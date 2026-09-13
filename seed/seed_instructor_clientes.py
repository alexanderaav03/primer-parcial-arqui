"""
Seed de datos para la base "ejercicios" (ms-ejercicios): instructor + clientes.

Crea (si no existe) el instructor de prueba Carlos Mendez -igual que
seed_ejercicios.py, para poder correr este script de forma independiente-
y 3 clientes de prueba asociados a el.

Requiere las mismas dependencias que ms-ejercicios (sqlalchemy,
psycopg2-binary, passlib[bcrypt], python-dotenv -> ya estan en su venv).

Uso:
    python seed/seed_instructor_clientes.py             # contra ms-ejercicios/.env (localhost:5432)
    python seed/seed_instructor_clientes.py --docker     # contra ms-ejercicios/.env.docker (contenedores, localhost:5433)
    (con el venv de ms-ejercicios activado, o llamando directo a su python:
     ms-ejercicios\\venv\\Scripts\\python.exe seed\\seed_instructor_clientes.py)

Idempotente: si un instructor/cliente con el mismo email ya existe, no
se duplica.
"""

import os
import sys
from pathlib import Path

from dotenv import load_dotenv
from passlib.context import CryptContext
from sqlalchemy import ForeignKey, String, create_engine
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

    clientes: Mapped[list["Cliente"]] = relationship(back_populates="instructor")


class Cliente(Base):
    __tablename__ = "clientes"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    instructor_id: Mapped[int] = mapped_column(ForeignKey("instructores.id"), nullable=False, index=True)
    nombre: Mapped[str] = mapped_column(String(255), nullable=False)
    objetivo: Mapped[str] = mapped_column(String(500), nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    rol: Mapped[str] = mapped_column(String(50), nullable=False, default="cliente")

    instructor: Mapped["Instructor"] = relationship(back_populates="clientes")


INSTRUCTOR = {
    "nombre": "Carlos Mendez",
    "email": "carlos@gym.com",
    "password": "test1234",
    "especialidad": "Fuerza y acondicionamiento",
}

CLIENTES = [
    {"nombre": "Ana Rojas", "objetivo": "Perder grasa", "email": "ana@test.com", "password": "test1234"},
    {"nombre": "Luis Paz", "objetivo": "Ganar masa muscular", "email": "luis@test.com", "password": "test1234"},
    {"nombre": "Marta Vega", "objetivo": "Tonificar", "email": "marta@test.com", "password": "test1234"},
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


def get_or_create_cliente(db: Session, instructor: Instructor, nombre: str, objetivo: str, email: str, password: str) -> Cliente:
    existente = db.query(Cliente).filter(Cliente.email == email).first()
    if existente:
        print(f"[=] Cliente ya existia: id={existente.id} email={existente.email}")
        return existente

    cliente = Cliente(
        instructor_id=instructor.id,
        nombre=nombre,
        objetivo=objetivo,
        email=email,
        password_hash=pwd_context.hash(password),
        rol="cliente",
    )
    db.add(cliente)
    db.flush()
    print(f"[+] Cliente creado: id={cliente.id} nombre={cliente.nombre} email={cliente.email}")
    return cliente


def main() -> None:
    engine = create_engine(DATABASE_URL)
    Base.metadata.create_all(bind=engine)
    SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)

    db = SessionLocal()
    try:
        print(f"== Seed instructor + clientes (usando {ENV_PATH.name}: {DATABASE_URL}) ==")
        instructor = get_or_create_instructor(db)

        for c in CLIENTES:
            get_or_create_cliente(db, instructor, c["nombre"], c["objetivo"], c["email"], c["password"])

        db.commit()
        print("== Listo ==")
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    main()
