from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.clients.rutinas_client import rutinas_client
from app.dependencies import CurrentUser
from app.models.ejercicio import Ejercicio
from app.repositories.cliente_repository import ClienteRepository
from app.repositories.ejercicio_repository import EjercicioRepository
from app.schemas.ejercicio import EjercicioCreate, EjercicioResponse
from app.storage.supabase_client import supabase_storage


class EjercicioService:
    def __init__(self, db: Session) -> None:
        self.ejercicio_repo = EjercicioRepository(db)
        self.cliente_repo = ClienteRepository(db)

    def list_by_instructor(self, instructor_id: int) -> list[EjercicioResponse]:
        ejercicios = self.ejercicio_repo.list_by_instructor(instructor_id)
        return [EjercicioResponse.model_validate(e) for e in ejercicios]

    def get_by_id(self, ejercicio_id: int, current_user: CurrentUser) -> EjercicioResponse:
        ejercicio = self.ejercicio_repo.get_by_id(ejercicio_id)
        if ejercicio is not None and self._puede_ver(ejercicio, current_user):
            return EjercicioResponse.model_validate(ejercicio)

        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ejercicio no encontrado",
        )

    def get_by_ids(self, ids: list[int], current_user: CurrentUser) -> list[EjercicioResponse]:
        """Para el batch del gateway (evita el N+1 al armar el detalle de una
        rutina): misma regla de visibilidad que get_by_id, pero en una sola
        consulta. Los ids que no existen o no son visibles para este usuario
        simplemente no aparecen en la respuesta -no es un error-.
        """
        if not ids:
            return []

        ejercicios = self.ejercicio_repo.list_by_ids(ids)
        visibles = [e for e in ejercicios if self._puede_ver(e, current_user)]
        return [EjercicioResponse.model_validate(e) for e in visibles]

    def _puede_ver(self, ejercicio: Ejercicio, current_user: CurrentUser) -> bool:
        if current_user.rol == "instructor":
            return ejercicio.instructor_id == current_user.id

        if current_user.rol == "cliente":
            cliente = self.cliente_repo.get_by_id(current_user.id)
            return cliente is not None and ejercicio.instructor_id == cliente.instructor_id

        return False

    def create(self, instructor_id: int, data: EjercicioCreate) -> EjercicioResponse:
        imagen_url = supabase_storage.upload_or_use_url(None, None, data.imagen_url)
        video_url = supabase_storage.upload_or_use_url(None, None, data.video_url)

        ejercicio = Ejercicio(
            instructor_id=instructor_id,
            nombre=data.nombre,
            descripcion=data.descripcion,
            imagen_url=imagen_url,
            video_url=video_url,
            tiene_ejemplo_completo=False,
            repeticiones_sugeridas=data.repeticiones_sugeridas,
            series_sugeridas=data.series_sugeridas,
            peso_sugerido=data.peso_sugerido,
            descanso_serie_sugerido=data.descanso_serie_sugerido,
            descanso_ejercicio_sugerido=data.descanso_ejercicio_sugerido,
            rpe_sugerido=data.rpe_sugerido,
        )
        created = self.ejercicio_repo.create(ejercicio)
        return EjercicioResponse.model_validate(created)

    def update(self, ejercicio_id: int, instructor_id: int, data: EjercicioCreate) -> EjercicioResponse:
        ejercicio = self.ejercicio_repo.get_by_id(ejercicio_id)
        if ejercicio is None or ejercicio.instructor_id != instructor_id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Ejercicio no encontrado",
            )

        imagen_url = supabase_storage.upload_or_use_url(None, None, data.imagen_url)
        video_url = supabase_storage.upload_or_use_url(None, None, data.video_url)

        ejercicio.nombre = data.nombre
        ejercicio.descripcion = data.descripcion
        ejercicio.imagen_url = imagen_url
        ejercicio.video_url = video_url
        ejercicio.repeticiones_sugeridas = data.repeticiones_sugeridas
        ejercicio.series_sugeridas = data.series_sugeridas
        ejercicio.peso_sugerido = data.peso_sugerido
        ejercicio.descanso_serie_sugerido = data.descanso_serie_sugerido
        ejercicio.descanso_ejercicio_sugerido = data.descanso_ejercicio_sugerido
        ejercicio.rpe_sugerido = data.rpe_sugerido

        updated = self.ejercicio_repo.update(ejercicio)
        return EjercicioResponse.model_validate(updated)

    async def delete(self, ejercicio_id: int, instructor_id: int, bearer_token: str) -> None:
        ejercicio = self.ejercicio_repo.get_by_id(ejercicio_id)
        if ejercicio is None or ejercicio.instructor_id != instructor_id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Ejercicio no encontrado",
            )

        en_uso = await rutinas_client.existe_en_detalle(ejercicio_id, bearer_token)
        if en_uso:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="No se puede eliminar: este ejercicio está siendo usado en una o más rutinas existentes",
            )

        self.ejercicio_repo.delete(ejercicio)
