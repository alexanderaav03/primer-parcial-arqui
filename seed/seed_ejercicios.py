"""
Seed de datos para la base "ejercicios" (ms-ejercicios).

Crea 1 instructor de prueba y 15 ejercicios (10 con media completa +
valores de referencia sugeridos, 5 sin media ni valores sugeridos,
solo para llenar el banco).

Requiere las mismas dependencias que ms-ejercicios (sqlalchemy,
psycopg2-binary, passlib[bcrypt], python-dotenv -> ya estan en su venv).

Uso:
    python seed/seed_ejercicios.py             # contra ms-ejercicios/.env (localhost:5432)
    python seed/seed_ejercicios.py --docker     # contra ms-ejercicios/.env.docker (contenedores, localhost:5433)
    (con el venv de ms-ejercicios activado, o llamando directo a su python:
     ms-ejercicios\\venv\\Scripts\\python.exe seed\\seed_ejercicios.py)

Idempotente: si un instructor/ejercicio con el mismo email/nombre ya
existe, no se duplica.
"""

import os
import sys
from pathlib import Path

from dotenv import load_dotenv
from passlib.context import CryptContext
from sqlalchemy import (
    Boolean,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    create_engine,
)
from sqlalchemy.orm import DeclarativeBase, Mapped, Session, mapped_column, relationship, sessionmaker

ROOT_DIR = Path(__file__).resolve().parent.parent
ENV_FILENAME = ".env.docker" if "--docker" in sys.argv else ".env"
ENV_PATH = ROOT_DIR / "ms-ejercicios" / ENV_FILENAME
load_dotenv(ENV_PATH)

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise RuntimeError(f"No se encontro DATABASE_URL en {ENV_PATH}")

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class Base(DeclarativeBase):
    pass


class Instructor(Base):
    __tablename__ = "instructores"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    nombre: Mapped[str] = mapped_column(String(255), nullable=False)
    especialidad: Mapped[str] = mapped_column(String(255), nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    rol: Mapped[str] = mapped_column(String(50), nullable=False, default="instructor")

    ejercicios: Mapped[list["Ejercicio"]] = relationship(back_populates="instructor")


class Ejercicio(Base):
    __tablename__ = "ejercicios"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    instructor_id: Mapped[int] = mapped_column(ForeignKey("instructores.id"), nullable=False, index=True)
    nombre: Mapped[str] = mapped_column(String(255), nullable=False)
    descripcion: Mapped[str] = mapped_column(Text, nullable=False)
    imagen_url: Mapped[str | None] = mapped_column(String(1024), nullable=True)
    video_url: Mapped[str | None] = mapped_column(String(1024), nullable=True)
    tiene_ejemplo_completo: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)

    repeticiones_sugeridas: Mapped[int | None] = mapped_column(Integer, nullable=True)
    series_sugeridas: Mapped[int | None] = mapped_column(Integer, nullable=True)
    peso_sugerido: Mapped[float | None] = mapped_column(Float, nullable=True)
    descanso_serie_sugerido: Mapped[str | None] = mapped_column(String(50), nullable=True)
    descanso_ejercicio_sugerido: Mapped[str | None] = mapped_column(String(50), nullable=True)
    rpe_sugerido: Mapped[int | None] = mapped_column(Integer, nullable=True)

    instructor: Mapped["Instructor"] = relationship(back_populates="ejercicios")


INSTRUCTOR = {
    "nombre": "Carlos Mendez",
    "email": "carlos@gym.com",
    "password": "test1234",
    "especialidad": "Fuerza y acondicionamiento",
}

