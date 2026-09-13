from app.schemas.auth import LoginRequest, RegistroRequest, TokenResponse, UsuarioResponse
from app.schemas.cliente import ClienteCreate, ClienteResponse
from app.schemas.ejercicio import EjercicioCreate, EjercicioResponse

__all__ = [
    "RegistroRequest",
    "LoginRequest",
    "TokenResponse",
    "UsuarioResponse",
    "ClienteCreate",
    "ClienteResponse",
    "EjercicioCreate",
    "EjercicioResponse",
]
