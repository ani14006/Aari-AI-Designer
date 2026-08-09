"""Declarative base + helper for creating all tables (dev convenience; use Alembic in prod)."""
from datetime import datetime

from sqlalchemy import DateTime, inspect, text
from sqlalchemy.engine import Connection
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )


def _add_missing_columns(conn: Connection) -> None:
    """create_all() only creates tables that don't exist yet — it never ALTERs a table that's
    already there, so a column added to a model after its table already exists in production
    (there's no Alembic here yet) silently never reaches the real database, and every insert/
    select touching it starts failing. This adds any such columns as nullable, which is always
    a safe, instant, non-blocking operation in Postgres even on a table with existing rows —
    application code already supplies its own defaults for every new row it writes, so the
    stricter nullability the ORM model declares is enforced there, not at the DB level."""
    inspector = inspect(conn)
    for table in Base.metadata.sorted_tables:
        if table.name not in inspector.get_table_names():
            continue  # create_all just created it fresh above — already has every column
        existing = {col["name"] for col in inspector.get_columns(table.name)}
        for column in table.columns:
            if column.name in existing:
                continue
            ddl_type = column.type.compile(dialect=conn.dialect)
            conn.execute(text(f'ALTER TABLE "{table.name}" ADD COLUMN "{column.name}" {ddl_type}'))


async def init_models() -> None:
    """Create all tables, then backfill any columns models have gained since a table was first
    created (see _add_missing_columns) — runs on every startup, in every environment, same as
    create_all. This is a stopgap in lieu of real migrations, not a replacement for Alembic:
    it only ever adds nullable columns and can't handle renames, drops, or type changes."""
    from app.db.session import engine
    # Import models so they register on Base.metadata before create_all runs.
    from app.models import cart, design, user  # noqa: F401

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        await conn.run_sync(_add_missing_columns)
