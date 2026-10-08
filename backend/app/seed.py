from sqlmodel import Session, select

from app.models import ActivityModel

CATALOG: list[dict] = [
    {
        "id": "act_001",
        "title": "Sonidos de la granja",
        "type": "listening",
        "category": "naturaleza",
        "difficulty": "easy",
        "duration_seconds": 120,
        "prompts": ['¿Qué animal hace "mu"?', '¿Qué animal hace "oink"?'],
        "audio_assets": ["cow.mp3", "pig.mp3"],
    },
    {
        "id": "act_002",
        "title": "Colores del arcoíris",
        "type": "visual",
        "category": "artistica",
        "difficulty": "easy",
        "duration_seconds": 150,
        "prompts": ["Selecciona el color rojo", "Selecciona el color azul"],
        "options": ["🔴", "🟢", "🔵", "🟡"],
    },
    {
        "id": "act_003",
        "title": "Parejas de frutas",
        "type": "memory",
        "category": "cognitiva",
        "difficulty": "easy",
        "duration_seconds": 180,
        "prompts": [
            "Encontrá la pareja de la manzana 🍎",
            "Encontrá la pareja del plátano 🍌",
        ],
        "options": ["🍎", "🍌", "🍇", "🍊"],
    },
    {
        "id": "act_004",
        "title": "Números del 1 al 3",
        "type": "visual",
        "category": "matematica",
        "difficulty": "easy",
        "duration_seconds": 120,
        "prompts": ["Selecciona el número 2", "Selecciona el número 3"],
        "options": ["1️⃣", "2️⃣", "3️⃣", "4️⃣"],
    },
]


def seed_activities(session: Session) -> None:
    existing = session.exec(select(ActivityModel)).all()
    if existing:
        return
    for item in CATALOG:
        session.add(ActivityModel(**item))
    session.commit()
