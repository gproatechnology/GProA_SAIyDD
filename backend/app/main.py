from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import Session

from app.config import settings
from app.database import engine, get_session, init_db
from app.models import ActivityModel
from app.repositories import (
    activity_exists,
    child_exists,
    create_child,
    create_session,
    get_child,
    get_progress,
    list_activities,
)
from app.seed import seed_activities
from app.schemas import (
    ActivityPublic,
    ChildProfile,
    ChildProfileCreate,
    HealthStatus,
    ProgressReport,
    SessionRecord,
    SessionRecordCreate,
)


@asynccontextmanager
async def lifespan(_: FastAPI):
    init_db()
    with Session(engine) as session:
        seed_activities(session)
    yield


app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="API del Sistema de Aprendizaje Inclusivo (SaIyDD).",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)


@app.get("/api/health", response_model=HealthStatus, tags=["meta"])
def health() -> HealthStatus:
    return HealthStatus(status="ok", version=settings.app_version)


@app.get("/api/activities", response_model=list[ActivityPublic], tags=["actividades"])
def list_activities_endpoint(
    session: Session = Depends(get_session),
) -> list[ActivityPublic]:
    return [
        ActivityPublic(
            id=item.id,
            title=item.title,
            type=item.type,
            category=item.category,
            difficulty=item.difficulty,
            duration_seconds=item.duration_seconds,
            prompts=item.prompts,
            options=item.options,
            audio_assets=item.audio_assets,
        )
        for item in list_activities(session)
    ]


@app.post(
    "/api/children",
    response_model=ChildProfile,
    status_code=status.HTTP_201_CREATED,
    tags=["niños"],
)
def create_child_endpoint(
    data: ChildProfileCreate,
    session: Session = Depends(get_session),
) -> ChildProfile:
    return create_child(session, data)


@app.get("/api/children/{child_id}", response_model=ChildProfile, tags=["niños"])
def get_child_endpoint(
    child_id: str,
    session: Session = Depends(get_session),
) -> ChildProfile:
    child = get_child(session, child_id)
    if child is None:
        raise HTTPException(status_code=404, detail="Niño no encontrado")
    return child


@app.post(
    "/api/sessions",
    response_model=SessionRecord,
    status_code=status.HTTP_201_CREATED,
    tags=["sesiones"],
)
def create_session_endpoint(
    data: SessionRecordCreate,
    session: Session = Depends(get_session),
) -> SessionRecord:
    if not child_exists(session, data.child_id):
        raise HTTPException(status_code=404, detail="Niño no encontrado")
    if not activity_exists(session, data.activity_id):
        raise HTTPException(status_code=404, detail="Actividad no encontrada")
    return create_session(session, data)


@app.get(
    "/api/children/{child_id}/progress",
    response_model=ProgressReport,
    tags=["progreso"],
)
def get_progress_endpoint(
    child_id: str,
    session: Session = Depends(get_session),
) -> ProgressReport:
    if not child_exists(session, child_id):
        raise HTTPException(status_code=404, detail="Niño no encontrado")
    return get_progress(session, child_id)
