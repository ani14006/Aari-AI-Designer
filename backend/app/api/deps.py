"""Shared FastAPI dependencies for the API layer."""
from typing import Any

from fastapi import Depends
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.supabase_auth import verify_supabase_token
from app.db.session import get_db
from app.models.user import User


async def get_current_user(
    decoded_token: dict[str, Any] = Depends(verify_supabase_token),
    db: AsyncSession = Depends(get_db),
) -> User:
    """Resolve (or lazily create) the local User row backing the authenticated Supabase account."""
    supabase_uid = decoded_token["sub"]
    result = await db.execute(select(User).where(User.supabase_uid == supabase_uid))
    user = result.scalar_one_or_none()

    if user is None:
        user_metadata = decoded_token.get("user_metadata") or {}
        user = User(
            supabase_uid=supabase_uid,
            email=decoded_token.get("email", f"{supabase_uid}@unknown.local"),
            display_name=user_metadata.get("full_name") or user_metadata.get("name", ""),
            photo_url=user_metadata.get("avatar_url") or user_metadata.get("picture", ""),
        )
        db.add(user)
        try:
            await db.commit()
        except IntegrityError:
            # A concurrent request (e.g. two tabs/requests firing right after first sign-in)
            # already inserted this user — roll back and fetch the row it created instead.
            await db.rollback()
            result = await db.execute(select(User).where(User.supabase_uid == supabase_uid))
            user = result.scalar_one_or_none()
            if user is None:
                raise
        else:
            await db.refresh(user)

    return user
