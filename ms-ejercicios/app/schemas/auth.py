from typing import Literal

from pydantic import BaseModel, EmailStr, Field, model_validator


class RegistroRequest(BaseModel):
    nombre: str = Field(min_length=1, max_length=255)
    email: EmailStr
    # La fortaleza real (min 8, letra + número) se valida en AuthService.registro
    # con un mensaje propio y 400 -si se pusiera min_length=8 acá, Pydantic
    # respondería 422 en vez del 400 que se pide para este caso-.
    password: str = Field(min_length=1, max_length=128)
    rol: Literal["instructor", "cliente"]
    especialidad: str | None = Field(default=None, max_length=255)
    objetivo: str | None = Field(default=None, max_length=500)
    instructor_id: int | None = None

    @model_validator(mode="after")
    def validate_rol_fields(self) -> "RegistroRequest":
        if self.rol == "instructor":
            if not self.especialidad:
                raise ValueError("especialidad es requerida para rol instructor")
        elif self.rol == "cliente":
            if not self.objetivo:
                raise ValueError("objetivo es requerido para rol cliente")
            if self.instructor_id is None:
                raise ValueError("instructor_id es requerido para rol cliente")
        return self


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class UsuarioResponse(BaseModel):
    id: int
    nombre: str
    email: EmailStr | None = None
    rol: str

    model_config = {"from_attributes": True}


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    usuario: UsuarioResponse
