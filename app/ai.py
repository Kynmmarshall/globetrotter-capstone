"""Google Gemini proxy for the in-app AI assistant - keeps the API key
server-side (same pattern as stats.py's Matomo token) and grounds every
answer in the app's real destinations data so the assistant can't invent
places, ratings, or facts that aren't in data.json.
"""
import logging
import os

import httpx

from .data import read_data

logger = logging.getLogger("trip_io.ai")

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-2.0-flash")
GEMINI_URL = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent"


class AiNotConfiguredError(Exception):
    pass


class AiRequestError(Exception):
    pass


def _destination_catalog() -> str:
    dests = read_data().get("destinations", [])
    lines = []
    for d in dests:
        bits = []
        if d.get("tags"):
            bits.append("tags: " + ", ".join(d["tags"]))
        if d.get("location"):
            bits.append("location: " + d["location"])
        if d.get("description"):
            bits.append(d["description"])
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


async def _generate(contents: list[dict], system_text: str) -> str:
    if not GEMINI_API_KEY:
        raise AiNotConfiguredError("GEMINI_API_KEY is not set")

    body = {
        "system_instruction": {"parts": [{"text": system_text}]},
        "contents": contents,
        "generationConfig": {"temperature": 0.6, "maxOutputTokens": 512},
    }
    try:
        async with httpx.AsyncClient(timeout=20) as client:
            resp = await client.post(GEMINI_URL, params={"key": GEMINI_API_KEY}, json=body)
        resp.raise_for_status()
        payload = resp.json()
    except httpx.HTTPError as exc:
        logger.warning("Gemini request failed: %s", exc)
        raise AiRequestError(str(exc)) from exc

    try:
        parts = payload["candidates"][0]["content"]["parts"]
        return "".join(p.get("text", "") for p in parts).strip()
    except (KeyError, IndexError, TypeError) as exc:
        logger.warning("Unexpected Gemini response shape: %s", payload)
        raise AiRequestError("Unexpected response from AI service") from exc


async def chat(messages: list[dict], interests: list[str] | None = None) -> str:
    system_text = _BASE_INSTRUCTIONS + _destination_catalog()
    if interests:
        system_text += (
            "\n\nThis user's stated interests: "
            + ", ".join(interests)
            + ". Lean on these when making suggestions, but don't ignore an explicit request for something else."
        )
    contents = [
        {"role": "model" if m["role"] == "assistant" else "user", "parts": [{"text": m["content"]}]}
        for m in messages
    ]
    return await _generate(contents, system_text)


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
    contents = [{"role": "user", "parts": [{"text": prompt}]}]
    system_text = _BASE_INSTRUCTIONS + _destination_catalog()
    return await _generate(contents, system_text)
