"""Declarative base + helper for creating all tables (dev convenience; use Alembic in prod)."""
from datetime import datetime

from sqlalchemy import DateTime, String, Text, inspect, text
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


def _widen_narrow_columns(conn: Connection) -> None:
    """Widens any existing column whose real type in the database is still a length-bounded
    VARCHAR from an earlier, narrower version of the model that has since changed to Text —
    e.g. generation_prompt was originally String(4096); the actual prompts built by the
    visualization pipeline run well past that, so every completed generation's final save was
    silently failing against Postgres with a StringDataRightTruncationError, discarding a
    successfully generated image because this one column couldn't hold its own prompt.

    Postgres-only: SQLite doesn't enforce VARCHAR length limits at all (a SQLite VARCHAR(4096)
    column happily stores any length), so this bug can't occur there and SQLite also doesn't
    support ALTER COLUMN ... TYPE the way this needs. Always widens, never narrows — safe and
    effectively instant in Postgres, no data rewrite needed to go from VARCHAR(n) to TEXT."""
    if conn.dialect.name != "postgresql":
        return
    inspector = inspect(conn)
    for table in Base.metadata.sorted_tables:
        if table.name not in inspector.get_table_names():
            continue
        existing = {col["name"]: col for col in inspector.get_columns(table.name)}
        for column in table.columns:
            if not isinstance(column.type, Text):
                continue
            existing_type = existing.get(column.name, {}).get("type")
            if isinstance(existing_type, String) and existing_type.length is not None:
                conn.execute(
                    text(f'ALTER TABLE "{table.name}" ALTER COLUMN "{column.name}" TYPE TEXT')
                )


async def init_models() -> None:
    """Create all tables, then backfill any columns models have gained since a table was first
    created (see _add_missing_columns) and widen any that shrunk from a bounded VARCHAR to Text
    (see _widen_narrow_columns) — runs on every startup, in every environment, same as
    create_all. This is a stopgap in lieu of real migrations, not a replacement for Alembic: it
    only ever adds columns or widens them, and can't handle renames, drops, or narrowing."""
    from app.db.session import engine
    # Import models so they register on Base.metadata before create_all runs.
    from app.models import cart, design, user  # noqa: F401

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        await conn.run_sync(_add_missing_columns)
        await conn.run_sync(_widen_narrow_columns)
