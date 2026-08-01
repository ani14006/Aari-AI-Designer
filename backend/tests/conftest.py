"""Test configuration: points the app at an isolated SQLite file before anything imports it."""
import os

os.environ.setdefault("DATABASE_URL", "sqlite+aiosqlite:///./test_aari_designer.db")
os.environ.setdefault("ENVIRONMENT", "development")
os.environ.setdefault("DEBUG", "true")
os.environ["SUPABASE_JWT_SECRET"] = "test-jwt-secret"
# Empty on purpose: skips the JWKS network lookup in supabase_auth.py so tests stay hermetic
# and exercise the legacy HS256 shared-secret path deterministically, offline.
os.environ["SUPABASE_URL"] = ""
