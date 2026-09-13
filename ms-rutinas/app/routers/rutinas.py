from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import CurrentUser, get_bearer_token, get_current_user, require_instructor
from app.schemas.rutina import RutinaCreate, RutinaResponse, RutinaUpdate
from app.services.rutina_service import RutinaService

router = APIRouter(prefix="/rutinas", tags=["rutinas"])


@router.get("", response_model=list[RutinaResponse])
def list_rutinas(
    cliente_id: Annotated[int, Query(gt=0)],
    current_user: Annotated[CurrentUser, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> list[RutinaResponse]:
    return RutinaService(db).list_by_cliente(cliente_id, current_user)


@router.post("", response_model=RutinaResponse, status_code=status.HTTP_201_CREATED)
async def create_rutina(
    body: RutinaCreate,
    current_user: Annotated[CurrentUser, Depends(require_instructor)],
    bearer_token: Annotated[str, Depends(get_bearer_token)],
    db: Annotated[Session, Depends(get_db)],
) -> RutinaResponse:
    return await RutinaService(db).create(body, bearer_token)


@router.get("/{rutina_id}", response_model=RutinaResponse)
def get_rutina(
    rutina_id: int,
    current_user: Annotated[CurrentUser, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> RutinaResponse:
    return RutinaService(db).get_by_id(rutina_id, current_user)


@router.put("/{rutina_id}", response_model=RutinaResponse)
async def update_rutina(
    rutina_id: int,
    body: RutinaUpdate,
    current_user: Annotated[CurrentUser, Depends(require_instructor)],
    bearer_token: Annotated[str, Depends(get_bearer_token)],
    db: Annotated[Session, Depends(get_db)],
) -> RutinaResponse:
    return await RutinaService(db).update(rutina_id, body, bearer_token)


@router.delete("/{rutina_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_rutina(
    rutina_id: int,
    current_user: Annotated[CurrentUser, Depends(require_instructor)],
    bearer_token: Annotated[str, Depends(get_bearer_token)],
    db: Annotated[Session, Depends(get_db)],
) -> None:
    await RutinaService(db).delete(rutina_id, bearer_token)
