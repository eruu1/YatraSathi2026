"""
AI Agent Service — Chat-only implementation.

Every chat turn:
  1. Restores (or creates) the persisted session from the DB.
  2. Appends the user message.
  3. Builds a rich system prompt that includes full screen context and
     itinerary data so the LLM can answer in detail.
  4. Calls the Groq LLM with the full conversation history.
  5. Persists the assistant reply and returns it.

No editing, no proposals, no ProposedAction — just conversation.
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from groq import Groq
from sqlalchemy.orm import Session

from backend.app.config.settings import settings
from backend.app.db.database import SessionLocal
from backend.app.models.ai_api import ChatResponse, SessionInfo
from backend.app.models.session import AISession


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _utc_iso(dt: Optional[datetime]) -> str:
    if dt is None:
        return ""
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.isoformat()


def _build_system_prompt(
    screen_context: Optional[str],
    screen_data: Optional[Dict[str, Any]],
    itinerary_context: Optional[Dict[str, Any]],
    created_itineraries: Optional[List[Dict[str, Any]]],
) -> str:
    """
    Construct a detailed system prompt that gives the LLM full awareness of
    the user's current screen, active itinerary, and saved trips.
    """
    lines = [
        "You are YatraSathi, an expert Nepal travel assistant built into a road-trip planning app.",
        "You have deep knowledge of Nepal's geography, culture, seasons, permits, roads, food, and attractions.",
        "Be conversational, warm, and concise. Use Nepali place names correctly.",
        "IMPORTANT: You are a chat assistant only. Do NOT attempt to edit itineraries or propose structured actions.",
        "If the user asks you to edit or change an itinerary, politely explain they can do that manually in the app,",
        "but you can give them detailed advice, suggestions, and information to help them decide.",
        "",
    ]

    # Screen context
    if screen_context:
        screen_labels = {
            "plan": "Trip Planner screen (user is building a new road trip)",
            "explore": "Explore screen (user is browsing places in Nepal)",
            "saved": "Saved Places screen (user is viewing their saved locations)",
            "saved_itinerary_detail": "Saved Itinerary detail screen (user is reviewing a trip they planned)",
            "itinerary_edit": "Itinerary screen (user is looking at a generated trip)",
            "map": "Map screen (user is viewing places on a map)",
            "profile": "Profile screen",
        }
        label = screen_labels.get(screen_context, f"'{screen_context}' screen")
        lines.append(f"CURRENT SCREEN: {label}")

    # Screen data (search query, origin/destination, etc.)
    if screen_data:
        relevant = {k: v for k, v in screen_data.items() if v not in (None, "", [], {})}
        if relevant:
            lines.append(f"SCREEN DATA: {json.dumps(relevant, ensure_ascii=False)}")

    # Active itinerary
    if itinerary_context:
        lines.append("")
        lines.append("ACTIVE ITINERARY THE USER IS VIEWING:")
        try:
            lines.append(json.dumps(itinerary_context, indent=2, ensure_ascii=False))
        except Exception:
            lines.append(str(itinerary_context))

    # Saved itineraries summary
    if created_itineraries:
        lines.append("")
        lines.append(f"USER'S SAVED ITINERARIES ({len(created_itineraries)} total):")
        for it in created_itineraries[:5]:  # cap at 5 to keep prompt size reasonable
            title = it.get("title") or it.get("id", "Untitled")
            origin = it.get("origin") or it.get("from", "?")
            dest = it.get("destination") or it.get("to", "?")
            days = it.get("days", "?")
            lines.append(f"  • {title} — {origin} → {dest}, {days} days")

    lines.append("")
    lines.append(
        "Answer the user's question thoroughly. If relevant, reference the itinerary or screen data above."
    )

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Service
# ---------------------------------------------------------------------------

class AIAgentService:
    """Session-aware chat service backed by Groq LLM."""

    def __init__(self) -> None:
        self._client: Optional[Groq] = None

    def _get_client(self) -> Groq:
        if self._client is None:
            if not settings.GROQ_API_KEY:
                raise RuntimeError(
                    "GROQ_API_KEY is not set. Add it to your .env file."
                )
            self._client = Groq(api_key=settings.GROQ_API_KEY)
        return self._client

    # ------------------------------------------------------------------ #
    # Session CRUD                                                          #
    # ------------------------------------------------------------------ #

    def _get_or_create_session(
        self, db: Session, session_id: str, user_id: Optional[str]
    ) -> AISession:
        row = db.query(AISession).filter(AISession.session_id == session_id).first()
        if row:
            return row
        row = AISession(
            session_id=session_id,
            messages=[],
            session_metadata={"user_id": user_id},
        )
        db.add(row)
        db.flush()
        return row

    def get_session(self, session_id: str) -> Optional[Dict[str, Any]]:
        with SessionLocal() as db:
            row = db.query(AISession).filter(AISession.session_id == session_id).first()
            if not row:
                return None
            return self._session_to_dict(row)

    def delete_session(self, session_id: str) -> bool:
        with SessionLocal() as db:
            row = db.query(AISession).filter(AISession.session_id == session_id).first()
            if not row:
                return False
            db.delete(row)
            db.commit()
            return True

    @staticmethod
    def _session_to_dict(row: AISession) -> Dict[str, Any]:
        meta = dict(row.session_metadata or {})
        return {
            "session_id": row.session_id,
            "user_id": meta.get("user_id"),
            "messages": list(row.messages or []),
            "session_metadata": meta,
            "created_at": _utc_iso(row.created_at),
            "updated_at": _utc_iso(row.updated_at),
        }

    # ------------------------------------------------------------------ #
    # Chat                                                                  #
    # ------------------------------------------------------------------ #

    def chat(
        self,
        session_id: str,
        user_id: Optional[str],
        message: str,
        screen_context: Optional[str] = None,
        screen_data: Optional[Dict[str, Any]] = None,
        itinerary_context: Optional[Dict[str, Any]] = None,
        created_itineraries: Optional[List[Dict[str, Any]]] = None,
    ) -> ChatResponse:
        if not settings.AI_ENABLED:
            return ChatResponse(
                session_id=session_id,
                response_text=(
                    "The AI assistant is currently disabled. "
                    "Set AI_ENABLED=true in your .env to enable it."
                ),
                messages=[],
            )

        with SessionLocal() as db:
            row = self._get_or_create_session(db, session_id, user_id)
            history: List[Dict[str, Any]] = list(row.messages or [])

            # Persist user message
            user_entry = {
                "role": "user",
                "content": message,
                "timestamp": _utc_iso(datetime.now(timezone.utc)),
            }
            history.append(user_entry)

            # Build system prompt with full context
            system_prompt = _build_system_prompt(
                screen_context, screen_data, itinerary_context, created_itineraries
            )

            # Build the messages list for the Groq API:
            # system prompt + all prior turns (role/content only) + current user message
            groq_messages: List[Dict[str, str]] = [
                {"role": "system", "content": system_prompt}
            ]
            # Include previous turns (skip entries without role/content)
            for h in history[:-1]:  # exclude the entry we just appended
                role = h.get("role")
                content = h.get("content", "")
                if role in ("user", "assistant") and content:
                    groq_messages.append({"role": role, "content": content})
            # Add current user message
            groq_messages.append({"role": "user", "content": message})

            # Call Groq
            try:
                client = self._get_client()
                completion = client.chat.completions.create(
                    model=settings.LLM_MODEL,
                    messages=groq_messages,  # type: ignore[arg-type]
                    temperature=settings.LLM_TEMPERATURE,
                    max_tokens=settings.LLM_MAX_TOKENS,
                )
                reply_text = completion.choices[0].message.content or ""
            except Exception as e:
                reply_text = (
                    f"Sorry, I couldn't reach the AI service right now ({e}). "
                    "Please check that the backend is running and GROQ_API_KEY is set."
                )

            # Persist assistant reply
            assistant_entry = {
                "role": "assistant",
                "content": reply_text,
                "timestamp": _utc_iso(datetime.now(timezone.utc)),
            }
            history.append(assistant_entry)

            # Update session metadata
            meta = dict(row.session_metadata or {})
            meta["user_id"] = user_id or meta.get("user_id")
            meta["last_screen_context"] = screen_context

            row.messages = history
            row.session_metadata = meta
            row.updated_at = datetime.now(timezone.utc)
            db.commit()

            return ChatResponse(
                session_id=row.session_id,
                response_text=reply_text,
                messages=list(row.messages or []),
            )


ai_agent_service = AIAgentService()
