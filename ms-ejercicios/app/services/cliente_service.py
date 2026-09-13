from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.cliente import Cliente
from app.repositories.cliente_repository import ClienteRepository
from app.repositories.instructor_repository import InstructorRepository
from app.schemas.cliente import ClienteCreate, ClienteResponse, ClienteUpdate
from app.security import hash_password


class ClienteService:
    def __init__(self, db: Session) -> None:
        self.cliente_repo = ClienteRepository(db)
        self.instructor_repo = InstructorRepository(db)

    def list_by_instructor(self, instructor_id: int) -> list[ClienteResponse]:
        clientes = self.cliente_repo.list_by_instructor(instructor_id)
        return [ClienteResponse.model_validate(c) for c in clientes]

    def create(self, instructor_id: int, data: ClienteCreate) -> ClienteResponse:
        if self.cliente_repo.get_by_email(data.email):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="El email ya está registrado",
            )

        if self.instructor_repo.get_by_email(data.email):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="El email ya está registrado",
            )

        cliente = Cliente(
            instructor_id=instructor_id,
            nombre=data.nombre,
            objetivo=data.objetivo,
            email=data.email,
            password_hash=hash_password(data.password),
            rol="cliente",
        )
        created = self.cliente_repo.create(cliente)
        return ClienteResponse.model_validate(created)

    def update(self, instructor_id: int, cliente_id: int, data: ClienteUpdate) -> ClienteResponse:
        cliente = self.cliente_repo.get_by_id(cliente_id)
        if cliente is None or cliente.instructor_id != instructor_id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Cliente no encontrado",
            )

        cliente.nombre = data.nombre
        cliente.objetivo = data.objetivo
        updated = self.cliente_repo.update(cliente)
        return ClienteResponse.model_validate(updated)
