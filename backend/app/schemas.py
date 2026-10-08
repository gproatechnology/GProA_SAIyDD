from datetime import datetime
from enum import Enum

from pydantic import BaseModel, ConfigDict, Field, field_validator
from pydantic.alias_generators import to_camel


class CamelModel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)


class ActivityType(str, Enum):
    listening = "listening"
    visual = "visual"
    memory = "memory"


class ActivityPublic(CamelModel):
    id: str
    title: str
    type: ActivityType
    category: str
    difficulty: str
    duration_seconds: int = Field(ge=1)
    prompts: list[str] = Field(min_length=1)
    options: list[str] | None = None
    audio_assets: list[str] | None = None


class ChildPreferences(CamelModel):
    topic: str = "animales"
    difficulty: str = "easy"


class ChildProfileCreate(CamelModel):
    name: str = Field(min_length=1, max_length=40)
    avatar: str = Field(min_length=1, max_length=30)
    preferences: ChildPreferences = Field(default_factory=ChildPreferences)


class ChildProfile(ChildProfileCreate):
    id: str
    created_at: datetime


class InteractionRecord(CamelModel):
    prompt_index: int = Field(ge=0)
    selected_index: int = Field(ge=0)
    correct: bool
    response_time_ms: int | None = Field(default=None, ge=0)


class SessionRecordCreate(CamelModel):
    child_id: str = Field(min_length=1)
    activity_id: str = Field(min_length=1)
    score: int = Field(ge=0)
    duration_seconds: int = Field(ge=0)
    interactions: list[InteractionRecord] = Field(default_factory=list)


class SessionRecord(SessionRecordCreate):
    id: str
    started_at: datetime
    finished_at: datetime


class ProgressReport(CamelModel):
    child_id: str
    total_sessions: int
    average_score: float
    total_seconds: int
    last_activity_at: datetime | None = None


class HealthStatus(CamelModel):
    status: str
    version: str


def _normalize_email(value: str) -> str:
    return value.strip().lower()


class TutorCreate(CamelModel):
    email: str = Field(min_length=3, max_length=254)
    display_name: str = Field(min_length=1, max_length=40)
    password: str = Field(min_length=8, max_length=72)

    @field_validator("email")
    @classmethod
    def normalize_email(cls, value: str) -> str:
        return _normalize_email(value)


class TutorPublic(CamelModel):
    id: str
    email: str
    display_name: str
    created_at: datetime


class LoginRequest(CamelModel):
    email: str = Field(min_length=3, max_length=254)
    password: str = Field(min_length=1, max_length=72)

    @field_validator("email")
    @classmethod
    def normalize_email(cls, value: str) -> str:
        return _normalize_email(value)


class TokenResponse(CamelModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int = Field(ge=1)
