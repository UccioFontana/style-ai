from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi import UploadFile, File, HTTPException
from mutagen import File as MutagenFile
import tempfile
import os

app = FastAPI(
    title="StyleAI Backend",
    version="0.1.0"
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

@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "service": "styleai-backend"
    }

@app.post("/songs/analyze")
async def analyze_song(file: UploadFile = File(...)):
    allowed_content_types = [
        "audio/mpeg",
        "audio/mp3",
        "audio/wav",
        "audio/x-wav",
        "audio/wave"
    ]

    allowed_extensions = [".mp3", ".wav"]

    filename = file.filename or ""
    file_extension = os.path.splitext(filename.lower())[1]

    if file.content_type not in allowed_content_types and file_extension not in allowed_extensions:
        raise HTTPException(
            status_code=400,
            detail="Formato non supportato. Carica un file MP3 o WAV."
        )

    temp_file_path = None

    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=file_extension) as temp_file:
            content = await file.read()
            temp_file.write(content)
            temp_file_path = temp_file.name

        audio = MutagenFile(temp_file_path)

        if audio is None or audio.info is None or not hasattr(audio.info, "length"):
            raise HTTPException(
                status_code=400,
                detail="Impossibile leggere la durata del file audio."
            )

        duration_seconds = int(round(audio.info.length))
        minutes = duration_seconds // 60
        seconds = duration_seconds % 60

        return {
            "status": "completed",
            "filename": filename,
            "duration": {
                "minutes": minutes,
                "seconds": seconds,
                "total_seconds": duration_seconds,
                "formatted": f"{minutes}:{seconds:02d}"
            }
        }

    finally:
        if temp_file_path and os.path.exists(temp_file_path):
            os.remove(temp_file_path)