# Cada uno con su slug de placeholder, descripcion, y valores de referencia
# sugeridos (varian un poco por ejercicio - los compuestos pesados llevan
# menos repeticiones, mas peso y mas descanso que los de aislamiento).
EJERCICIOS_CON_MEDIA = [
    {
        "nombre": "Sentadilla",
        "slug": "Sentadilla",
        "descripcion": "Ejercicio compuesto de tren inferior que trabaja cuadriceps, gluteos e isquiotibiales.",
        "repeticiones_sugeridas": 10,
        "series_sugeridas": 4,
        "peso_sugerido": 40.0,
        "descanso_serie_sugerido": "1 min",
        "descanso_ejercicio_sugerido": "2 min",
        "rpe_sugerido": 7,
    },
    {
        "nombre": "Extension de Cuadriceps",
        "slug": "ExtensionCuadriceps",
        "descripcion": "Ejercicio de aislamiento para cuadriceps realizado en maquina.",
        "repeticiones_sugeridas": 12,
        "series_sugeridas": 3,
        "peso_sugerido": 20.0,
        "descanso_serie_sugerido": "45 seg",
        "descanso_ejercicio_sugerido": "1 min",
        "rpe_sugerido": 6,
    },
    {
        "nombre": "Gemelos en Maquina",
        "slug": "GemelosMaquina",
        "descripcion": "Ejercicio de aislamiento para gemelos (pantorrillas) en maquina.",
        "repeticiones_sugeridas": 15,
        "series_sugeridas": 3,
        "peso_sugerido": 30.0,
        "descanso_serie_sugerido": "45 seg",
        "descanso_ejercicio_sugerido": "1 min",
        "rpe_sugerido": 6,
    },
    {
        "nombre": "Remo de espalda en maquina",
        "slug": "RemoEspalda",
        "descripcion": "Ejercicio de traccion horizontal para dorsales y espalda media en maquina.",
        "repeticiones_sugeridas": 12,
        "series_sugeridas": 3,
        "peso_sugerido": 35.0,
        "descanso_serie_sugerido": "1 min",
        "descanso_ejercicio_sugerido": "2 min",
        "rpe_sugerido": 7,
    },
    {
        "nombre": "Press de banca",
        "slug": "PressBanca",
        "descripcion": "Ejercicio compuesto de empuje horizontal para pecho, hombros y triceps.",
        "repeticiones_sugeridas": 8,
        "series_sugeridas": 4,
        "peso_sugerido": 45.0,
        "descanso_serie_sugerido": "2 min",
        "descanso_ejercicio_sugerido": "3 min",
        "rpe_sugerido": 8,
    },
    {
        "nombre": "Jalon al pecho",
        "slug": "JalonPecho",
        "descripcion": "Ejercicio de traccion vertical en polea alta para dorsales y biceps.",
        "repeticiones_sugeridas": 12,
        "series_sugeridas": 3,
        "peso_sugerido": 35.0,
        "descanso_serie_sugerido": "1 min",
        "descanso_ejercicio_sugerido": "2 min",
        "rpe_sugerido": 6,
    },
    {
        "nombre": "Curl de biceps con barra",
        "slug": "CurlBiceps",
        "descripcion": "Ejercicio de aislamiento para biceps realizado con barra recta u olimpica.",
        "repeticiones_sugeridas": 12,
        "series_sugeridas": 3,
        "peso_sugerido": 15.0,
        "descanso_serie_sugerido": "45 seg",
        "descanso_ejercicio_sugerido": "1 min",
        "rpe_sugerido": 6,
    },
    {
        "nombre": "Press militar",
        "slug": "PressMilitar",
        "descripcion": "Ejercicio compuesto de empuje vertical para hombros y triceps.",
        "repeticiones_sugeridas": 10,
        "series_sugeridas": 3,
        "peso_sugerido": 20.0,
        "descanso_serie_sugerido": "1 min",
        "descanso_ejercicio_sugerido": "2 min",
        "rpe_sugerido": 7,
    },
    {
        "nombre": "Peso muerto",
        "slug": "PesoMuerto",
        "descripcion": "Ejercicio compuesto de cadena posterior para espalda baja, gluteos e isquiotibiales.",
        "repeticiones_sugeridas": 6,
        "series_sugeridas": 4,
        "peso_sugerido": 60.0,
        "descanso_serie_sugerido": "2 min",
        "descanso_ejercicio_sugerido": "3 min",
        "rpe_sugerido": 8,
    },
    {
        "nombre": "Extension de triceps en polea",
        "slug": "ExtensionTriceps",
        "descripcion": "Ejercicio de aislamiento para triceps realizado en polea alta.",
        "repeticiones_sugeridas": 12,
        "series_sugeridas": 3,
        "peso_sugerido": 15.0,
        "descanso_serie_sugerido": "45 seg",
        "descanso_ejercicio_sugerido": "1 min",
        "rpe_sugerido": 6,
    },
]

