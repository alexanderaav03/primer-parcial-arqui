from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import CurrentUser, require_instructor
from app.repositories.instructor_repository import InstructorRepository
from app.schemas.instructor import InstructorResponse

router = APIRouter(prefix="/instructores", tags=["instructores"])


@router.get("/me", response_model=InstructorResponse)
def get_me(
    current_user: Annotated[CurrentUser, Depends(require_instructor)],
    db: Annotated[Session, Depends(get_db)],
) -> InstructorResponse:
    instructor = InstructorRepository(db).get_by_id(current_user.id)
    return InstructorResponse.model_validate(instructor)
