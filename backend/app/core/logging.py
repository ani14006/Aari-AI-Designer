"""Structured logging setup, applied once at application startup."""
import logging
import sys

from app.core.config import settings

_LOG_FORMAT = "%(asctime)s | %(levelname)-8s | %(name)s | %(message)s"


def configure_logging() -> None:
    level = logging.DEBUG if settings.DEBUG else logging.INFO
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(logging.Formatter(_LOG_FORMAT, datefmt="%Y-%m-%d %H:%M:%S"))

    root = logging.getLogger()
    root.setLevel(level)
    root.handlers = [handler]

    # Quiet noisy third-party loggers unless we're actively debugging.
    for noisy in ("httpx", "httpcore", "urllib3", "aiosqlite", "sqlalchemy.engine"):
        logging.getLogger(noisy).setLevel(logging.WARNING)
