"""
Pydantic request/response models for the AI chat endpoints.
Editing, proposal, and workspace models have been removed — the AI is chat-only.
"""
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


# ---------------------------------------------------------------------------
# Chat endpoints
# ---------------------------------------------------------------------------

class ChatRequest(BaseModel):
    """Request body for POST /ai/chat."""

    session_id: str = Field(..., description="Stable session identifier for the chat.")
    user_id: Optional[str] = Field(None, description="Authenticated user id, if any.")
    message: str = Field(..., min_length=1, description="User's latest message text.")

    screen_context: Optional[str] = Field(
        None,
        description=(
            "Name of the active Flutter screen: plan, explore, "
            "saved_itinerary_detail, profile, saved, map."
        ),
    )
    screen_data: Optional[Dict[str, Any]] = Field(
        None,
        description="Screen-specific data (origin/destination, current search query, etc.).",
    )
    itinerary_context: Optional[Dict[str, Any]] = Field(
        None,
        description="The itinerary the user is currently viewing, if any.",
    )
    created_itineraries: Optional[List[Dict[str, Any]]] = Field(
        None,
        description="Lightweight list of all the user's saved itineraries.",
    )


class ChatResponse(BaseModel):
    """Response body for POST /ai/chat."""

    session_id: str
    response_text: str = Field("", description="Natural language assistant reply.")
    messages: List[Dict[str, Any]] = Field(
        default_factory=list,
        description="Full updated conversation history.",
    )


class SessionInfo(BaseModel):
    """Full persisted AI session metadata."""

    session_id: str
    user_id: Optional[str]
    messages: List[Dict[str, Any]]
    session_metadata: Dict[str, Any]
    created_at: str
    updated_at: str


class GenericSuccess(BaseModel):
    success: bool = True
    message: Optional[str] = None


class WorkspaceCreate(BaseModel):
    user_id: str = Field(..., description="Authenticated user id for workspace ownership.")
    name: str = Field(..., description="Workspace name or itinerary title.")
    origin_lat: Optional[float] = Field(None, description="Origin latitude for the itinerary.")
    origin_lng: Optional[float] = Field(None, description="Origin longitude for the itinerary.")
    destination_lat: Optional[float] = Field(None, description="Destination latitude for the itinerary.")
    destination_lng: Optional[float] = Field(None, description="Destination longitude for the itinerary.")
    start_date: Optional[str] = Field(None, description="Planned itinerary start date.")
    end_date: Optional[str] = Field(None, description="Planned itinerary end date.")
    initial_itinerary: Optional[Dict[str, Any]] = Field(
        None,
        description="Optional initial itinerary snapshot to seed the workspace.",
    )


class WorkspaceExecute(BaseModel):
    operation_type: str = Field(..., description="The workspace operation type to execute.")
    args: Optional[Dict[str, Any]] = Field(None, description="Arguments for the operation.")
    user_id: Optional[str] = Field(None, description="Authenticated user id executing the operation.")


class WorkspacePropose(BaseModel):
    operations: List[Dict[str, Any]] = Field(
        ..., description="List of proposed workspace operations."
    )
    user_id: Optional[str] = Field(None, description="Authenticated user id for the proposal.")
    screen_context: Optional[str] = Field(
        None,
        description="Contextual screen identifier where the proposal was generated.",
    )


class ProposalAction(BaseModel):
    action: str = Field(..., description="Action to take on the proposal: accept or reject.")
    create_version: bool = Field(
        True,
        description="Whether accepting the proposal should create an immutable version.",
    )
    version_description: Optional[str] = Field(
        None,
        description="Optional description for the created workspace version.",
    )
