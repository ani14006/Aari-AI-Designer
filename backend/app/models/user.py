"""User model. Identity is owned by Supabase Auth; this row mirrors profile + app-level state."""
import uuid

from sqlalchemy import String, Boolean
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin


class User(Base, TimestampMixin):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    supabase_uid: Mapped[str] = mapped_column(String(128), unique=True, index=True, nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    display_name: Mapped[str] = mapped_column(String(255), default="")
    photo_url: Mapped[str] = mapped_column(String(1024), default="")
    language: Mapped[str] = mapped_column(String(8), default="en")
    dark_mode: Mapped[bool] = mapped_column(Boolean, default=False)
    notifications_enabled: Mapped[bool] = mapped_column(Boolean, default=True)

    designs: Mapped[list["Design"]] = relationship(back_populates="owner", cascade="all, delete-orphan")
