from pydantic import BaseModel, EmailStr, Field


class ClienteCreate(BaseModel):
    nombre: str = Field(min_length=1, max_length=255)
    objetivo: str = Field(min_length=1, max_length=500)
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)


class ClienteUpdate(BaseModel):
    nombre: str = Field(min_length=1, max_length=255)
    objetivo: str = Field(min_length=1, max_length=500)


class ClienteResponse(BaseModel):
    id: int
    nombre: str
    objetivo: str

    model_config = {"from_attributes": True}
