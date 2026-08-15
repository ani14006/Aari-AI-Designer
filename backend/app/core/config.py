"""Application configuration loaded from environment variables."""
from functools import lru_cache
from typing import List

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # General
    APP_NAME: str = "Aari AI Designer"
    ENVIRONMENT: str = "development"  # development | production
    API_V1_PREFIX: str = "/api/v1"
    DEBUG: bool = True
    CORS_ORIGINS: List[str] = ["*"]

    # Database
    DATABASE_URL: str = "sqlite+aiosqlite:///./aari_designer.db"
    SQL_ECHO: bool = False  # set true only when actively debugging queries — very noisy

    # Security
    SECRET_KEY: str = "change-this-in-production"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24

    # Supabase Authentication
    SUPABASE_URL: str = ""  # e.g. https://xxxxx.supabase.co
    SUPABASE_JWT_SECRET: str = ""  # Project Settings -> API -> JWT Secret, verifies access tokens

    # Cloudinary
    CLOUDINARY_CLOUD_NAME: str = ""
    CLOUDINARY_API_KEY: str = ""
    CLOUDINARY_API_SECRET: str = ""

    # Gemini — colour/style vision analysis. Image generation uses OpenAI instead (below).
    GEMINI_API_KEY: str = ""
    GEMINI_TEXT_MODEL: str = "gemini-flash-latest"

    # OpenAI — photorealistic preview generation (gpt-image-1). Text-to-image only: the Images
    # API has no image-to-image/editing mode, so the result is generated from a text description
    # of the detected colours/style rather than directly editing the user's uploaded photos.
    OPENAI_API_KEY: str = ""
    OPENAI_IMAGE_MODEL: str = "gpt-image-1"
    # "low" | "medium" | "high" — low is ~3.6x cheaper than medium and ~15x cheaper than high
    # for a 1024x1024 image, at a real cost to visual fidelity. Kept configurable via env so it
    # can be dialled up per-deployment without a code change.
    OPENAI_IMAGE_QUALITY: str = "low"

    # Visualization pipeline (images.edit(), reference-image-faithful rendering)
    OPENAI_EDIT_MODEL: str = "gpt-image-1"
    # "high" is the biggest single latency/cost line in the pipeline (and doubles on the
    # automatic retry when the first attempt's QA score falls short) — tried "medium" for
    # speed, but Aari embroidery's fine beadwork/thread detail needs the crispness "medium"
    # doesn't hold onto. Detail quality wins over generation speed here. Kept configurable via env.
    OPENAI_EDIT_QUALITY: str = "high"
    VISUALIZATION_QA_ACCEPT_THRESHOLD: float = 70.0

    # "View on Mannequin" — separate optional presentation stage, tunable independently of the
    # core visualization pipeline's quality tier above.
    OPENAI_MANNEQUIN_QUALITY: str = "high"

    @property
    def is_production(self) -> bool:
        return self.ENVIRONMENT.lower() == "production"


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
