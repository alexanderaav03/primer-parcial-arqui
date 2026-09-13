from fastapi import APIRouter, Request, Response

from app.config import settings
from app.services.proxy_service import proxy_service

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/registro")
async def registro(request: Request) -> Response:
    return await proxy_service.forward(
        request,
        base_url=settings.MS_EJERCICIOS_URL.rstrip("/"),
        path="/api/auth/registro",
        service_name="ms-ejercicios",
    )


@router.post("/login")
async def login(request: Request) -> Response:
    return await proxy_service.forward(
        request,
        base_url=settings.MS_EJERCICIOS_URL.rstrip("/"),
        path="/api/auth/login",
        service_name="ms-ejercicios",
    )
