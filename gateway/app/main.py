import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.middlewares.auth_middleware import AuthMiddleware
from app.middlewares.logging_middleware import LoggingMiddleware
from app.routers import auth, ejercicios, rutinas

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
# httpx loguea cada llamada saliente por su cuenta (nivel INFO); ya lo
# logueamos nosotros mismos en ProxyService con mas contexto, así que se
# silencia para no duplicar cada línea.
logging.getLogger("httpx").setLevel(logging.WARNING)

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


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
