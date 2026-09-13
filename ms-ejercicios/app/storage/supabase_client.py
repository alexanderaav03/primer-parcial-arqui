import logging
import uuid
from pathlib import PurePath

from app.config import settings

logger = logging.getLogger(__name__)


class SupabaseStorageClient:
    """Cliente simple para subir archivos a Supabase Storage y obtener URL pública."""

    def __init__(self) -> None:
        self._client = None
        self._bucket = settings.SUPABASE_BUCKET

    @property
    def is_configured(self) -> bool:
        return bool(settings.SUPABASE_URL and settings.SUPABASE_KEY)

    def _get_client(self):
        if self._client is None:
            if not self.is_configured:
                raise RuntimeError("Supabase no está configurado (SUPABASE_URL / SUPABASE_KEY)")
            from supabase import create_client

            self._client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
        return self._client

    def upload_file(self, file_bytes: bytes, filename: str, content_type: str | None = None) -> str:
        client = self._get_client()
        extension = PurePath(filename).suffix
        storage_path = f"{uuid.uuid4().hex}{extension}"

        options = {"content-type": content_type} if content_type else None
        client.storage.from_(self._bucket).upload(
            path=storage_path,
            file=file_bytes,
            file_options=options,
        )
        return client.storage.from_(self._bucket).get_public_url(storage_path)

    def upload_or_use_url(
        self,
        file_bytes: bytes | None,
        filename: str | None,
        direct_url: str | None,
        content_type: str | None = None,
    ) -> str | None:
        if file_bytes and filename:
            try:
                return self.upload_file(file_bytes, filename, content_type)
            except Exception:
                logger.exception("Error subiendo archivo a Supabase; usando URL directa si existe")
                return direct_url
        return direct_url


supabase_storage = SupabaseStorageClient()
