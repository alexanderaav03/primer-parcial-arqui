from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.cliente import Cliente


class ClienteRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_by_id(self, cliente_id: int) -> Cliente | None:
        return self.db.get(Cliente, cliente_id)

    def get_by_email(self, email: str) -> Cliente | None:
        stmt = select(Cliente).where(Cliente.email == email)
        return self.db.scalar(stmt)

    def list_by_instructor(self, instructor_id: int) -> list[Cliente]:
        stmt = select(Cliente).where(Cliente.instructor_id == instructor_id).order_by(Cliente.id)
        return list(self.db.scalars(stmt).all())

    def create(self, cliente: Cliente) -> Cliente:
        self.db.add(cliente)
        self.db.commit()
        self.db.refresh(cliente)
        return cliente

    def update(self, cliente: Cliente) -> Cliente:
        self.db.commit()
        self.db.refresh(cliente)
        return cliente
