from datetime import datetime

from sqlmodel import JSON, Column, Field, SQLModel

from app.schemas import ActivityType


class ChildModel(SQLModel, table=True):
    __tablename__ = "children"

    id: str = Field(primary_key=True)
    name: str = Field(index=True)
    avatar: str
    preferences: dict = Field(default_factory=dict, sa_column=Column(JSON))
    created_at: datetime


class ActivityModel(SQLModel, table=True):
    __tablename__ = "activities"

    id: str = Field(primary_key=True)
    title: str
    type: ActivityType
    category: str
    difficulty: str
    duration_seconds: int
    prompts: list = Field(sa_column=Column(JSON))
    options: list | None = Field(default=None, sa_column=Column(JSON))
    audio_assets: list | None = Field(default=None, sa_column=Column(JSON))


class SessionModel(SQLModel, table=True):
    __tablename__ = "sessions"

    id: str = Field(primary_key=True)
    child_id: str = Field(index=True)
    activity_id: str = Field(index=True)
    score: int
    duration_seconds: int
    interactions: list = Field(default_factory=list, sa_column=Column(JSON))
    started_at: datetime
    finished_at: datetime
