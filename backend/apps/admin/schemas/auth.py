"""Admin authentication schemas."""
from __future__ import annotations
from typing import Optional, List
from pydantic import BaseModel, EmailStr, Field


class AdminLoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)
    mfa_code: Optional[str] = None


class AdminLoginResponse(BaseModel):
    status: str = "OK"
    access_token: str
    refresh_token: str
    admin: "AdminProfile"


class AdminProfile(BaseModel):
    id: str
    email: str
    full_name: str
    role: str
    permissions: dict = {}
    mfa_enabled: bool = False


class AdminRefreshRequest(BaseModel):
    refresh_token: str


class AdminRefreshResponse(BaseModel):
    status: str = "OK"
    access_token: str
    refresh_token: str


class AdminPasswordChangeRequest(BaseModel):
    current_password: str = Field(min_length=8)
    new_password: str = Field(min_length=8)


class AdminPasswordChangeResponse(BaseModel):
    status: str = "OK"
    message: str = "Password changed successfully"


AdminLoginResponse.model_rebuild()
