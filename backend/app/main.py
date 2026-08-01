"""Aari AI Designer — FastAPI application entrypoint."""
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.v1.router import api_router
from app.core.config import settings
from app.core.logging import configure_logging
from app.db.base import init_models
from app.utils.exceptions import AariDesignerError

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(_app: FastAPI):
    configure_logging()
    if not settings.is_production:
        # Convenience for local dev; production environments should run Alembic migrations instead.
        await init_models()
    logger.info("%s started (environment=%s)", settings.APP_NAME, settings.ENVIRONMENT)
    yield


app = FastAPI(
    title=settings.APP_NAME,
    version="1.0.0",
    description="Premium AI-powered Aari embroidery visualization platform.",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(AariDesignerError)
async def handle_domain_error(_request: Request, exc: AariDesignerError) -> JSONResponse:
    logger.warning("%s: %s", exc.__class__.__name__, exc.message)
    return JSONResponse(status_code=exc.status_code, content={"detail": exc.message})


@app.exception_handler(Exception)
async def handle_unexpected_error(request: Request, exc: Exception) -> JSONResponse:
    # Starlette routes the bare-Exception handler through ServerErrorMiddleware, which sits
    # *outside* CORSMiddleware — so without manually adding these headers here, the browser
    # can't read the response at all and reports an opaque network error instead of this
    # error's actual message. Handlers registered for our own AariDesignerError subclasses
    # don't need this: those stay inside CORSMiddleware's wrapping and get headers normally.
    logger.exception("Unhandled exception while processing request")
    detail = str(exc) if settings.DEBUG else "Internal server error."
    origin = request.headers.get("origin")
    headers = {"Access-Control-Allow-Credentials": "true"}
    if origin and (settings.CORS_ORIGINS == ["*"] or origin in settings.CORS_ORIGINS):
        headers["Access-Control-Allow-Origin"] = origin
    return JSONResponse(status_code=500, content={"detail": detail}, headers=headers)


@app.get("/health", tags=["health"])
async def health_check() -> dict[str, str]:
    return {"status": "ok", "app": settings.APP_NAME}


app.include_router(api_router, prefix=settings.API_V1_PREFIX)
