"""
Saved Places API endpoints.

All routes are scoped to a user via the `user_id` query param (the plain
username string stored in UserSession.loggedInUser on the Flutter side).
No JWT auth is required — matches the rest of the app's auth pattern.

Endpoints
---------
POST   /saved-places                    — save a place
DELETE /saved-places/{place_id}         — unsave a place
GET    /saved-places?user_id=…          — list all saved places for a user
GET    /saved-places/{place_id}/check   — check if a place is saved
"""
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from typing import Any, Dict

from backend.app.services.saved_places_service import saved_places_service

router = APIRouter(prefix="/saved-places", tags=["saved-places"])


# ── Request body ──────────────────────────────────────────────────────────────

class SavePlaceRequest(BaseModel):
    user_id: str
    place_id: str
    place_snapshot: Dict[str, Any]


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.post("")
async def save_place(body: SavePlaceRequest):
    """Save a place for a user. Idempotent — safe to call multiple times."""
    if not body.user_id.strip():
        raise HTTPException(status_code=400, detail="user_id is required")
    if not body.place_id.strip():
        raise HTTPException(status_code=400, detail="place_id is required")

    result = saved_places_service.save_place(
        user_id=body.user_id.strip(),
        place_id=body.place_id.strip(),
        place_snapshot=body.place_snapshot,
    )
    return {"status": "saved", "saved_place": result}


@router.delete("/{place_id}")
async def unsave_place(
    place_id: str,
    user_id: str = Query(..., description="Username of the user"),
):
    """Remove a saved place. Returns 404 if it was never saved."""
    if not user_id.strip():
        raise HTTPException(status_code=400, detail="user_id is required")

    deleted = saved_places_service.unsave_place(
        user_id=user_id.strip(),
        place_id=place_id.strip(),
    )
    if not deleted:
        raise HTTPException(status_code=404, detail="Saved place not found")
    return {"status": "unsaved", "place_id": place_id}


@router.get("")
async def get_saved_places(
    user_id: str = Query(..., description="Username of the user"),
):
    """Return all saved places for a user, most-recently saved first."""
    if not user_id.strip():
        raise HTTPException(status_code=400, detail="user_id is required")

    rows = saved_places_service.get_saved_places(user_id.strip())
    # Extract the place snapshots — that's what the Flutter app needs
    places = [r["place_snapshot"] for r in rows if r.get("place_snapshot")]
    return {
        "places": places,
        "count": len(places),
        "user_id": user_id.strip(),
    }


@router.get("/{place_id}/check")
async def check_saved(
    place_id: str,
    user_id: str = Query(..., description="Username of the user"),
):
    """Check whether a specific place is saved by the user."""
    saved = saved_places_service.is_saved(
        user_id=user_id.strip(),
        place_id=place_id.strip(),
    )
    return {"place_id": place_id, "is_saved": saved}
