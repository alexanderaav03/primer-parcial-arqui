from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.registro_progreso import RegistroProgreso


class RegistroProgresoRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def list_by_detalle(self, detalle_rutina_id: int) -> list[RegistroProgreso]:
        stmt = (
            select(RegistroProgreso)
            .where(RegistroProgreso.detalle_rutina_id == detalle_rutina_id)
            .order_by(RegistroProgreso.fecha.desc())
        )
        return list(self.db.scalars(stmt).all())

    def create(self, registro: RegistroProgreso) -> RegistroProgreso:
        self.db.add(registro)
        self.db.commit()
        self.db.refresh(registro)
        return registro
