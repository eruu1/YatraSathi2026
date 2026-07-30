"""
Authentication service — password hashing, JWT issuance, user CRUD.

Uses bcrypt directly (bypasses passlib which has a Python 3.14 incompatibility)
and python-jose for JWT encoding/decoding.
"""
from __future__ import annotations

import uuid
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional

import bcrypt
from jose import JWTError, jwt
from sqlalchemy.exc import IntegrityError

from backend.app.config.settings import settings
from backend.app.db.database import SessionLocal
from backend.app.models.user import User


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _hash(plain: str) -> str:
    return bcrypt.hashpw(plain.encode(), bcrypt.gensalt()).decode()


def _verify(plain: str, hashed: str) -> bool:
    try:
        return bcrypt.checkpw(plain.encode(), hashed.encode())
    except Exception:
        return False


def _make_token(data: Dict[str, Any], expires_hours: int) -> str:
    payload = dict(data)
    payload["exp"] = datetime.now(timezone.utc) + timedelta(hours=expires_hours)
    return jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


def _user_dict(user: User) -> Dict[str, Any]:
    return {
        "id": str(user.id),
        "email": user.email,
        "username": user.username,
        "full_name": user.full_name,
        "created_at": user.created_at.isoformat() if user.created_at else None,
    }


# ---------------------------------------------------------------------------
# Service
# ---------------------------------------------------------------------------

class AuthService:

    def register(
        self,
        email: str,
        username: str,
        password: str,
        full_name: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Create a new user and return a token + user dict."""
        with SessionLocal() as db:
            # Normalise
            email = email.strip().lower()
            username = username.strip()

            # Duplicate check with a friendly message
            existing_email = db.query(User).filter(User.email == email).first()
            if existing_email:
                raise ValueError("An account with this email already exists.")
            existing_user = db.query(User).filter(User.username == username).first()
            if existing_user:
                raise ValueError("This username is already taken.")

            user = User(
                email=email,
                username=username,
                hashed_password=_hash(password),
                full_name=full_name or username,
            )
            db.add(user)
            try:
                db.commit()
                db.refresh(user)
            except IntegrityError:
                db.rollback()
                raise ValueError("Registration failed — duplicate email or username.")

            token = _make_token(
                {"sub": str(user.id), "username": user.username},
                settings.JWT_EXPIRE_HOURS,
            )
            return {"access_token": token, "token_type": "bearer", "user": _user_dict(user)}

    def login(self, email: str, password: str) -> Dict[str, Any]:
        """Verify credentials and return a token + user dict."""
        with SessionLocal() as db:
            email = email.strip().lower()
            user = db.query(User).filter(User.email == email).first()
            if not user or not _verify(password, user.hashed_password):
                raise ValueError("Incorrect email or password.")

            token = _make_token(
                {"sub": str(user.id), "username": user.username},
                settings.JWT_EXPIRE_HOURS,
            )
            return {"access_token": token, "token_type": "bearer", "user": _user_dict(user)}

    def get_current_user(self, token: str) -> Dict[str, Any]:
        """Decode a JWT and return the user dict."""
        try:
            payload = jwt.decode(
                token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM]
            )
            user_id: str = payload.get("sub")
            if not user_id:
                raise ValueError("Invalid token.")
        except JWTError:
            raise ValueError("Invalid or expired token.")

        with SessionLocal() as db:
            user = db.query(User).filter(User.id == uuid.UUID(user_id)).first()
            if not user:
                raise ValueError("User not found.")
            return _user_dict(user)


auth_service = AuthService()
