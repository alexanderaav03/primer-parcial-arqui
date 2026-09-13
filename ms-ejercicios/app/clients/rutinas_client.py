import httpx
from fastapi import HTTPException, status

from app.config import settings

TIMEOUT_SECONDS = 5.0


class RutinasClient:
    def __init__(self) -> None:
        self.base_url = settings.MS_RUTINAS_URL.rstrip("/")

    async def _get_en_uso(self, path: str, bearer_token: str) -> bool:
        url = f"{self.base_url}{path}"
        headers = {"Authorization": f"Bearer {bearer_token}"}

        try:
            async with httpx.AsyncClient(timeout=TIMEOUT_SECONDS) as client:
                response = await client.get(url, headers=headers)
        except (httpx.RequestError, httpx.TimeoutException):
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="servicio de rutinas no disponible",
            ) from None

        if response.status_code != status.HTTP_200_OK:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="servicio de rutinas no disponible",
            )

        return bool(response.json().get("en_uso"))

    async def existe_en_detalle(self, ejercicio_id: int, bearer_token: str) -> bool:
        """True si ese ejercicio_id está referenciado en algún DetalleRutina
        (de cualquier rutina/cliente) según ms-rutinas. Mismo patrón espejado
        que EjerciciosClient.validate_ejercicio, en la dirección contraria:
        ms-ejercicios necesita saber esto antes de permitir borrar un
        ejercicio del banco -esa tabla vive en la base de ms-rutinas-.
        """
        return await self._get_en_uso(f"/api/detalles/existe-ejercicio/{ejercicio_id}", bearer_token)

    async def existe_cliente_con_rutina(self, cliente_id: int, bearer_token: str) -> bool:
        """True si ese cliente_id tiene alguna Rutina asociada según
        ms-rutinas. La usa ms-ejercicios antes de permitir borrar un
        cliente -esa tabla vive en la base de ms-rutinas-.
        """
        return await self._get_en_uso(f"/api/detalles/existe-cliente/{cliente_id}", bearer_token)


rutinas_client = RutinasClient()
