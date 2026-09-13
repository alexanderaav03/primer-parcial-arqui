from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.rutina import Rutina


class RutinaRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_by_id(self, rutina_id: int) -> Rutina | None:
        return self.db.get(Rutina, rutina_id)

    def list_by_cliente(self, cliente_id: int) -> list[Rutina]:
        stmt = select(Rutina).where(Rutina.cliente_id == cliente_id).order_by(Rutina.id)
        return list(self.db.scalars(stmt).all())

    def create(self, rutina: Rutina) -> Rutina:
        self.db.add(rutina)
        self.db.commit()
        self.db.refresh(rutina)
        return rutina

    def update(self, rutina: Rutina) -> Rutina:
        self.db.commit()
        self.db.refresh(rutina)
        return rutina
