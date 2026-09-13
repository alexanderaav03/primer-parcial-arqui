from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Instructor(Base):
    __tablename__ = "instructores"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    nombre: Mapped[str] = mapped_column(String(255), nullable=False)
    especialidad: Mapped[str] = mapped_column(String(255), nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    rol: Mapped[str] = mapped_column(String(50), nullable=False, default="instructor")

    clientes: Mapped[list["Cliente"]] = relationship(back_populates="instructor")
    ejercicios: Mapped[list["Ejercicio"]] = relationship(back_populates="instructor")


from app.models.cliente import Cliente  # noqa: E402
from app.models.ejercicio import Ejercicio  # noqa: E402
