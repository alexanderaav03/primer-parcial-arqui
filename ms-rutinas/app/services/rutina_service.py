from datetime import date

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.clients.ejercicios_client import ejercicios_client
from app.dependencies import CurrentUser
from app.models.rutina import Rutina
from app.repositories.rutina_repository import RutinaRepository
from app.schemas.rutina import RutinaCreate, RutinaResponse, RutinaUpdate


class RutinaService:
    def __init__(self, db: Session) -> None:
        self.rutina_repo = RutinaRepository(db)

    @staticmethod
    def _ensure_cliente_access(cliente_id: int, current_user: CurrentUser) -> None:
        if current_user.rol == "cliente" and current_user.id != cliente_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No autorizado para consultar rutinas de otro cliente",
            )

    @staticmethod
    def _ensure_rutina_access(rutina: Rutina, current_user: CurrentUser) -> None:
        if current_user.rol == "cliente" and rutina.cliente_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No autorizado para acceder a esta rutina",
            )

    async def _assert_cliente_del_instructor(self, cliente_id: int, bearer_token: str, *, detail: str) -> None:
        """ms-rutinas no sabe localmente de quién es cada cliente (cliente_id
        es un entero suelto, sin relación en su base), así que se lo pregunta
        a ms-ejercicios -mismo patrón que validar un ejercicio_id-. 404 (no
        403) para no revelar existencia si el cliente no es tuyo.
        """
        ids_permitidos = await ejercicios_client.obtener_ids_clientes_del_instructor(bearer_token)
        if cliente_id not in ids_permitidos:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=detail)

    async def assert_instructor_dueno(self, rutina: Rutina, bearer_token: str) -> None:
        """Solo el instructor dueño del cliente de esta rutina puede editarla,
        borrarle detalles, o agregarle detalles."""
        await self._assert_cliente_del_instructor(
            rutina.cliente_id, bearer_token, detail="Rutina no encontrada"
        )

    async def assert_cliente_del_instructor(self, cliente_id: int, bearer_token: str) -> None:
        """Para POST /api/rutinas: valida que cliente_id pertenezca al
        instructor del token antes de crear la rutina."""
        await self._assert_cliente_del_instructor(cliente_id, bearer_token, detail="Cliente no encontrado")

    def list_by_cliente(self, cliente_id: int, current_user: CurrentUser) -> list[RutinaResponse]:
        self._ensure_cliente_access(cliente_id, current_user)
        rutinas = self.rutina_repo.list_by_cliente(cliente_id)
        return [RutinaResponse.model_validate(r) for r in rutinas]

    async def create(self, data: RutinaCreate, bearer_token: str) -> RutinaResponse:
        await self.assert_cliente_del_instructor(data.cliente_id, bearer_token)

        self._validar_sin_solapamiento(
            cliente_id=data.cliente_id,
            fecha_inicio=data.fecha_inicio,
            fecha_fin=data.fecha_fin,
        )

        rutina = Rutina(
            cliente_id=data.cliente_id,
            nombre=data.nombre,
            fecha_inicio=data.fecha_inicio,
            fecha_fin=data.fecha_fin,
        )
        created = self.rutina_repo.create(rutina)
        return RutinaResponse.model_validate(created)

    async def update(self, rutina_id: int, data: RutinaUpdate, bearer_token: str) -> RutinaResponse:
        rutina = self.get_rutina_or_404(rutina_id)
        await self.assert_instructor_dueno(rutina, bearer_token)

        self._validar_sin_solapamiento(
            cliente_id=rutina.cliente_id,
            fecha_inicio=data.fecha_inicio,
            fecha_fin=data.fecha_fin,
            excluir_rutina_id=rutina.id,
        )

        rutina.nombre = data.nombre
        rutina.fecha_inicio = data.fecha_inicio
        rutina.fecha_fin = data.fecha_fin
        updated = self.rutina_repo.update(rutina)
        return RutinaResponse.model_validate(updated)

    def _validar_sin_solapamiento(
        self,
        *,
        cliente_id: int,
        fecha_inicio: date,
        fecha_fin: date,
        excluir_rutina_id: int | None = None,
    ) -> None:
        """Un mismo cliente no puede tener dos rutinas cuyos rangos de
        fecha se crucen. El nombre no se valida -puede repetirse-, solo
        las fechas. Al editar, la propia rutina se excluye de la comparación."""
        existentes = self.rutina_repo.list_by_cliente(cliente_id)
        for existente in existentes:
            if excluir_rutina_id is not None and existente.id == excluir_rutina_id:
                continue

            se_solapan = fecha_inicio <= existente.fecha_fin and fecha_fin >= existente.fecha_inicio
            if se_solapan:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=(
                        f"Ya existe una rutina para este cliente entre {existente.fecha_inicio} "
                        f"y {existente.fecha_fin} que se cruza con las fechas ingresadas"
                    ),
                )

    def get_by_id(self, rutina_id: int, current_user: CurrentUser) -> RutinaResponse:
        rutina = self.rutina_repo.get_by_id(rutina_id)
        if rutina is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Rutina no encontrada",
            )
        self._ensure_rutina_access(rutina, current_user)
        return RutinaResponse.model_validate(rutina)

    def get_rutina_or_404(self, rutina_id: int) -> Rutina:
        rutina = self.rutina_repo.get_by_id(rutina_id)
        if rutina is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Rutina no encontrada",
            )
        return rutina
