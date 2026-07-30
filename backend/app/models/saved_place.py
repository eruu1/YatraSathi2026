"""
SQLAlchemy ORM model for user-saved places.

Table: saved_places
  user_id   — plain string (username) matching UserSession.loggedInUser
  place_id  — UUID string of the Place row in the places table
  place_snapshot — full place JSON so the saved list is self-contained
                   (no join needed, works even if the place row changes)
"""
from sqlalchemy import Column, String, DateTime, JSON, UniqueConstraint, Index
from sqlalchemy.dialects.postgresql import UUID
from backend.app.db.database import Base
import uuid
from datetime import datetime, timezone


class SavedPlace(Base):
    __tablename__ = "saved_places"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Plain username string — no FK, keeps it simple (matches UserSession.loggedInUser)
    user_id = Column(String(255), nullable=False, index=True)

    # UUID of the place in the places table (stored as string for simplicity)
    place_id = Column(String(255), nullable=False)

    # Full JSON snapshot of the place at save time — self-contained, no join needed
    place_snapshot = Column(JSON, nullable=False, default=dict)

    saved_at = Column(
        DateTime,
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    __table_args__ = (
        # One user can save each place at most once
        UniqueConstraint("user_id", "place_id", name="uq_saved_place_user_place"),
        Index("ix_saved_places_user_saved", "user_id", "saved_at"),
    )

    def to_dict(self):
        return {
            "id": str(self.id),
            "user_id": self.user_id,
            "place_id": self.place_id,
            "place_snapshot": self.place_snapshot or {},
            "saved_at": self.saved_at.isoformat() if self.saved_at else None,
        }
