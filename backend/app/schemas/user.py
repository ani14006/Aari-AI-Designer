"""Pydantic schemas for user profile + settings."""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, EmailStr


class UserBase(BaseModel):
    email: EmailStr
    display_name: str = ""
    photo_url: str = ""


class UserRead(UserBase):
    model_config = ConfigDict(from_attributes=True)

    id: str
    supabase_uid: str
    language: str
    dark_mode: bool
    notifications_enabled: bool
    created_at: datetime


class UserSettingsUpdate(BaseModel):
    display_name: Optional[str] = None
    language: Optional[str] = None
    dark_mode: Optional[bool] = None
    notifications_enabled: Optional[bool] = None
