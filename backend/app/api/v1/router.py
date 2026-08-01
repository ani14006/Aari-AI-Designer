"""Aggregates all v1 API routers under a single prefix."""
from fastapi import APIRouter

from app.api.v1.endpoints import analysis, auth, cart, designs, generation, mannequin, uploads

api_router = APIRouter()
api_router.include_router(auth.router)
api_router.include_router(uploads.router)
api_router.include_router(analysis.router)
api_router.include_router(generation.router)
api_router.include_router(mannequin.router)
api_router.include_router(designs.router)
api_router.include_router(cart.router)
