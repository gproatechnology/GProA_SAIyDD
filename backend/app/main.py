from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.schemas import ActivityPublic, HealthStatus

app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="API del Sistema de Aprendizaje Inclusivo (SaIyDD).",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

ACTIVITIES: list[ActivityPublic] = [
    ActivityPublic(
        id="act_001",
        title="Sonidos de la granja",
        type="listening",
        category="naturaleza",
        difficulty="easy",
        duration_seconds=120,
        prompts=['¿Qué animal hace "mu"?', '¿Qué animal hace "oink"?'],
        audio_assets=["cow.mp3", "pig.mp3"],
    ),
    ActivityPublic(
        id="act_002",
        title="Colores del arcoíris",
        type="visual",
        category="artistica",
        difficulty="easy",
        duration_seconds=150,
        prompts=["Selecciona el color rojo", "Selecciona el color azul"],
        options=["🔴", "🟢", "🔵", "🟡"],
    ),
    ActivityPublic(
        id="act_003",
        title="Parejas de frutas",
        type="memory",
        category="cognitiva",
        difficulty="easy",
        duration_seconds=180,
        prompts=[
            "Encontrá la pareja de la manzana 🍎",
            "Encontrá la pareja del plátano 🍌",
        ],
        options=["🍎", "🍌", "🍇", "🍊"],
    ),
    ActivityPublic(
        id="act_004",
        title="Números del 1 al 3",
        type="visual",
        category="matematica",
        difficulty="easy",
        duration_seconds=120,
        prompts=["Selecciona el número 2", "Selecciona el número 3"],
        options=["1️⃣", "2️⃣", "3️⃣", "4️⃣"],
    ),
]


@app.get("/api/health", response_model=HealthStatus, tags=["meta"])
def health() -> HealthStatus:
    return HealthStatus(status="ok", version=settings.app_version)


@app.get("/api/activities", response_model=list[ActivityPublic], tags=["actividades"])
def list_activities() -> list[ActivityPublic]:
    return ACTIVITIES
