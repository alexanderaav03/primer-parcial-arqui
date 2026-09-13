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

    def exists_by_cliente(self, cliente_id: int) -> bool:
        stmt = select(Rutina.id).where(Rutina.cliente_id == cliente_id).limit(1)
        return self.db.scalars(stmt).first() is not None

    def delete(self, rutina: Rutina) -> None:
        # cascade="all, delete-orphan" en Rutina.detalles se encarga de borrar
        # sus DetalleRutina; a su vez, la FK ondelete=CASCADE de
        # RegistroProgreso se encarga de esos -pero eso solo importa si
        # existieran, y el caller ya confirmó que no antes de llegar aquí-.
        self.db.delete(rutina)
        self.db.commit()
