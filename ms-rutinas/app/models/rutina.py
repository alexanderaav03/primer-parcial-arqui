from datetime import date

from sqlalchemy import Date, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Rutina(Base):
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


from app.models.detalle_rutina import DetalleRutina  # noqa: E402
