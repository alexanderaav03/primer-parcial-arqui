from datetime import datetime

from sqlalchemy import DateTime, Float, ForeignKey, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class RegistroProgreso(Base):
    __tablename__ = "registros_progreso"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    # ondelete="CASCADE": si se borra el detalle (DELETE /detalles/{id}), sus
    # registros de progreso se van con él -no tiene sentido dejarlos huérfanos-.
    detalle_rutina_id: Mapped[int] = mapped_column(
        ForeignKey("detalles_rutina.id", ondelete="CASCADE"), nullable=False, index=True
    )
    fecha: Mapped[datetime] = mapped_column(DateTime, nullable=False, server_default=func.now())
    series_realizadas: Mapped[int] = mapped_column(Integer, nullable=False)
    repeticiones_realizadas: Mapped[int] = mapped_column(Integer, nullable=False)
    peso_realizado: Mapped[float] = mapped_column(Float, nullable=False)
    nota: Mapped[str | None] = mapped_column(String(500), nullable=True)
