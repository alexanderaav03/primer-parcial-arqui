import asyncio
import logging
import time
from typing import Any

import httpx
from fastapi import HTTPException, Request, Response, status
from starlette.responses import JSONResponse

from app.config import settings

logger = logging.getLogger("gateway")

TIMEOUT_SECONDS = 10.0

HOP_BY_HOP_HEADERS = {
    "connection",
    "keep-alive",
    "proxy-authenticate",
    "proxy-authorization",
    "te",
    "trailers",
    "transfer-encoding",
    "upgrade",
    "host",
    "content-length",
}


class ProxyService:
    def __init__(self) -> None:
        self.ejercicios_base = settings.MS_EJERCICIOS_URL.rstrip("/")
        self.rutinas_base = settings.MS_RUTINAS_URL.rstrip("/")

    @staticmethod
    def _forward_headers(request: Request) -> dict[str, str]:
        return {
            key: value
            for key, value in request.headers.items()
            if key.lower() not in HOP_BY_HOP_HEADERS
        }

    @staticmethod
    def _service_unavailable(service_name: str) -> HTTPException:
        return HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"servicio {service_name} no disponible",
        )

    async def _request(
        self,
        method: str,
        url: str,
        *,
        headers: dict[str, str],
        params: dict[str, str] | None = None,
        content: bytes | None = None,
        service_name: str,
    ) -> httpx.Response:
        inicio = time.perf_counter()
        try:
            async with httpx.AsyncClient(timeout=TIMEOUT_SECONDS) as client:
                response = await client.request(
                    method=method,
                    url=url,
                    headers=headers,
                    params=params,
                    content=content,
                )
        except (httpx.RequestError, httpx.TimeoutException) as exc:
            duracion_ms = int((time.perf_counter() - inicio) * 1000)
            logger.error(
                "%s %s -> %s no respondió (%sms)", method, url, service_name, duracion_ms
            )
            raise self._service_unavailable(service_name) from exc

        duracion_ms = int((time.perf_counter() - inicio) * 1000)
        logger.info(
            "%s %s -> reenviado a %s, respondió %s (%sms)",
            method,
            url,
            service_name,
            response.status_code,
            duracion_ms,
        )
        return response

    async def forward(
        self,
        request: Request,
        *,
        base_url: str,
        path: str,
        service_name: str,
    ) -> Response:
        url = f"{base_url}{path}"
        body = await request.body()
        headers = self._forward_headers(request)
        params = dict(request.query_params)

        upstream = await self._request(
            request.method,
            url,
            headers=headers,
            params=params or None,
            content=body if body else None,
            service_name=service_name,
        )

        response_headers = {
            key: value
            for key, value in upstream.headers.items()
            if key.lower() not in HOP_BY_HOP_HEADERS
        }
        return Response(
            content=upstream.content,
            status_code=upstream.status_code,
            headers=response_headers,
            media_type=upstream.headers.get("content-type"),
        )

    async def get_json(
        self,
        url: str,
        *,
        headers: dict[str, str],
        service_name: str,
    ) -> Any:
        response = await self._request("GET", url, headers=headers, service_name=service_name)
        if response.status_code >= status.HTTP_500_INTERNAL_SERVER_ERROR:
            raise self._service_unavailable(service_name)
        if response.status_code != status.HTTP_200_OK:
            try:
                detail = response.json()
            except Exception:
                detail = response.text
            raise HTTPException(status_code=response.status_code, detail=detail)
        return response.json()

    async def get_rutina_detalle(self, request: Request, rutina_id: int) -> JSONResponse:
        headers = self._forward_headers(request)

        rutina_url = f"{self.rutinas_base}/api/rutinas/{rutina_id}"
        detalles_url = f"{self.rutinas_base}/api/rutinas/{rutina_id}/detalles"

        rutina, detalles = await asyncio.gather(
            self.get_json(rutina_url, headers=headers, service_name="ms-rutinas"),
            self.get_json(detalles_url, headers=headers, service_name="ms-rutinas"),
        )

        async def fetch_ejercicio(detalle: dict[str, Any]) -> dict[str, Any]:
            ejercicio_id = detalle["ejercicio_id"]
            ejercicio_url = f"{self.ejercicios_base}/api/ejercicios/{ejercicio_id}"
            ejercicio = await self.get_json(
                ejercicio_url,
                headers=headers,
                service_name="ms-ejercicios",
            )
            return {
                "detalle_id": detalle["detalle_id"],
                "ejercicio_id": detalle["ejercicio_id"],
                "nombre": ejercicio["nombre"],
                "descripcion": ejercicio["descripcion"],
                "imagen_url": ejercicio.get("imagen_url"),
                "video_url": ejercicio.get("video_url"),
                "tiene_ejemplo_completo": ejercicio["tiene_ejemplo_completo"],
                "repeticiones": detalle["repeticiones"],
                "series": detalle["series"],
                "peso": detalle["peso"],
                "descanso_serie": detalle["descanso_serie"],
                "descanso_ejercicio": detalle["descanso_ejercicio"],
                "rpe": detalle["rpe"],
            }

        ejercicios = await asyncio.gather(*(fetch_ejercicio(d) for d in detalles))

        payload = {
            "id": rutina["id"],
            "cliente_id": rutina["cliente_id"],
            "nombre": rutina["nombre"],
            "fecha_inicio": rutina["fecha_inicio"],
            "fecha_fin": rutina["fecha_fin"],
            "ejercicios": list(ejercicios),
        }
        return JSONResponse(content=payload)


proxy_service = ProxyService()
