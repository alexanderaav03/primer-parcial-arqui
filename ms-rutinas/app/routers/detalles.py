from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import CurrentUser, get_bearer_token, get_current_user, require_instructor
from app.schemas.detalle_rutina import DetalleRutinaCreate, DetalleRutinaResponse
from app.services.detalle_service import DetalleService

router = APIRouter(prefix="/rutinas", tags=["detalles"])


@router.get("/{rutina_id}/detalles", response_model=list[DetalleRutinaResponse])
def list_detalles(
    rutina_id: int,
    current_user: Annotated[CurrentUser, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> list[DetalleRutinaResponse]:
    return DetalleService(db).list_by_rutina(rutina_id, current_user)


@router.post(
    "/{rutina_id}/detalles",
    response_model=DetalleRutinaResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_detalle(
    rutina_id: int,
    body: DetalleRutinaCreate,
    current_user: Annotated[CurrentUser, Depends(require_instructor)],
    bearer_token: Annotated[str, Depends(get_bearer_token)],
    db: Annotated[Session, Depends(get_db)],
) -> DetalleRutinaResponse:
    return await DetalleService(db).create(rutina_id, body, bearer_token)


@router.delete("/{rutina_id}/detalles/{detalle_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_detalle(
    rutina_id: int,
    detalle_id: int,
    current_user: Annotated[CurrentUser, Depends(require_instructor)],
    bearer_token: Annotated[str, Depends(get_bearer_token)],
    db: Annotated[Session, Depends(get_db)],
) -> None:
    await DetalleService(db).delete(rutina_id, detalle_id, bearer_token)
