from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.songs import router as songs_router

app = FastAPI(
    title="StyleAI Backend",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://127.0.0.1:3000",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(
    songs_router,
    prefix="/songs",
    tags=["Songs"],
)


@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "service": "style-ai-backend",
    }