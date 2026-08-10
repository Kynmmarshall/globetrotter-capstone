"""Groq (OpenAI-compatible chat completions) proxy for the in-app AI
assistant - keeps the API key server-side and grounds every answer in this
service's own destinations data so the assistant can't invent places,
ratings, or facts that aren't in destinations.json.
"""
import logging
import os

import httpx

from .data import read_data

logger = logging.getLogger("trip_io.recommendation_service.ai")

GROQ_API_KEY = os.getenv("GROQ_API_KEY")
GROQ_MODEL = os.getenv("GROQ_MODEL", "llama-3.3-70b-versatile")
GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"


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
        lines.append(f"- ({d.get('id')}) {d.get('name', '')} | " + " | ".join(bits))
    return "\n".join(lines)


_BASE_INSTRUCTIONS = (
    "You are the in-app travel assistant for trip_io, a trip-planning app focused "
    "exclusively on Yaoundé, Cameroon. Only recommend or describe destinations "
    "from the catalog below - never invent a place, address, opening hours, price, "
    "or review that isn't given to you. Keep answers concise and friendly, like a "
    "knowledgeable local friend.\n\n"
    "Formatting rules - the app displays your replies as plain chat text, not "
    "rendered markdown, so anything markdown-style would show up as stray literal "
    "characters:\n"
    "- Never use markdown: no *asterisks*, **double asterisks**, # headers, "
    "`backticks`, or bullet dashes. Write in plain conversational sentences.\n"
    "- Each place below is listed as (id) Name - that id is internal, never write "
    "it out plainly (e.g. never write \"d1\" or \"(d1)\" in your reply). Whenever you "
    "mention a specific place from the catalog, write it as [[Name|id]] using its "
    "exact name and id instead, e.g. [[Monument de la Réunification|d1]]. The app "
    "turns that into a tappable link to that place's page - use it every time you "
    "name a catalog place, not just the first time.\n"
    "- Use relevant emojis naturally through your replies (e.g. 📍 for a place, 🍽️ "
    "for food, 🌿 for nature, 🕒 for hours) so it feels warm and human rather than "
    "robotic - a couple per message is usually enough, don't overdo it.\n\n"
    "Destination catalog:\n"
)


def _language_instruction(language_code: str | None) -> str:
    if language_code == "fr":
        return "Answer exclusively in French, regardless of the language used by the user."
    if language_code == "en":
        return "Answer exclusively in English, regardless of the language used by the user."
    return "Answer in the same language as the user unless the conversation clearly indicates a different app language."


def _system_text(interests: list[str] | None = None, language_code: str | None = None) -> str:
    system_text = _BASE_INSTRUCTIONS + _language_instruction(language_code) + "\n\n" + _destination_catalog()
    if interests:
        system_text += (
            "\n\nThis user's stated interests: "
            + ", ".join(interests)
            + ". Lean on these when making suggestions, but don't ignore an explicit request for something else."
        )
    return system_text


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


async def chat(
    messages: list[dict],
    interests: list[str] | None = None,
    language_code: str | None = None,
) -> str:
    system_text = _system_text(interests=interests, language_code=language_code)
    full_messages = [{"role": "system", "content": system_text}] + [
        {"role": "assistant" if m["role"] == "assistant" else "user", "content": m["content"]}
        for m in messages
    ]
    return await _generate(full_messages)


async def explain_destination(destination: dict, language_code: str | None = None) -> str:
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
    system_text = _system_text(language_code=language_code)
    messages = [
        {"role": "system", "content": system_text},
        {"role": "user", "content": prompt},
    ]
    return await _generate(messages)
