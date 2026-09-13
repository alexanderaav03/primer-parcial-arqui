"""
Seed de datos para la base "rutinas" (ms-rutinas).

Crea 2 rutinas de ejemplo con sus detalles, referenciando clientes y
ejercicios que ya deben existir en la base "ejercicios" (correr antes
seed_ejercicios.py y seed_instructor_clientes.py).

cliente_id y ejercicio_id se resuelven por nombre/email contra la base
"ejercicios" (DATABASE_URL de ms-ejercicios/.env) y luego se insertan
en la base "rutinas" (DATABASE_URL de ms-rutinas/.env) -son bases
distintas, sin foreign key entre ellas, como corresponde en una
arquitectura de microservicios-.

Requiere las mismas dependencias que ms-rutinas (sqlalchemy,
psycopg2-binary, python-dotenv -> ya estan en su venv; tambien
funciona con el venv de ms-ejercicios, que trae lo mismo).

Uso:
    python seed/seed_rutinas.py             # contra .env de ambos servicios (localhost:5432)
    python seed/seed_rutinas.py --docker     # contra .env.docker de ambos servicios (contenedores, 5433/5434)

Idempotente: si ya existe una rutina con el mismo cliente_id + nombre,
no se duplica (ni sus detalles).
"""

import sys
from datetime import date
from pathlib import Path

from dotenv import dotenv_values
from sqlalchemy import Date, Float, ForeignKey, Integer, String, create_engine
from sqlalchemy.orm import DeclarativeBase, Mapped, Session, mapped_column, relationship, sessionmaker

ROOT_DIR = Path(__file__).resolve().parent.parent
ENV_FILENAME = ".env.docker" if "--docker" in sys.argv else ".env"

EJERCICIOS_ENV_PATH = ROOT_DIR / "ms-ejercicios" / ENV_FILENAME
RUTINAS_ENV_PATH = ROOT_DIR / "ms-rutinas" / ENV_FILENAME


def _read_database_url(env_path: Path) -> str:
    url = dotenv_values(env_path).get("DATABASE_URL")
    if not url:
        raise RuntimeError(f"No se encontro DATABASE_URL en {env_path}")
    return url


EJERCICIOS_DATABASE_URL = _read_database_url(EJERCICIOS_ENV_PATH)
RUTINAS_DATABASE_URL = _read_database_url(RUTINAS_ENV_PATH)


# --- Modelos de solo lectura contra la base "ejercicios" ---

class EjerciciosBase(DeclarativeBase):
    pass


