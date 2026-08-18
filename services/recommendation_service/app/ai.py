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
GROQ_TRANSCRIBE_URL = "https://api.groq.com/openai/v1/audio/transcriptions"
# turbo over the plain whisper-large-v3: ~3x cheaper and faster, and
# accuracy isn't the bottleneck for a short chat voice message.
GROQ_TRANSCRIBE_MODEL = os.getenv("GROQ_TRANSCRIBE_MODEL", "whisper-large-v3-turbo")


class AiNotConfiguredError(Exception):
    pass


class AiRequestError(Exception):
    pass


_MAX_DESTINATION_CATALOG_ITEMS = 25
_MAX_TAGS_PER_DESTINATION = 4


def _destination_catalog(interests: list[str] | None = None, preferred_ids: list[str] | None = None) -> str:
    dests = read_data().get("destinations", [])
    preferred = {item for item in (preferred_ids or []) if item}
    interest_lookup = {item.lower() for item in (interests or []) if item}

    ranked = []
    for d in dests:
        score = 0
        dest_id = d.get("id")
        if dest_id in preferred:
            score += 100
        tags = d.get("tags") or []
        if interest_lookup:
            score += sum(1 for tag in tags if str(tag).lower() in interest_lookup)
        ranked.append((score, d))

    ranked.sort(key=lambda item: (-item[0], item[1].get("name", "")))
    selected = ranked[:_MAX_DESTINATION_CATALOG_ITEMS]
    overflow = max(len(ranked) - _MAX_DESTINATION_CATALOG_ITEMS, 0)
    lines = []
    for _, d in selected:
        bits = []
        if d.get("tags"):
            bits.append("tags: " + ", ".join(d["tags"][:_MAX_TAGS_PER_DESTINATION]))
        if d.get("location"):
            bits.append("location: " + d["location"])
        lines.append(f"- ({d.get('id')}) {d.get('name', '')} | " + " | ".join(bits))
    if overflow > 0:
        lines.append(f"... and {overflow} more destinations available if the user asks for a broader shortlist.")
    return "\n".join(lines)


_BASE_INSTRUCTIONS = (
    "You are Tia, the Trip Intelligence Assistant for trip_io, the trip-planning "
    "assistant for Yaoundé, Cameroon. Your job is travel assistance first: help users "
    "plan trips, discover destinations, compare places, ask about timings, practical "
    "tips, routes, and recommendations that fit their interests. Stay focused on "
    "travel and destination planning instead of answering unrelated general questions. "
    "If a user asks something outside travel, gently redirect toward trip planning, "
    "travel recommendations, or destination guidance.\n\n"
    "Core behavior:\n"
    "- You are Tia, the Trip Intelligence Assistant. Use 'Tia' and 'Ask TIA' or "
    "'TIA explanation' style language naturally when speaking to the user.\n"
    "- Focus on travel assistance, itineraries, destination choices, timing, preferences, "
    "local tips, and practical trip guidance.\n"
    "- Do not answer every question as a general-purpose assistant; guide the user back "
    "to trip planning, recommendations, and destination advice.\n"
    "- Only recommend or describe destinations from the catalog below - never invent a "
    "place, address, opening hours, price, or review that isn't given to you.\n"
    "- Keep answers concise and friendly, like a knowledgeable local friend.\n\n"
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


def _system_text(
    interests: list[str] | None = None,
    language_code: str | None = None,
    preferred_ids: list[str] | None = None,
) -> str:
    system_text = _BASE_INSTRUCTIONS + _language_instruction(language_code) + "\n\n" + _destination_catalog(
        interests=interests,
        preferred_ids=preferred_ids,
    )
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
    preferred_ids = []
    if messages:
        for m in messages:
            content = (m.get("content") or "")
            for token in ("d1", "d2", "d3", "d4", "d5", "d6", "d7", "d8", "d9", "d10"):
                if f"{token}" in content.lower():
                    preferred_ids.append(token)
    system_text = _system_text(interests=interests, language_code=language_code, preferred_ids=preferred_ids)
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
    preferred_ids = [destination.get("id")] if destination.get("id") else []
    system_text = _system_text(language_code=language_code, preferred_ids=preferred_ids)
    messages = [
        {"role": "system", "content": system_text},
        {"role": "user", "content": prompt},
    ]
    return await _generate(messages)


async def transcribe(audio_bytes: bytes, filename: str, content_type: str) -> str:
    """Transcribes a voice message to text via Groq's Whisper endpoint - the
    result is meant to land back in the chat's own text input for the user
    to review/send like a typed message, not treated as an AI reply itself.
    Reuses the same two exceptions chat()/explain_destination() raise so
    main.py's existing _ai_error_response mapping needs no changes."""
    if not GROQ_API_KEY:
        raise AiNotConfiguredError("GROQ_API_KEY is not set")

    try:
        async with httpx.AsyncClient(timeout=25) as client:
            resp = await client.post(
                GROQ_TRANSCRIBE_URL,
                headers={"Authorization": f"Bearer {GROQ_API_KEY}"},
                data={"model": GROQ_TRANSCRIBE_MODEL},
                files={"file": (filename, audio_bytes, content_type)},
            )
        resp.raise_for_status()
        payload = resp.json()
    except httpx.HTTPError as exc:
        logger.warning("Groq transcription request failed: %s", exc)
        raise AiRequestError(str(exc)) from exc

    text = (payload.get("text") or "").strip()
    if not text:
        raise AiRequestError("Transcription returned no text")
    return text
