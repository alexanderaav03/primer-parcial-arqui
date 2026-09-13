import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import Base, engine
from app.middlewares.logging_middleware import LoggingMiddleware
from app.models import DetalleRutina, RegistroProgreso, Rutina  # noqa: F401
from app.routers import detalles, progreso, rutinas

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
# httpx loguea por su cuenta cada llamada saliente a ms-ejercicios (para
# validar ejercicios/clientes); se silencia para no duplicar el ruido -las
# llamadas de este servicio ya quedan cubiertas por el log de cada request.
logging.getLogger("httpx").setLevel(logging.WARNING)


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(
    title="ms-rutinas",
    description="Microservicio de rutinas y detalles de rutina",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(LoggingMiddleware)

API_PREFIX = "/api"

app.include_router(rutinas.router, prefix=API_PREFIX)
app.include_router(detalles.router, prefix=API_PREFIX)
app.include_router(progreso.router, prefix=API_PREFIX)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
