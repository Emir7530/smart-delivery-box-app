from typing import Any

try:
    from pydantic import BaseModel, ConfigDict

    class JsonBody(BaseModel):
        model_config = ConfigDict(extra="allow")

        def as_dict(self) -> dict[str, Any]:
            return self.model_dump()

except ImportError:  # pragma: no cover - FastAPI installs Pydantic.
    class JsonBody:  # type: ignore[no-redef]
        pass
