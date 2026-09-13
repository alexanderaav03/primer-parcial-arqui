from pydantic import BaseModel, EmailStr, Field


class ClienteCreate(BaseModel):
    nombre: str = Field(min_length=1, max_length=255)
    objetivo: str = Field(min_length=1, max_length=500)
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)
    peso: float | None = Field(default=None, gt=0)
    altura: float | None = Field(default=None, gt=0)


class ClienteUpdate(BaseModel):
    nombre: str = Field(min_length=1, max_length=255)
    objetivo: str = Field(min_length=1, max_length=500)
    peso: float | None = Field(default=None, gt=0)
    altura: float | None = Field(default=None, gt=0)


class ClienteResponse(BaseModel):
    id: int
    nombre: str
    objetivo: str
    peso: float | None = None
    altura: float | None = None

    model_config = {"from_attributes": True}
