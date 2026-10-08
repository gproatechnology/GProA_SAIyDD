from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI, HTTPException, Request, status
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter
from slowapi.util import get_remote_address
from sqlmodel import Session

from app.auth import (
    create_access_token,
    hash_password,
    require_tutor,
    verify_password,
)
from app.config import settings
from app.database import engine, get_session, init_db
from app.errors import register_error_handlers
from app.models import ActivityModel, TutorModel
from app.repositories import (
    activity_exists,
    child_exists,
    create_child,
    create_session,
    create_tutor,
    get_child,
    get_progress,
    get_tutor_by_email,
    list_activities,
    tutor_exists,
)
from app.seed import seed_activities
from app.schemas import (
    ActivityPublic,
    ChildProfile,
    ChildProfileCreate,
    HealthStatus,
    LoginRequest,
    ProgressReport,
    SessionRecord,
    SessionRecordCreate,
    TokenResponse,
    TutorCreate,
    TutorPublic,
)

limiter = Limiter(key_func=get_remote_address)


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
app.state.limiter = limiter
register_error_handlers(app)


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
    tutor: TutorModel = Depends(require_tutor),
    session: Session = Depends(get_session),
) -> ChildProfile:
    return create_child(session, data)


@app.get("/api/children/{child_id}", response_model=ChildProfile, tags=["niños"])
def get_child_endpoint(
    child_id: str,
    tutor: TutorModel = Depends(require_tutor),
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
    tutor: TutorModel = Depends(require_tutor),
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
    tutor: TutorModel = Depends(require_tutor),
    session: Session = Depends(get_session),
) -> ProgressReport:
    if not child_exists(session, child_id):
        raise HTTPException(status_code=404, detail="Niño no encontrado")
    return get_progress(session, child_id)


@app.post(
    "/api/auth/register",
    response_model=TutorPublic,
    status_code=status.HTTP_201_CREATED,
    tags=["auth"],
)
@limiter.limit("5/hour")
def register_endpoint(
    request: Request,
    data: TutorCreate,
    session: Session = Depends(get_session),
) -> TutorPublic:
    if tutor_exists(session, data.email):
        raise HTTPException(
            status_code=409, detail="El tutor ya está registrado"
        )
    return create_tutor(session, data, hash_password(data.password))


@app.post("/api/auth/login", response_model=TokenResponse, tags=["auth"])
@limiter.limit("10/minute")
def login_endpoint(
    request: Request,
    data: LoginRequest,
    session: Session = Depends(get_session),
) -> TokenResponse:
    tutor = get_tutor_by_email(session, data.email)
    if tutor is None or not verify_password(data.password, tutor.password_hash):
        raise HTTPException(status_code=401, detail="Credenciales inválidas")
    token = create_access_token(tutor.id)
    return TokenResponse(
        access_token=token,
        expires_in=settings.access_token_expire_minutes * 60,
    )
