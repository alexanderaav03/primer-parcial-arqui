from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import CurrentUser, get_bearer_token, require_instructor
from app.schemas.cliente import ClienteCreate, ClienteResponse, ClienteUpdate
from app.services.cliente_service import ClienteService

router = APIRouter(prefix="/clientes", tags=["clientes"])


@router.get("", response_model=list[ClienteResponse])
def list_clientes(
    current_user: Annotated[CurrentUser, Depends(require_instructor)],
    db: Annotated[Session, Depends(get_db)],
) -> list[ClienteResponse]:
    return ClienteService(db).list_by_instructor(current_user.id)


@router.post("", response_model=ClienteResponse, status_code=status.HTTP_201_CREATED)
def create_cliente(
    body: ClienteCreate,
    current_user: Annotated[CurrentUser, Depends(require_instructor)],
    db: Annotated[Session, Depends(get_db)],
) -> ClienteResponse:
    return ClienteService(db).create(current_user.id, body)


@router.put("/{cliente_id}", response_model=ClienteResponse)
def update_cliente(
    cliente_id: int,
    body: ClienteUpdate,
    current_user: Annotated[CurrentUser, Depends(require_instructor)],
    db: Annotated[Session, Depends(get_db)],
) -> ClienteResponse:
    return ClienteService(db).update(current_user.id, cliente_id, body)


@router.delete("/{cliente_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_cliente(
    cliente_id: int,
    current_user: Annotated[CurrentUser, Depends(require_instructor)],
    bearer_token: Annotated[str, Depends(get_bearer_token)],
    db: Annotated[Session, Depends(get_db)],
) -> None:
    await ClienteService(db).delete(cliente_id, current_user.id, bearer_token)
