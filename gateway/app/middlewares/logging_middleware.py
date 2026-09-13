import logging
import time

from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.requests import Request
from starlette.responses import Response

logger = logging.getLogger("gateway")


class LoggingMiddleware(BaseHTTPMiddleware):
    """Loguea cada request entrante al gateway con su código de respuesta y
    duración total (incluye auth + el o los reenvíos a microservicios). El
    detalle de a qué microservicio se reenvió cada llamada y cuánto tardó
    esa llamada puntual se loguea aparte, en ProxyService._request.
    """

    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint) -> Response:
        inicio = time.perf_counter()
        try:
            response = await call_next(request)
        except Exception:
            duracion_ms = int((time.perf_counter() - inicio) * 1000)
            logger.exception("%s %s -> 500 (%sms)", request.method, request.url.path, duracion_ms)
            raise

        duracion_ms = int((time.perf_counter() - inicio) * 1000)
        logger.info("%s %s -> %s (%sms)", request.method, request.url.path, response.status_code, duracion_ms)
        return response
