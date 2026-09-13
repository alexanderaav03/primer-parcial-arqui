from fastapi import APIRouter, Request, Response
from starlette.responses import JSONResponse

from app.config import settings
from app.services.proxy_service import proxy_service

router = APIRouter(prefix="/rutinas", tags=["rutinas"])

RUTINAS_BASE = settings.MS_RUTINAS_URL.rstrip("/")


@router.get("")
async def list_rutinas(request: Request) -> Response:
    return await proxy_service.forward(
        request,
        base_url=RUTINAS_BASE,
        path="/api/rutinas",
        service_name="ms-rutinas",
    )


@router.post("")
async def create_rutina(request: Request) -> Response:
    return await proxy_service.forward(
        request,
        base_url=RUTINAS_BASE,
        path="/api/rutinas",
        service_name="ms-rutinas",
    )


@router.get("/{rutina_id}/detalle")
async def get_rutina_detalle(rutina_id: int, request: Request) -> JSONResponse:
    return await proxy_service.get_rutina_detalle(request, rutina_id)


@router.put("/{rutina_id}")
async def update_rutina(rutina_id: int, request: Request) -> Response:
    return await proxy_service.forward(
        request,
        base_url=RUTINAS_BASE,
        path=f"/api/rutinas/{rutina_id}",
        service_name="ms-rutinas",
    )


@router.delete("/{rutina_id}")
async def delete_rutina(rutina_id: int, request: Request) -> Response:
    return await proxy_service.forward(
        request,
        base_url=RUTINAS_BASE,
        path=f"/api/rutinas/{rutina_id}",
        service_name="ms-rutinas",
    )


@router.post("/{rutina_id}/detalles")
async def create_detalle(rutina_id: int, request: Request) -> Response:
    return await proxy_service.forward(
        request,
        base_url=RUTINAS_BASE,
        path=f"/api/rutinas/{rutina_id}/detalles",
        service_name="ms-rutinas",
    )


@router.put("/{rutina_id}/detalles/{detalle_id}")
async def update_detalle(rutina_id: int, detalle_id: int, request: Request) -> Response:
    return await proxy_service.forward(
        request,
        base_url=RUTINAS_BASE,
        path=f"/api/rutinas/{rutina_id}/detalles/{detalle_id}",
        service_name="ms-rutinas",
    )


@router.delete("/{rutina_id}/detalles/{detalle_id}")
async def delete_detalle(rutina_id: int, detalle_id: int, request: Request) -> Response:
    return await proxy_service.forward(
        request,
        base_url=RUTINAS_BASE,
        path=f"/api/rutinas/{rutina_id}/detalles/{detalle_id}",
        service_name="ms-rutinas",
    )


@router.post("/{rutina_id}/detalles/{detalle_id}/registros")
async def create_registro_progreso(rutina_id: int, detalle_id: int, request: Request) -> Response:
    return await proxy_service.forward(
        request,
        base_url=RUTINAS_BASE,
        path=f"/api/rutinas/{rutina_id}/detalles/{detalle_id}/registros",
        service_name="ms-rutinas",
    )


@router.get("/{rutina_id}/detalles/{detalle_id}/registros")
async def list_registros_progreso(rutina_id: int, detalle_id: int, request: Request) -> Response:
    return await proxy_service.forward(
        request,
        base_url=RUTINAS_BASE,
        path=f"/api/rutinas/{rutina_id}/detalles/{detalle_id}/registros",
        service_name="ms-rutinas",
    )
