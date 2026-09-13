from sqlalchemy import Float, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class DetalleRutina(Base):
    __tablename__ = "detalles_rutina"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    rutina_id: Mapped[int] = mapped_column(ForeignKey("rutinas.id"), nullable=False, index=True)
    ejercicio_id: Mapped[int] = mapped_column(Integer, nullable=False, index=True)
    repeticiones: Mapped[int] = mapped_column(Integer, nullable=False)
    series: Mapped[int] = mapped_column(Integer, nullable=False)
    peso: Mapped[float] = mapped_column(Float, nullable=False)
    descanso_serie: Mapped[str] = mapped_column(String(50), nullable=False)
    descanso_ejercicio: Mapped[str] = mapped_column(String(50), nullable=False)
    rpe: Mapped[int] = mapped_column(Integer, nullable=False)

    rutina: Mapped["Rutina"] = relationship(back_populates="detalles")


from app.models.rutina import Rutina  # noqa: E402
