from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.requests import Request
from starlette.responses import JSONResponse, Response

from app.security import InvalidTokenError, validate_token

PUBLIC_PATHS = {
    "/health",
    "/api/auth/registro",
    "/api/auth/login",
    "/docs",
    "/redoc",
    "/openapi.json",
}


class AuthMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint) -> Response:
        path = request.url.path.rstrip("/") or "/"
        if path in PUBLIC_PATHS or request.method == "OPTIONS":
            return await call_next(request)

        auth_header = request.headers.get("Authorization")
        if not auth_header or not auth_header.lower().startswith("bearer "):
            return JSONResponse(
                status_code=401,
                content={"detail": "Credenciales de autenticación no provistas"},
                headers={"WWW-Authenticate": "Bearer"},
            )

        token = auth_header.split(" ", 1)[1].strip()
        try:
            validate_token(token)
        except InvalidTokenError:
            return JSONResponse(
                status_code=401,
                content={"detail": "Token inválido o expirado"},
                headers={"WWW-Authenticate": "Bearer"},
            )

        return await call_next(request)
