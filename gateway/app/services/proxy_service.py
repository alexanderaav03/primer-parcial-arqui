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
            detail=f"servicio {service_name} no disponible, intenta más tarde",
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
                "%s %s -> %s no respondió (%sms): %s: %s",
                method,
                url,
                service_name,
                duracion_ms,
                type(exc).__name__,
                exc,
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
        params: dict[str, str] | None = None,
    ) -> Any:
        response = await self._request("GET", url, headers=headers, params=params, service_name=service_name)
        if response.status_code >= status.HTTP_500_INTERNAL_SERVER_ERROR:
            raise self._service_unavailable(service_name)
        if response.status_code != status.HTTP_200_OK:
            try:
                detail = response.json()
            except Exception:
                detail = response.text
            raise HTTPException(status_code=response.status_code, detail=detail)
        return response.json()

    async def _fetch_ejercicios_batch(
        self,
        ejercicio_ids: set[int],
        *,
        headers: dict[str, str],
    ) -> dict[int, dict[str, Any]]:
        """Una sola llamada a ms-ejercicios para resolver varios ejercicio_id
        a la vez (evita el N+1 de pedirlos uno por uno). Devuelve un dict
        ejercicio_id -> ejercicio; los ids que ms-ejercicios no devolvió
        (borrados, o sin permiso) simplemente no están en el dict.
        """
        if not ejercicio_ids:
            return {}

        url = f"{self.ejercicios_base}/api/ejercicios/batch"
        ids_param = ",".join(str(i) for i in sorted(ejercicio_ids))
        ejercicios = await self.get_json(
            url,
            headers=headers,
            service_name="ms-ejercicios",
            params={"ids": ids_param},
        )
        return {ejercicio["id"]: ejercicio for ejercicio in ejercicios}

    async def get_rutina_detalle(self, request: Request, rutina_id: int) -> JSONResponse:
        headers = self._forward_headers(request)

        rutina_url = f"{self.rutinas_base}/api/rutinas/{rutina_id}"
        detalles_url = f"{self.rutinas_base}/api/rutinas/{rutina_id}/detalles"

        rutina, detalles = await asyncio.gather(
            self.get_json(rutina_url, headers=headers, service_name="ms-rutinas"),
            self.get_json(detalles_url, headers=headers, service_name="ms-rutinas"),
        )

        ejercicios_por_id = await self._fetch_ejercicios_batch(
            {detalle["ejercicio_id"] for detalle in detalles},
            headers=headers,
        )

        def combinar(detalle: dict[str, Any]) -> dict[str, Any]:
            ejercicio_id = detalle["ejercicio_id"]
            ejercicio = ejercicios_por_id.get(ejercicio_id)
            if ejercicio is None:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Ejercicio {ejercicio_id} no encontrado",
                )
            return {
                "detalle_id": detalle["detalle_id"],
                "ejercicio_id": ejercicio_id,
                "nombre": ejercicio["nombre"],
                "descripcion": ejercicio["descripcion"],
                "imagen_url": ejercicio.get("imagen_url"),
                "video_url": ejercicio.get("video_url"),
                "tiene_ejemplo_completo": ejercicio["tiene_ejemplo_completo"],
                "repeticiones": detalle["repeticiones"],
                "series": detalle["series"],
                "sesiones_por_semana": detalle["sesiones_por_semana"],
                "peso": detalle["peso"],
                "descanso_serie": detalle["descanso_serie"],
                "descanso_ejercicio": detalle["descanso_ejercicio"],
                "rpe": detalle["rpe"],
            }

        payload = {
            "id": rutina["id"],
            "cliente_id": rutina["cliente_id"],
            "nombre": rutina["nombre"],
            "fecha_inicio": rutina["fecha_inicio"],
            "fecha_fin": rutina["fecha_fin"],
            "ejercicios": [combinar(detalle) for detalle in detalles],
        }
        return JSONResponse(content=payload)


proxy_service = ProxyService()
