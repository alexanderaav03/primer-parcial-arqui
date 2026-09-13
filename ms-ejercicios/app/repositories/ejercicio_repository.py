from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.ejercicio import Ejercicio


class EjercicioRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_by_id(self, ejercicio_id: int) -> Ejercicio | None:
        return self.db.get(Ejercicio, ejercicio_id)

    def list_by_ids(self, ids: list[int]) -> list[Ejercicio]:
        stmt = select(Ejercicio).where(Ejercicio.id.in_(ids))
        return list(self.db.scalars(stmt).all())

    def list_by_instructor(self, instructor_id: int) -> list[Ejercicio]:
        stmt = select(Ejercicio).where(Ejercicio.instructor_id == instructor_id).order_by(Ejercicio.id)
        return list(self.db.scalars(stmt).all())

    def create(self, ejercicio: Ejercicio) -> Ejercicio:
        self.db.add(ejercicio)
        self.db.commit()
        self.db.refresh(ejercicio)
        return ejercicio

    def update(self, ejercicio: Ejercicio) -> Ejercicio:
        self.db.commit()
        self.db.refresh(ejercicio)
        return ejercicio

    def delete(self, ejercicio: Ejercicio) -> None:
        self.db.delete(ejercicio)
        self.db.commit()
