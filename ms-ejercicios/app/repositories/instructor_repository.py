from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.instructor import Instructor


class InstructorRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_by_id(self, instructor_id: int) -> Instructor | None:
        return self.db.get(Instructor, instructor_id)

    def get_by_email(self, email: str) -> Instructor | None:
        stmt = select(Instructor).where(Instructor.email == email)
        return self.db.scalar(stmt)

    def create(self, instructor: Instructor) -> Instructor:
        self.db.add(instructor)
        self.db.commit()
        self.db.refresh(instructor)
        return instructor
