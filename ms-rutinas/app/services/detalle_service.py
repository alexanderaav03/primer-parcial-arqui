from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.clients.ejercicios_client import ejercicios_client
from app.dependencies import CurrentUser
from app.models.detalle_rutina import DetalleRutina
from app.repositories.detalle_rutina_repository import DetalleRutinaRepository
from app.schemas.detalle_rutina import DetalleRutinaCreate, DetalleRutinaResponse
from app.services.rutina_service import RutinaService


class DetalleService:
    def __init__(self, db: Session) -> None:
        self.detalle_repo = DetalleRutinaRepository(db)
        self.rutina_service = RutinaService(db)

    def list_by_rutina(self, rutina_id: int, current_user: CurrentUser) -> list[DetalleRutinaResponse]:
        rutina = self.rutina_service.get_rutina_or_404(rutina_id)
        self.rutina_service._ensure_rutina_access(rutina, current_user)
        detalles = self.detalle_repo.list_by_rutina(rutina_id)
        return [DetalleRutinaResponse.from_model(d) for d in detalles]

    async def create(
        self,
        rutina_id: int,
        data: DetalleRutinaCreate,
        bearer_token: str,
    ) -> DetalleRutinaResponse:
        rutina = self.rutina_service.get_rutina_or_404(rutina_id)
        await self.rutina_service.assert_instructor_dueno(rutina, bearer_token)
        await ejercicios_client.validate_ejercicio(data.ejercicio_id, bearer_token)

        detalle = DetalleRutina(
            rutina_id=rutina_id,
            ejercicio_id=data.ejercicio_id,
            repeticiones=data.repeticiones,
            series=data.series,
            sesiones_por_semana=data.sesiones_por_semana,
            peso=data.peso,
            descanso_serie=data.descanso_serie,
            descanso_ejercicio=data.descanso_ejercicio,
            rpe=data.rpe,
        )
        created = self.detalle_repo.create(detalle)
        return DetalleRutinaResponse.from_model(created)

    async def delete(self, rutina_id: int, detalle_id: int, bearer_token: str) -> None:
        rutina = self.rutina_service.get_rutina_or_404(rutina_id)
        await self.rutina_service.assert_instructor_dueno(rutina, bearer_token)

        detalle = self.detalle_repo.get_by_id(detalle_id)
        if detalle is None or detalle.rutina_id != rutina_id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Detalle no encontrado",
            )

        self.detalle_repo.delete(detalle)

    def existe_ejercicio(self, ejercicio_id: int) -> bool:
        """True si el ejercicio está referenciado en algún DetalleRutina, de
        cualquier rutina/cliente -no filtra por instructor-. La usa
        ms-ejercicios antes de permitir borrar un ejercicio del banco."""
        return self.detalle_repo.exists_by_ejercicio(ejercicio_id)
