from pydantic import BaseModel, EmailStr


class InstructorResponse(BaseModel):
    id: int
    nombre: str
    especialidad: str
    email: EmailStr
    rol: str

    model_config = {"from_attributes": True}
