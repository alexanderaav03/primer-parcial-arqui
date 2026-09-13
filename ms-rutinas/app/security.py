from jose import JWTError, jwt

from app.config import settings

ALGORITHM = "HS256"


def decode_access_token(token: str) -> dict:
    return jwt.decode(token, settings.JWT_SECRET, algorithms=[ALGORITHM])


class InvalidTokenError(Exception):
    pass


def get_token_payload(token: str) -> dict:
    try:
        return decode_access_token(token)
    except JWTError as exc:
        raise InvalidTokenError("Token inválido o expirado") from exc
