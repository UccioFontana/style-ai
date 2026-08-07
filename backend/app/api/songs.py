import os
import tempfile

from fastapi import APIRouter, File, HTTPException, UploadFile

from app.services.complete_analysis import analyze_complete_audio_file

router = APIRouter()

@router.post("/analyze")
async def analyze_song(file: UploadFile = File(...)):
    allowed_content_types = [
        "audio/mpeg",
        "audio/mp3",
        "audio/wav",
        "audio/x-wav",
        "audio/wave",
    ]

    allowed_extensions = [".mp3", ".wav"]

    filename = file.filename or ""
    file_extension = os.path.splitext(filename.lower())[1]

    if (
        file.content_type not in allowed_content_types
        and file_extension not in allowed_extensions
    ):
        raise HTTPException(
            status_code=400,
            detail="Formato non supportato. Carica un file MP3 o WAV.",
        )

    temp_file_path = None

    try:
        with tempfile.NamedTemporaryFile(
            delete=False,
            suffix=file_extension,
        ) as temp_file:
            content = await file.read()
            temp_file.write(content)
            temp_file_path = temp_file.name

        result = analyze_complete_audio_file(
            file_path=temp_file_path,
            original_filename=filename,
        )

        return result

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Errore durante l'analisi audio: {str(e)}",
        )

    finally:
        if temp_file_path and os.path.exists(temp_file_path):
            os.remove(temp_file_path)