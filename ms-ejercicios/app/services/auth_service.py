import re

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app import rate_limiter
from app.models.cliente import Cliente
from app.models.instructor import Instructor
from app.repositories.cliente_repository import ClienteRepository
from app.repositories.instructor_repository import InstructorRepository
from app.schemas.auth import LoginRequest, RegistroRequest, TokenResponse, UsuarioResponse
from app.security import create_access_token, hash_password, verify_password

PASSWORD_MIN_LENGTH = 8


def _validar_fortaleza_password(password: str) -> None:
    errores = []
    if len(password) < PASSWORD_MIN_LENGTH:
        errores.append(f"al menos {PASSWORD_MIN_LENGTH} caracteres")
    if not re.search(r"[A-Za-z]", password):
        errores.append("al menos una letra")
    if not re.search(r"\d", password):
        errores.append("al menos un número")

    if errores:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"La contraseña debe tener {', '.join(errores)}",
        )


class AuthService:
    def __init__(self, db: Session) -> None:
        self.instructor_repo = InstructorRepository(db)
        self.cliente_repo = ClienteRepository(db)

    def registro(self, data: RegistroRequest) -> UsuarioResponse:
        _validar_fortaleza_password(data.password)

        if self.instructor_repo.get_by_email(data.email) or self.cliente_repo.get_by_email(data.email):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="El email ya está registrado",
            )

        password_hash = hash_password(data.password)

        if data.rol == "instructor":
            instructor = Instructor(
                nombre=data.nombre,
                especialidad=data.especialidad or "",
                email=data.email,
                password_hash=password_hash,
                rol="instructor",
            )
            created = self.instructor_repo.create(instructor)
            return UsuarioResponse(id=created.id, nombre=created.nombre, email=created.email, rol=created.rol)

        instructor = self.instructor_repo.get_by_id(data.instructor_id)
        if instructor is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Instructor no encontrado",
            )

        cliente = Cliente(
            instructor_id=data.instructor_id,
            nombre=data.nombre,
            objetivo=data.objetivo or "",
            email=data.email,
            password_hash=password_hash,
            rol="cliente",
        )
        created = self.cliente_repo.create(cliente)
        return UsuarioResponse(id=created.id, nombre=created.nombre, email=created.email, rol=created.rol)

    def login(self, data: LoginRequest) -> TokenResponse:
        if rate_limiter.excede_limite(data.email):
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Demasiados intentos, intenta de nuevo en unos minutos",
            )

        instructor = self.instructor_repo.get_by_email(data.email)
        if instructor and verify_password(data.password, instructor.password_hash):
            rate_limiter.limpiar_intentos(data.email)
            token = create_access_token(instructor.id, instructor.rol)
            usuario = UsuarioResponse(
                id=instructor.id,
                nombre=instructor.nombre,
                rol=instructor.rol,
            )
            return TokenResponse(access_token=token, usuario=usuario)

        cliente = self.cliente_repo.get_by_email(data.email)
        if cliente and verify_password(data.password, cliente.password_hash):
            rate_limiter.limpiar_intentos(data.email)
            token = create_access_token(cliente.id, cliente.rol)
            usuario = UsuarioResponse(
                id=cliente.id,
                nombre=cliente.nombre,
                rol=cliente.rol,
            )
            return TokenResponse(access_token=token, usuario=usuario)

        rate_limiter.registrar_intento_fallido(data.email)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email o contraseña incorrectos",
        )
