from dataclasses import dataclass
from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.security import InvalidTokenError, get_token_payload

security_scheme = HTTPBearer(auto_error=False)


@dataclass
class CurrentUser:
    id: int
    rol: str


def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(security_scheme)],
) -> CurrentUser:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Credenciales de autenticación no provistas",
            headers={"WWW-Authenticate": "Bearer"},
        )
    try:
        payload = get_token_payload(credentials.credentials)
    except InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido o expirado",
            headers={"WWW-Authenticate": "Bearer"},
        ) from None

    user_id = payload.get("id")
    rol = payload.get("rol")
    if user_id is None or rol is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return CurrentUser(id=int(user_id), rol=str(rol))


def get_bearer_token(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(security_scheme)],
) -> str:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Credenciales de autenticación no provistas",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return credentials.credentials


def require_instructor(current_user: Annotated[CurrentUser, Depends(get_current_user)]) -> CurrentUser:
    if current_user.rol != "instructor":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Se requiere rol instructor",
        )
    return current_user
