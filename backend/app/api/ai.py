"""
AI chat API endpoints.

  POST   /ai/chat                  — single chat turn with full context awareness
  GET    /ai/sessions/{session_id} — fetch persisted session history
  DELETE /ai/sessions/{session_id} — clear a session
"""
from fastapi import APIRouter, HTTPException

from backend.app.models.ai_api import (
    ChatRequest,
    ChatResponse,
    SessionInfo,
    GenericSuccess,
)
from backend.app.services.ai_agent_service import ai_agent_service

router = APIRouter(prefix="/ai", tags=["ai"])


@router.post("/chat", response_model=ChatResponse)
async def chat(req: ChatRequest) -> ChatResponse:
    """Run a single conversational turn with the AI travel assistant."""
    try:
        return ai_agent_service.chat(
            session_id=req.session_id,
            user_id=req.user_id,
            message=req.message,
            screen_context=req.screen_context,
            screen_data=req.screen_data,
            itinerary_context=req.itinerary_context,
            created_itineraries=req.created_itineraries,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Chat error: {e}")


@router.get("/sessions/{session_id}", response_model=SessionInfo)
async def get_session(session_id: str) -> SessionInfo:
    """Fetch the stored state of a chat session."""
    info = ai_agent_service.get_session(session_id)
    if not info:
        raise HTTPException(status_code=404, detail="Session not found")
    return SessionInfo(**info)


@router.delete("/sessions/{session_id}", response_model=GenericSuccess)
async def delete_session(session_id: str) -> GenericSuccess:
    """Delete a chat session and clear its history."""
    deleted = ai_agent_service.delete_session(session_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Session not found")
    return GenericSuccess(message="Session deleted")
