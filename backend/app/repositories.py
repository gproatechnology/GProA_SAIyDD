import secrets
from datetime import datetime, timezone

from sqlmodel import Session, select

from app.models import ActivityModel, ChildModel, SessionModel, TutorModel
from app.schemas import (
    ChildPreferences,
    ChildProfile,
    ChildProfileCreate,
    InteractionRecord,
    ProgressReport,
    SessionRecord,
    SessionRecordCreate,
    TutorCreate,
    TutorPublic,
)


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


def new_id(prefix: str) -> str:
    return f"{prefix}_{secrets.token_hex(6)}"


def create_child(session: Session, data: ChildProfileCreate) -> ChildProfile:
    child = ChildModel(
        id=new_id("child"),
        name=data.name,
        avatar=data.avatar,
        preferences=data.preferences.model_dump(),
        created_at=utcnow(),
    )
    session.add(child)
    session.commit()
    session.refresh(child)
    return to_child_profile(child)


def get_child(session: Session, child_id: str) -> ChildProfile | None:
    child = session.get(ChildModel, child_id)
    if child is None:
        return None
    return to_child_profile(child)


def child_exists(session: Session, child_id: str) -> bool:
    return session.get(ChildModel, child_id) is not None


def activity_exists(session: Session, activity_id: str) -> bool:
    return session.get(ActivityModel, activity_id) is not None


def list_activities(session: Session) -> list[ActivityModel]:
    return session.exec(select(ActivityModel)).all()


def create_session(session: Session, data: SessionRecordCreate) -> SessionRecord:
    now = utcnow()
    record = SessionModel(
        id=new_id("sess"),
        child_id=data.child_id,
        activity_id=data.activity_id,
        score=data.score,
        duration_seconds=data.duration_seconds,
        interactions=[item.model_dump() for item in data.interactions],
        started_at=now,
        finished_at=now,
    )
    session.add(record)
    session.commit()
    session.refresh(record)
    return to_session_record(record)


def get_progress(session: Session, child_id: str) -> ProgressReport:
    sessions = session.exec(
        select(SessionModel).where(SessionModel.child_id == child_id)
    ).all()
    total = len(sessions)
    average = round(sum(s.score for s in sessions) / total, 2) if total else 0.0
    total_seconds = sum(s.duration_seconds for s in sessions)
    last = max((s.finished_at for s in sessions), default=None)
    return ProgressReport(
        child_id=child_id,
        total_sessions=total,
        average_score=average,
        total_seconds=total_seconds,
        last_activity_at=last,
    )


def to_child_profile(child: ChildModel) -> ChildProfile:
    return ChildProfile(
        id=child.id,
        name=child.name,
        avatar=child.avatar,
        preferences=ChildPreferences(**child.preferences),
        created_at=child.created_at,
    )


def to_session_record(record: SessionModel) -> SessionRecord:
    return SessionRecord(
        id=record.id,
        child_id=record.child_id,
        activity_id=record.activity_id,
        score=record.score,
        duration_seconds=record.duration_seconds,
        interactions=[InteractionRecord(**item) for item in record.interactions],
        started_at=record.started_at,
        finished_at=record.finished_at,
    )


def create_tutor(
    session: Session, data: TutorCreate, password_hash: str
) -> TutorPublic:
    tutor = TutorModel(
        id=new_id("tutor"),
        email=data.email,
        display_name=data.display_name,
        password_hash=password_hash,
        created_at=utcnow(),
    )
    session.add(tutor)
    session.commit()
    session.refresh(tutor)
    return to_tutor_public(tutor)


def get_tutor(session: Session, tutor_id: str) -> TutorModel | None:
    return session.get(TutorModel, tutor_id)


def get_tutor_by_email(session: Session, email: str) -> TutorModel | None:
    return session.exec(
        select(TutorModel).where(TutorModel.email == email)
    ).first()


def tutor_exists(session: Session, email: str) -> bool:
    return get_tutor_by_email(session, email) is not None


def to_tutor_public(tutor: TutorModel) -> TutorPublic:
    return TutorPublic(
        id=tutor.id,
        email=tutor.email,
        display_name=tutor.display_name,
        created_at=tutor.created_at,
    )
