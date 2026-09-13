from jose import JWTError, jwt

from app.config import settings

ALGORITHM = "HS256"


class InvalidTokenError(Exception):
    pass


def validate_token(token: str) -> dict:
    try:
        return jwt.decode(token, settings.JWT_SECRET, algorithms=[ALGORITHM])
    except JWTError as exc:
        raise InvalidTokenError("Token inválido o expirado") from exc
