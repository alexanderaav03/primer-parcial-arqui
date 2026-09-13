from fastapi import APIRouter, Request, Response

from app.config import settings
from app.services.proxy_service import proxy_service

router = APIRouter(tags=["ejercicios"])

EJERCICIOS_BASE = settings.MS_EJERCICIOS_URL.rstrip("/")


@router.get("/ejercicios")
async def list_ejercicios(request: Request) -> Response:
    return await proxy_service.forward(
        request,
        base_url=EJERCICIOS_BASE,
        path="/api/ejercicios",
        service_name="ms-ejercicios",
    )


@router.post("/ejercicios")
async def create_ejercicio(request: Request) -> Response:
    return await proxy_service.forward(
        request,
        base_url=EJERCICIOS_BASE,
        path="/api/ejercicios",
        service_name="ms-ejercicios",
    )


@router.get("/ejercicios/{ejercicio_id}")
async def get_ejercicio(ejercicio_id: int, request: Request) -> Response:
    return await proxy_service.forward(
        request,
        base_url=EJERCICIOS_BASE,
        path=f"/api/ejercicios/{ejercicio_id}",
        service_name="ms-ejercicios",
    )


@router.put("/ejercicios/{ejercicio_id}")
async def update_ejercicio(ejercicio_id: int, request: Request) -> Response:
    return await proxy_service.forward(
        request,
        base_url=EJERCICIOS_BASE,
        path=f"/api/ejercicios/{ejercicio_id}",
        service_name="ms-ejercicios",
    )


@router.delete("/ejercicios/{ejercicio_id}")
async def delete_ejercicio(ejercicio_id: int, request: Request) -> Response:
    return await proxy_service.forward(
        request,
        base_url=EJERCICIOS_BASE,
        path=f"/api/ejercicios/{ejercicio_id}",
        service_name="ms-ejercicios",
    )


@router.get("/clientes")
async def list_clientes(request: Request) -> Response:
    return await proxy_service.forward(
        request,
        base_url=EJERCICIOS_BASE,
        path="/api/clientes",
        service_name="ms-ejercicios",
    )


@router.post("/clientes")
async def create_cliente(request: Request) -> Response:
    return await proxy_service.forward(
        request,
        base_url=EJERCICIOS_BASE,
        path="/api/clientes",
        service_name="ms-ejercicios",
    )


@router.put("/clientes/{cliente_id}")
async def update_cliente(cliente_id: int, request: Request) -> Response:
    return await proxy_service.forward(
        request,
        base_url=EJERCICIOS_BASE,
        path=f"/api/clientes/{cliente_id}",
        service_name="ms-ejercicios",
    )


@router.delete("/clientes/{cliente_id}")
async def delete_cliente(cliente_id: int, request: Request) -> Response:
    return await proxy_service.forward(
        request,
        base_url=EJERCICIOS_BASE,
        path=f"/api/clientes/{cliente_id}",
        service_name="ms-ejercicios",
    )
