"""
Itinerary model for trip planning.
"""
from sqlalchemy import Column, String, Text, DateTime, JSON, Boolean
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from backend.app.db.database import Base
import uuid
from datetime import datetime, timezone


class Itinerary(Base):
    """Itinerary model for trip planning."""
    
    __tablename__ = "itineraries"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True))
    title = Column(String(255))
    description = Column(Text)
    destinations = Column(JSON, default=list)
    start_date = Column(DateTime)
    end_date = Column(DateTime)
    # Whether this itinerary is publicly visible in the community feed
    is_public = Column(Boolean, default=False)
    # Optional human-readable author username for quick display
    author_username = Column(String(128), nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
