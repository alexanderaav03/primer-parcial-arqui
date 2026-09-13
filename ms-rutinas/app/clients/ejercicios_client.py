import httpx
from fastapi import HTTPException, status

from app.config import settings

TIMEOUT_SECONDS = 5.0


class EjerciciosClient:
    def __init__(self) -> None:
        self.base_url = settings.MS_EJERCICIOS_URL.rstrip("/")

    async def validate_ejercicio(self, ejercicio_id: int, bearer_token: str) -> None:
        url = f"{self.base_url}/api/ejercicios/{ejercicio_id}"
        headers = {"Authorization": f"Bearer {bearer_token}"}

        try:
            async with httpx.AsyncClient(timeout=TIMEOUT_SECONDS) as client:
                response = await client.get(url, headers=headers)
        except (httpx.RequestError, httpx.TimeoutException):
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="servicio de ejercicios no disponible",
            ) from None

        if response.status_code == status.HTTP_404_NOT_FOUND:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="ejercicio no existe",
            )

        if response.status_code >= status.HTTP_500_INTERNAL_SERVER_ERROR:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="servicio de ejercicios no disponible",
            )

        if response.status_code != status.HTTP_200_OK:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="ejercicio no existe",
            )

    async def obtener_ids_clientes_del_instructor(self, bearer_token: str) -> set[int]:
        """IDs de los clientes que pertenecen al instructor dueño de bearer_token.

        ms-rutinas no tiene relación instructor-cliente en su propia base (cliente_id
        es un entero suelto, sin FK), así que para saber "de quién es este cliente"
        hay que preguntarle a ms-ejercicios -mismo patrón que validate_ejercicio-.
        GET /api/clientes ya viene filtrado del lado de ms-ejercicios por el
        instructor del token.
        """
        url = f"{self.base_url}/api/clientes"
        headers = {"Authorization": f"Bearer {bearer_token}"}

        try:
            async with httpx.AsyncClient(timeout=TIMEOUT_SECONDS) as client:
                response = await client.get(url, headers=headers)
        except (httpx.RequestError, httpx.TimeoutException):
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="servicio de ejercicios no disponible",
            ) from None

        if response.status_code >= status.HTTP_500_INTERNAL_SERVER_ERROR:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="servicio de ejercicios no disponible",
            )

        if response.status_code != status.HTTP_200_OK:
            return set()

        return {cliente["id"] for cliente in response.json()}


ejercicios_client = EjerciciosClient()
