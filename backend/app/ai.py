"""Groq (OpenAI-compatible chat completions) proxy for the in-app AI
assistant - keeps the API key server-side (same pattern as stats.py's
Matomo token) and grounds every answer in the app's real destinations data
so the assistant can't invent places, ratings, or facts that aren't in
data.json. Groq's free tier needs no billing account, unlike Gemini's,
which is why this replaced the original Gemini-based implementation.
"""
import logging
import os

import httpx

from .data import read_data

logger = logging.getLogger("trip_io.ai")

GROQ_API_KEY = os.getenv("GROQ_API_KEY")
GROQ_MODEL = os.getenv("GROQ_MODEL", "llama-3.3-70b-versatile")
GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"


class AiNotConfiguredError(Exception):
    pass


class AiRequestError(Exception):
    pass


def _destination_catalog() -> str:
    # Name/tags/location only - deliberately no description. This catalog
    # gets embedded in the system prompt on every /ai/chat turn (unlike
    # /ai/explain, which is cached), so trimming it here directly cuts the
    # tokens spent per message. explain_destination() still passes the full
    # description for the one destination it's actually explaining, via its
    # own detail_lines below - nothing is lost there.
    dests = read_data().get("destinations", [])
    lines = []
    for d in dests:
        bits = []
        if d.get("tags"):
            bits.append("tags: " + ", ".join(d["tags"]))
        if d.get("location"):
            bits.append("location: " + d["location"])
        lines.append(f"- ({d.get('id')}) {d.get('name', '')} | " + " | ".join(bits))
    return "\n".join(lines)


_BASE_INSTRUCTIONS = (
    "You are the in-app travel assistant for trip_io, a trip-planning app focused "
    "exclusively on Yaoundé, Cameroon. Answer naturally in whatever language the "
    "user writes in (English or French). Only recommend or describe destinations "
    "from the catalog below - never invent a place, address, opening hours, price, "
    "or review that isn't given to you. The app does not yet have star ratings or "
    "reviews for destinations - if asked, say that feature is coming soon rather "
    "than making up a number. Keep answers concise and friendly, like a "
    "knowledgeable local friend.\n\nDestination catalog:\n"
)


async def _generate(messages: list[dict]) -> str:
    if not GROQ_API_KEY:
        raise AiNotConfiguredError("GROQ_API_KEY is not set")

    body = {
        "model": GROQ_MODEL,
        "messages": messages,
        "temperature": 0.6,
        "max_tokens": 512,
    }
    try:
        async with httpx.AsyncClient(timeout=20) as client:
            resp = await client.post(
                GROQ_URL,
                headers={"Authorization": f"Bearer {GROQ_API_KEY}"},
                json=body,
            )
        resp.raise_for_status()
        payload = resp.json()
    except httpx.HTTPError as exc:
        logger.warning("Groq request failed: %s", exc)
        raise AiRequestError(str(exc)) from exc

    try:
        return payload["choices"][0]["message"]["content"].strip()
    except (KeyError, IndexError, TypeError) as exc:
        logger.warning("Unexpected Groq response shape: %s", payload)
        raise AiRequestError("Unexpected response from AI service") from exc


async def chat(messages: list[dict], interests: list[str] | None = None) -> str:
    system_text = _BASE_INSTRUCTIONS + _destination_catalog()
    if interests:
        system_text += (
            "\n\nThis user's stated interests: "
            + ", ".join(interests)
            + ". Lean on these when making suggestions, but don't ignore an explicit request for something else."
        )
    full_messages = [{"role": "system", "content": system_text}] + [
        {"role": "assistant" if m["role"] == "assistant" else "user", "content": m["content"]}
        for m in messages
    ]
    return await _generate(full_messages)


async def explain_destination(destination: dict) -> str:
    detail_lines = [f"Name: {destination.get('name')}"]
    if destination.get("location"):
        detail_lines.append(f"Location: {destination['location']}")
    if destination.get("tags"):
        detail_lines.append("Tags: " + ", ".join(destination["tags"]))
    if destination.get("description"):
        detail_lines.append(f"Description: {destination['description']}")
    if destination.get("opening_hours"):
        detail_lines.append(f"Opening hours: {destination['opening_hours']}")
    if destination.get("entry_fee"):
        detail_lines.append(f"Entry fee: {destination['entry_fee']}")
    if destination.get("tips"):
        detail_lines.append(f"Tips: {destination['tips']}")

    prompt = (
        "Write a warm, informative 3-5 sentence explanation of this destination for "
        "a traveller deciding whether to visit. You may add well-known general "
        "historical/cultural context, but do not invent specific facts (prices, "
        "hours, addresses, ratings) beyond what's given here:\n\n" + "\n".join(detail_lines)
    )
    system_text = _BASE_INSTRUCTIONS + _destination_catalog()
    messages = [
        {"role": "system", "content": system_text},
        {"role": "user", "content": prompt},
    ]
    return await _generate(messages)
