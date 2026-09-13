"""Rate limiting simple en memoria del proceso para POST /api/auth/login.

No hay Redis en este proyecto, así que esto vive en un dict en memoria -
suficiente para un solo proceso uvicorn como el que corre hoy. Si el
servicio llegara a correr con varios workers/réplicas, cada uno tendría
su propio contador y el límite efectivo se multiplicaría; para ese caso
habría que mover esto a Redis.
"""

import time
from collections import defaultdict

VENTANA_SEGUNDOS = 15 * 60
MAX_INTENTOS_FALLIDOS = 5

_intentos_fallidos: dict[str, list[float]] = defaultdict(list)


def _purgar_antiguos(intentos: list[float], ahora: float) -> None:
    while intentos and ahora - intentos[0] > VENTANA_SEGUNDOS:
        intentos.pop(0)


def excede_limite(email: str) -> bool:
    ahora = time.time()
    intentos = _intentos_fallidos.get(email, [])
    _purgar_antiguos(intentos, ahora)
    return len(intentos) >= MAX_INTENTOS_FALLIDOS


def registrar_intento_fallido(email: str) -> None:
    ahora = time.time()
    intentos = _intentos_fallidos[email]
    _purgar_antiguos(intentos, ahora)
    intentos.append(ahora)


def limpiar_intentos(email: str) -> None:
    _intentos_fallidos.pop(email, None)
