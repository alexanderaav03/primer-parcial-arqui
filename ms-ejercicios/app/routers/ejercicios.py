from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import CurrentUser, get_current_user, require_instructor
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
