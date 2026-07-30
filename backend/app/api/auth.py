"""
Authentication API endpoints.

  POST  /auth/register  — create a new account
  POST  /auth/login     — sign in and receive a JWT
  GET   /auth/me        — return the current user's profile (requires Bearer token)
"""
from fastapi import APIRouter, HTTPException, Header
from typing import Optional
from pydantic import BaseModel, Field

from backend.app.services.auth_service import auth_service

router = APIRouter(prefix="/auth", tags=["auth"])


# ── Request / response models ─────────────────────────────────────────────

class RegisterRequest(BaseModel):
    email: str = Field(..., description="User email address")
    username: str = Field(..., min_length=2, description="Unique username")
    password: str = Field(..., min_length=6, description="Password (min 6 chars)")
    full_name: Optional[str] = Field(None, description="Display name")


class LoginRequest(BaseModel):
    email: str
    password: str


# ── Endpoints ─────────────────────────────────────────────────────────────

@router.post("/register")
async def register(req: RegisterRequest):
    """Create a new user account and return an access token."""
    try:
        return auth_service.register(
            email=req.email,
            username=req.username,
            password=req.password,
            full_name=req.full_name,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Registration error: {e}")


@router.post("/login")
async def login(req: LoginRequest):
    """Sign in with email + password and receive an access token."""
    try:
        return auth_service.login(email=req.email, password=req.password)
    except ValueError as e:
        raise HTTPException(status_code=401, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Login error: {e}")


@router.get("/me")
async def get_me(authorization: Optional[str] = Header(None)):
    """Return the authenticated user's profile from the Bearer token."""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing or invalid Authorization header")
    token = authorization.removeprefix("Bearer ").strip()
    try:
        return auth_service.get_current_user(token)
    except ValueError as e:
        raise HTTPException(status_code=401, detail=str(e))
