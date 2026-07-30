"""
Simple itineraries API: expose user-created and public itineraries.
"""
from fastapi import APIRouter, HTTPException, Query
from typing import List
from sqlalchemy.orm import Session
from backend.app.db.database import SessionLocal
from backend.app.models.itinerary import Itinerary
from backend.app.models.user import User

router = APIRouter(prefix="/itineraries", tags=["itineraries"])


def _get_db() -> Session:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.get("/user")
def get_user_itineraries(username: str = Query(..., description="Username")):
    """Return itineraries created by the given username."""
    if not username.strip():
        raise HTTPException(status_code=400, detail="username is required")

    with SessionLocal() as db:
        user = db.query(User).filter(User.username == username.strip()).first()
        if not user:
            # No user found — return empty set rather than 404 so frontend can handle guests.
            return {"itineraries": [], "count": 0, "username": username}

        rows = db.query(Itinerary).filter(Itinerary.user_id == user.id).order_by(Itinerary.created_at.desc()).all()
        items = []
        for it in rows:
            items.append({
                "id": str(it.id),
                "title": it.title,
                "description": it.description,
                "start_date": it.start_date.isoformat() if it.start_date else None,
                "end_date": it.end_date.isoformat() if it.end_date else None,
                "created_at": it.created_at.isoformat() if it.created_at else None,
            })
        return {"itineraries": items, "count": len(items), "username": username}


@router.get("/public")
def get_public_itineraries(limit: int = Query(20, description="Max items to return")):
    """Return recent public/community itineraries."""
    with SessionLocal() as db:
        rows = db.query(Itinerary).filter(Itinerary.is_public == True).order_by(Itinerary.created_at.desc()).limit(limit).all()
        items = []
        for it in rows:
            items.append({
                "id": str(it.id),
                "title": it.title,
                "description": it.description,
                "author": it.author_username,
                "created_at": it.created_at.isoformat() if it.created_at else None,
            })
        return {"itineraries": items, "count": len(items)}