class Cliente(EjerciciosBase):
    __tablename__ = "clientes"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    instructor_id: Mapped[int] = mapped_column(Integer, nullable=False)
    nombre: Mapped[str] = mapped_column(String(255), nullable=False)
    objetivo: Mapped[str] = mapped_column(String(500), nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    rol: Mapped[str] = mapped_column(String(50), nullable=False, default="cliente")


class Ejercicio(EjerciciosBase):
    __tablename__ = "ejercicios"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    instructor_id: Mapped[int] = mapped_column(Integer, nullable=False)
    nombre: Mapped[str] = mapped_column(String(255), nullable=False)


# --- Modelos de escritura contra la base "rutinas" ---

class RutinasBase(DeclarativeBase):
    pass


class Rutina(RutinasBase):
    __tablename__ = "rutinas"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    cliente_id: Mapped[int] = mapped_column(Integer, nullable=False, index=True)
    nombre: Mapped[str] = mapped_column(String(255), nullable=False)
    fecha_inicio: Mapped[date] = mapped_column(Date, nullable=False)
    fecha_fin: Mapped[date] = mapped_column(Date, nullable=False)

    detalles: Mapped[list["DetalleRutina"]] = relationship(
        back_populates="rutina",
        cascade="all, delete-orphan",
    )


class DetalleRutina(RutinasBase):
    __tablename__ = "detalles_rutina"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    rutina_id: Mapped[int] = mapped_column(ForeignKey("rutinas.id"), nullable=False, index=True)
    ejercicio_id: Mapped[int] = mapped_column(Integer, nullable=False, index=True)
    repeticiones: Mapped[int] = mapped_column(Integer, nullable=False)
    series: Mapped[int] = mapped_column(Integer, nullable=False)
    sesiones_por_semana: Mapped[int] = mapped_column(Integer, nullable=False)
    peso: Mapped[float] = mapped_column(Float, nullable=False)
    descanso_serie: Mapped[str] = mapped_column(String(50), nullable=False)
    descanso_ejercicio: Mapped[str] = mapped_column(String(50), nullable=False)
    rpe: Mapped[int] = mapped_column(Integer, nullable=False)

    rutina: Mapped["Rutina"] = relationship(back_populates="detalles")


DETALLE_DEFAULT = {
    "repeticiones": 12,
    "series": 3,
    "sesiones_por_semana": 3,
    "peso": 20,
    "descanso_serie": "1 min",
    "descanso_ejercicio": "2 min",
    "rpe": 6,
}

RUTINAS_A_CREAR = [
    {
        "cliente_email": "ana@test.com",
        "nombre": "Rutina Semana 1",
        "fecha_inicio": date(2026, 9, 8),
        "fecha_fin": date(2026, 9, 13),
        "ejercicios_nombres": ["Sentadilla", "Extension de Cuadriceps", "Gemelos en Maquina"],
    },
    {
        "cliente_email": "luis@test.com",
        "nombre": "Rutina Semana 1",
        "fecha_inicio": date(2026, 9, 8),
        "fecha_fin": date(2026, 9, 13),
        "ejercicios_nombres": ["Remo de espalda en maquina", "Press de banca"],
    },
]


def resolver_cliente_id(db_ejercicios: Session, email: str) -> int:
    cliente = db_ejercicios.query(Cliente).filter(Cliente.email == email).first()
    if cliente is None:
        raise RuntimeError(
            f"No se encontro el cliente con email={email} en la base 'ejercicios'. "
            "Corre primero seed/seed_instructor_clientes.py"
        )
    return cliente.id


def resolver_ejercicio_id(db_ejercicios: Session, nombre: str) -> int:
    ejercicio = db_ejercicios.query(Ejercicio).filter(Ejercicio.nombre == nombre).first()
    if ejercicio is None:
        raise RuntimeError(
            f"No se encontro el ejercicio '{nombre}' en la base 'ejercicios'. "
            "Corre primero seed/seed_ejercicios.py"
        )
    return ejercicio.id


def get_or_create_rutina(db_rutinas: Session, cliente_id: int, nombre: str, fecha_inicio: date, fecha_fin: date, ejercicio_ids: list[int]) -> Rutina:
    existente = (
        db_rutinas.query(Rutina)
        .filter(Rutina.cliente_id == cliente_id, Rutina.nombre == nombre)
        .first()
    )
    if existente:
        print(f"[=] Rutina ya existia: id={existente.id} cliente_id={cliente_id} nombre={existente.nombre}")
        return existente

    rutina = Rutina(cliente_id=cliente_id, nombre=nombre, fecha_inicio=fecha_inicio, fecha_fin=fecha_fin)
    for ejercicio_id in ejercicio_ids:
        rutina.detalles.append(DetalleRutina(ejercicio_id=ejercicio_id, **DETALLE_DEFAULT))

    db_rutinas.add(rutina)
    db_rutinas.flush()
    print(f"[+] Rutina creada: id={rutina.id} cliente_id={cliente_id} nombre={rutina.nombre}")
    for detalle in rutina.detalles:
        print(f"    - Detalle creado: id={detalle.id} ejercicio_id={detalle.ejercicio_id}")
    return rutina


def main() -> None:
    engine_ejercicios = create_engine(EJERCICIOS_DATABASE_URL)
    engine_rutinas = create_engine(RUTINAS_DATABASE_URL)
    RutinasBase.metadata.create_all(bind=engine_rutinas)

    SessionEjercicios = sessionmaker(bind=engine_ejercicios, autoflush=False, autocommit=False)
    SessionRutinas = sessionmaker(bind=engine_rutinas, autoflush=False, autocommit=False)

    db_ejercicios = SessionEjercicios()
    db_rutinas = SessionRutinas()
    try:
        print(f"== Seed rutinas (usando {ENV_FILENAME}: ejercicios={EJERCICIOS_DATABASE_URL} | rutinas={RUTINAS_DATABASE_URL}) ==")

        for spec in RUTINAS_A_CREAR:
            cliente_id = resolver_cliente_id(db_ejercicios, spec["cliente_email"])
            ejercicio_ids = [resolver_ejercicio_id(db_ejercicios, n) for n in spec["ejercicios_nombres"]]

            get_or_create_rutina(
                db_rutinas,
                cliente_id=cliente_id,
                nombre=spec["nombre"],
                fecha_inicio=spec["fecha_inicio"],
                fecha_fin=spec["fecha_fin"],
                ejercicio_ids=ejercicio_ids,
            )

        db_rutinas.commit()
        print("== Listo ==")
    except Exception:
        db_rutinas.rollback()
        raise
    finally:
        db_ejercicios.close()
        db_rutinas.close()


if __name__ == "__main__":
    main()
