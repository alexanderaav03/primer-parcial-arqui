from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import CurrentUser, get_bearer_token, get_current_user, require_cliente
from app.schemas.registro_progreso import RegistroProgresoCreate, RegistroProgresoResponse
from app.services.progreso_service import ProgresoService

router = APIRouter(prefix="/rutinas", tags=["progreso"])


@router.post(
    "/{rutina_id}/detalles/{detalle_id}/registros",
    response_model=RegistroProgresoResponse,
    status_code=status.HTTP_201_CREATED,
)
def crear_registro(
    rutina_id: int,
    detalle_id: int,
    body: RegistroProgresoCreate,
    current_user: Annotated[CurrentUser, Depends(require_cliente)],
    db: Annotated[Session, Depends(get_db)],
) -> RegistroProgresoResponse:
    return ProgresoService(db).crear_registro(rutina_id, detalle_id, body, current_user)


@router.get(
    "/{rutina_id}/detalles/{detalle_id}/registros",
    response_model=list[RegistroProgresoResponse],
)
async def listar_registros(
    rutina_id: int,
    detalle_id: int,
    current_user: Annotated[CurrentUser, Depends(get_current_user)],
    bearer_token: Annotated[str, Depends(get_bearer_token)],
    db: Annotated[Session, Depends(get_db)],
) -> list[RegistroProgresoResponse]:
    return await ProgresoService(db).listar_registros(rutina_id, detalle_id, current_user, bearer_token)
