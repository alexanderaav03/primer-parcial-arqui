import logging
from pathlib import Path

from fastapi import FastAPI, HTTPException, Request, status
from fastapi.middleware.cors import CORSMiddleware
from starlette.responses import JSONResponse

from app.middlewares.auth_middleware import AuthMiddleware
from app.middlewares.logging_middleware import LoggingMiddleware
from app.routers import auth, ejercicios, rutinas

LOG_DIR = Path(__file__).resolve().parent.parent / "logs"
LOG_DIR.mkdir(parents=True, exist_ok=True)

_LOG_FORMAT = "[%(asctime)s] %(levelname)s %(name)s: %(message)s"
_LOG_DATEFMT = "%Y-%m-%d %H:%M:%S"

logging.basicConfig(
    level=logging.INFO,
    format=_LOG_FORMAT,
    datefmt=_LOG_DATEFMT,
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler(LOG_DIR / "gateway.log", encoding="utf-8"),
    ],
)
# httpx loguea cada llamada saliente por su cuenta (nivel INFO); ya lo
# logueamos nosotros mismos en ProxyService con mas contexto, así que se
# silencia para no duplicar cada línea.
logging.getLogger("httpx").setLevel(logging.WARNING)

logger = logging.getLogger("gateway")

app = FastAPI(
    title="API Gateway - Banco de Ejercicios",
    description="Puerta de entrada única al sistema de microservicios",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(AuthMiddleware)
# Se agrega despues de AuthMiddleware para que quede como la mas externa y
# mida el tiempo total (auth + reenvio), no solo el reenvio.
app.add_middleware(LoggingMiddleware)

API_PREFIX = "/api"

app.include_router(auth.router, prefix=API_PREFIX)
app.include_router(ejercicios.router, prefix=API_PREFIX)
app.include_router(rutinas.router, prefix=API_PREFIX)


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
    """Los 503 (microservicio caído/timeout, ver ProxyService._request) se
    devuelven como {"error": ...} -mensaje claro para el cliente final-. El
    resto de los HTTPException (401 de auth, 4xx reenviados tal cual desde
    los microservicios, etc.) mantienen el shape {"detail": ...} de FastAPI,
    para no romper nada que ya dependa de ese formato.
    """
    if exc.status_code == status.HTTP_503_SERVICE_UNAVAILABLE:
        logger.error("%s %s -> 503: %s", request.method, request.url.path, exc.detail)
        return JSONResponse(status_code=exc.status_code, content={"error": exc.detail}, headers=exc.headers)

    return JSONResponse(status_code=exc.status_code, content={"detail": exc.detail}, headers=exc.headers)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
