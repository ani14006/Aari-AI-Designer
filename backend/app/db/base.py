"""Declarative base + helper for creating all tables (dev convenience; use Alembic in prod)."""
from datetime import datetime

from sqlalchemy import DateTime
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )


async def init_models() -> None:
    """Create all tables. Intended for local/dev use; production should run Alembic migrations."""
    from app.db.session import engine
    # Import models so they register on Base.metadata before create_all runs.
    from app.models import cart, design, user  # noqa: F401

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