EJERCICIOS_SIN_MEDIA = [
    ("Zancadas", "Ejercicio unilateral de tren inferior para cuadriceps y gluteos."),
    ("Plancha abdominal", "Ejercicio isometrico de core para abdomen y estabilidad de tronco."),
    ("Remo con mancuerna", "Ejercicio de traccion horizontal unilateral para espalda con mancuerna."),
    ("Elevaciones laterales", "Ejercicio de aislamiento para deltoides lateral con mancuernas."),
    ("Hip thrust", "Ejercicio compuesto para gluteos realizado con barra apoyada en cadera."),
]


def get_or_create_instructor(db: Session) -> Instructor:
    existente = db.query(Instructor).filter(Instructor.email == INSTRUCTOR["email"]).first()
    if existente:
        print(f"[=] Instructor ya existia: id={existente.id} email={existente.email}")
        return existente

    instructor = Instructor(
        nombre=INSTRUCTOR["nombre"],
        especialidad=INSTRUCTOR["especialidad"],
        email=INSTRUCTOR["email"],
        password_hash=pwd_context.hash(INSTRUCTOR["password"]),
        rol="instructor",
    )
    db.add(instructor)
    db.flush()
    print(f"[+] Instructor creado: id={instructor.id} email={instructor.email}")
    return instructor


def get_or_create_ejercicio(
    db: Session,
    instructor: Instructor,
    nombre: str,
    descripcion: str,
    imagen_url: str | None,
    video_url: str | None,
    tiene_ejemplo_completo: bool,
    repeticiones_sugeridas: int | None = None,
    series_sugeridas: int | None = None,
    peso_sugerido: float | None = None,
    descanso_serie_sugerido: str | None = None,
    descanso_ejercicio_sugerido: str | None = None,
    rpe_sugerido: int | None = None,
) -> Ejercicio:
    existente = (
        db.query(Ejercicio)
        .filter(Ejercicio.instructor_id == instructor.id, Ejercicio.nombre == nombre)
        .first()
    )
    if existente:
        print(f"[=] Ejercicio ya existia: id={existente.id} nombre={existente.nombre}")
        return existente

    ejercicio = Ejercicio(
        instructor_id=instructor.id,
        nombre=nombre,
        descripcion=descripcion,
        imagen_url=imagen_url,
        video_url=video_url,
        tiene_ejemplo_completo=tiene_ejemplo_completo,
        repeticiones_sugeridas=repeticiones_sugeridas,
        series_sugeridas=series_sugeridas,
        peso_sugerido=peso_sugerido,
        descanso_serie_sugerido=descanso_serie_sugerido,
        descanso_ejercicio_sugerido=descanso_ejercicio_sugerido,
        rpe_sugerido=rpe_sugerido,
    )
    db.add(ejercicio)
    db.flush()
    print(f"[+] Ejercicio creado: id={ejercicio.id} nombre={ejercicio.nombre} con_media={tiene_ejemplo_completo}")
    return ejercicio


def main() -> None:
    engine = create_engine(DATABASE_URL)
    Base.metadata.create_all(bind=engine)
    SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)

    db = SessionLocal()
    try:
        print(f"== Seed ejercicios (usando {ENV_PATH.name}: {DATABASE_URL}) ==")
        instructor = get_or_create_instructor(db)

        for idx, datos in enumerate(EJERCICIOS_CON_MEDIA, start=1):
            get_or_create_ejercicio(
                db,
                instructor,
                nombre=datos["nombre"],
                descripcion=datos["descripcion"],
                imagen_url=f"https://placehold.co/600x400?text={datos['slug']}",
                video_url=f"https://youtube.com/watch?v=demo{idx}",
                tiene_ejemplo_completo=True,
                repeticiones_sugeridas=datos["repeticiones_sugeridas"],
                series_sugeridas=datos["series_sugeridas"],
                peso_sugerido=datos["peso_sugerido"],
                descanso_serie_sugerido=datos["descanso_serie_sugerido"],
                descanso_ejercicio_sugerido=datos["descanso_ejercicio_sugerido"],
                rpe_sugerido=datos["rpe_sugerido"],
            )

        for nombre, descripcion in EJERCICIOS_SIN_MEDIA:
            get_or_create_ejercicio(
                db,
                instructor,
                nombre=nombre,
                descripcion=descripcion,
                imagen_url=None,
                video_url=None,
                tiene_ejemplo_completo=False,
                # sin valores sugeridos: quedan en null (default de la funcion)
            )

        db.commit()
        print("== Listo ==")
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    main()
