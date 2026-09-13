from sqlalchemy import Float, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Cliente(Base):
    __tablename__ = "clientes"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    instructor_id: Mapped[int] = mapped_column(ForeignKey("instructores.id"), nullable=False, index=True)
    nombre: Mapped[str] = mapped_column(String(255), nullable=False)
    objetivo: Mapped[str] = mapped_column(String(500), nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    rol: Mapped[str] = mapped_column(String(50), nullable=False, default="cliente")
    peso: Mapped[float | None] = mapped_column(Float, nullable=True)
    altura: Mapped[float | None] = mapped_column(Float, nullable=True)

    instructor: Mapped["Instructor"] = relationship(back_populates="clientes")


from app.models.instructor import Instructor  # noqa: E402
