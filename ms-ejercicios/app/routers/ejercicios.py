from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import CurrentUser, get_bearer_token, get_current_user, require_instructor
from app.schemas.ejercicio import EjercicioCreate, EjercicioResponse
from app.services.ejercicio_service import EjercicioService

router = APIRouter(prefix="/ejercicios", tags=["ejercicios"])


@router.get("", response_model=list[EjercicioResponse])
def list_ejercicios(
    current_user: Annotated[CurrentUser, Depends(require_instructor)],
    db: Annotated[Session, Depends(get_db)],
) -> list[EjercicioResponse]:
    return EjercicioService(db).list_by_instructor(current_user.id)


@router.post("", response_model=EjercicioResponse, status_code=status.HTTP_201_CREATED)
def create_ejercicio(
    body: EjercicioCreate,
    current_user: Annotated[CurrentUser, Depends(require_instructor)],
    db: Annotated[Session, Depends(get_db)],
) -> EjercicioResponse:
    return EjercicioService(db).create(current_user.id, body)


@router.get("/batch", response_model=list[EjercicioResponse])
def get_ejercicios_batch(
    ids: str,
    current_user: Annotated[CurrentUser, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> list[EjercicioResponse]:
    """Version batch de GET /ejercicios/{id}: uso pensado para el gateway,
    que arma el detalle de una rutina y necesita los datos de varios
    ejercicios a la vez sin hacer una llamada HTTP por cada uno (N+1).

    ids: lista de ids separados por coma, ej. "1,2,3".
    """
    try:
        ids_parseados = [int(i) for i in ids.split(",") if i.strip()]
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Parámetro 'ids' inválido, formato esperado: ids=1,2,3",
        ) from None

    return EjercicioService(db).get_by_ids(ids_parseados, current_user)


@router.get("/{ejercicio_id}", response_model=EjercicioResponse)
def get_ejercicio(
    ejercicio_id: int,
    current_user: Annotated[CurrentUser, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> EjercicioResponse:
    return EjercicioService(db).get_by_id(ejercicio_id, current_user)


@router.put("/{ejercicio_id}", response_model=EjercicioResponse)
def update_ejercicio(
    ejercicio_id: int,
    body: EjercicioCreate,
    current_user: Annotated[CurrentUser, Depends(require_instructor)],
    db: Annotated[Session, Depends(get_db)],
) -> EjercicioResponse:
    return EjercicioService(db).update(ejercicio_id, current_user.id, body)


@router.delete("/{ejercicio_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_ejercicio(
    ejercicio_id: int,
    current_user: Annotated[CurrentUser, Depends(require_instructor)],
    bearer_token: Annotated[str, Depends(get_bearer_token)],
    db: Annotated[Session, Depends(get_db)],
) -> None:
    await EjercicioService(db).delete(ejercicio_id, current_user.id, bearer_token)
