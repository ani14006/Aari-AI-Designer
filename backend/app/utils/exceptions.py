"""Domain-level exceptions, translated to HTTP responses by handlers in main.py."""


class AariDesignerError(Exception):
    """Base class for all application-specific errors."""

    status_code = 500

    def __init__(self, message: str):
        self.message = message
        super().__init__(message)


class UploadError(AariDesignerError):
    status_code = 400


class AIServiceError(AariDesignerError):
    status_code = 502


class NotFoundError(AariDesignerError):
    status_code = 404


class ValidationError(AariDesignerError):
    status_code = 422
