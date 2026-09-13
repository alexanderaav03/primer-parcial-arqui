from sqlalchemy import Boolean, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Ejercicio(Base):
    __tablename__ = "ejercicios"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    instructor_id: Mapped[int] = mapped_column(ForeignKey("instructores.id"), nullable=False, index=True)
    nombre: Mapped[str] = mapped_column(String(255), nullable=False)
    descripcion: Mapped[str] = mapped_column(Text, nullable=False)
    imagen_url: Mapped[str | None] = mapped_column(String(1024), nullable=True)
    video_url: Mapped[str | None] = mapped_column(String(1024), nullable=True)
    tiene_ejemplo_completo: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)

    # Valores de referencia sugeridos del banco (independientes de cualquier
    # rutina). Todos nullable: los ejercicios sin ejemplo completo no los tienen.
    repeticiones_sugeridas: Mapped[int | None] = mapped_column(Integer, nullable=True)
    series_sugeridas: Mapped[int | None] = mapped_column(Integer, nullable=True)
    peso_sugerido: Mapped[float | None] = mapped_column(Float, nullable=True)
    descanso_serie_sugerido: Mapped[str | None] = mapped_column(String(50), nullable=True)
    descanso_ejercicio_sugerido: Mapped[str | None] = mapped_column(String(50), nullable=True)
    rpe_sugerido: Mapped[int | None] = mapped_column(Integer, nullable=True)

    instructor: Mapped["Instructor"] = relationship(back_populates="ejercicios")


from app.models.instructor import Instructor  # noqa: E402
