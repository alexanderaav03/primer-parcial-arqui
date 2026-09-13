from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.detalle_rutina import DetalleRutina


class DetalleRutinaRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def list_by_rutina(self, rutina_id: int) -> list[DetalleRutina]:
        stmt = (
            select(DetalleRutina)
            .where(DetalleRutina.rutina_id == rutina_id)
            .order_by(DetalleRutina.id)
        )
        return list(self.db.scalars(stmt).all())

    def create(self, detalle: DetalleRutina) -> DetalleRutina:
        self.db.add(detalle)
        self.db.commit()
        self.db.refresh(detalle)
        return detalle

    def get_by_id(self, detalle_id: int) -> DetalleRutina | None:
        return self.db.get(DetalleRutina, detalle_id)

    def delete(self, detalle: DetalleRutina) -> None:
        self.db.delete(detalle)
        self.db.commit()

    def exists_by_ejercicio(self, ejercicio_id: int) -> bool:
        stmt = select(DetalleRutina.id).where(DetalleRutina.ejercicio_id == ejercicio_id).limit(1)
        return self.db.scalars(stmt).first() is not None
