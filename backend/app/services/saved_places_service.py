"""
Service layer for user-saved places.

Methods
-------
save_place(user_id, place_id, place_snapshot)
    Idempotent — silently succeeds if already saved.
unsave_place(user_id, place_id)
    Returns True if a row was deleted, False if it didn't exist.
get_saved_places(user_id)
    Returns the full list of saved place snapshots for a user,
    ordered by most-recently saved first.
is_saved(user_id, place_id)
    Quick membership check.
"""
from __future__ import annotations

from typing import Any, Dict, List

from sqlalchemy.exc import IntegrityError

from backend.app.db.database import SessionLocal
from backend.app.models.saved_place import SavedPlace


class SavedPlacesService:
    # ------------------------------------------------------------------ #
    # Save                                                                  #
    # ------------------------------------------------------------------ #
    def save_place(
        self,
        user_id: str,
        place_id: str,
        place_snapshot: Dict[str, Any],
    ) -> Dict[str, Any]:
        """
        Persist a saved place row.  Idempotent — if the (user_id, place_id)
        pair already exists the existing row is returned unchanged.
        """
        with SessionLocal() as db:
            # Check for existing row first to avoid relying solely on the
            # IntegrityError path (friendlier for callers).
            existing = (
                db.query(SavedPlace)
                .filter(
                    SavedPlace.user_id == user_id,
                    SavedPlace.place_id == place_id,
                )
                .first()
            )
            if existing:
                return existing.to_dict()

            row = SavedPlace(
                user_id=user_id,
                place_id=place_id,
                place_snapshot=place_snapshot,
            )
            db.add(row)
            try:
                db.commit()
                db.refresh(row)
                return row.to_dict()
            except IntegrityError:
                # Race condition — another request saved the same place
                db.rollback()
                existing = (
                    db.query(SavedPlace)
                    .filter(
                        SavedPlace.user_id == user_id,
                        SavedPlace.place_id == place_id,
                    )
                    .first()
                )
                return existing.to_dict() if existing else {}

    # ------------------------------------------------------------------ #
    # Unsave                                                                #
    # ------------------------------------------------------------------ #
    def unsave_place(self, user_id: str, place_id: str) -> bool:
        """
        Delete the saved-place row.
        Returns True if deleted, False if the row didn't exist.
        """
        with SessionLocal() as db:
            row = (
                db.query(SavedPlace)
                .filter(
                    SavedPlace.user_id == user_id,
                    SavedPlace.place_id == place_id,
                )
                .first()
            )
            if not row:
                return False
            db.delete(row)
            db.commit()
            return True

    # ------------------------------------------------------------------ #
    # List                                                                  #
    # ------------------------------------------------------------------ #
    def get_saved_places(self, user_id: str) -> List[Dict[str, Any]]:
        """
        Return all saved places for a user ordered by most-recently saved first.
        Each item includes the full place_snapshot so the client needs no
        secondary lookup.
        """
        with SessionLocal() as db:
            rows = (
                db.query(SavedPlace)
                .filter(SavedPlace.user_id == user_id)
                .order_by(SavedPlace.saved_at.desc())
                .all()
            )
            return [r.to_dict() for r in rows]

    # ------------------------------------------------------------------ #
    # Membership check                                                      #
    # ------------------------------------------------------------------ #
    def is_saved(self, user_id: str, place_id: str) -> bool:
        with SessionLocal() as db:
            return (
                db.query(SavedPlace)
                .filter(
                    SavedPlace.user_id == user_id,
                    SavedPlace.place_id == place_id,
                )
                .first()
            ) is not None


# Singleton used by the API router
saved_places_service = SavedPlacesService()
