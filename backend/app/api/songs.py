import json
import os
import tempfile

from fastapi import APIRouter, File, Form, HTTPException, UploadFile

from app.services.complete_analysis import analyze_complete_audio_file

router = APIRouter()

@router.post("/analyze")
async def analyze_song(
    file: UploadFile = File(...),
    softwareType: str = Form("None"),
    instruments: str = Form("[]"),
    feeling: str = Form("{}"),
):
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

    parsed_instruments = parse_instruments(instruments)
    parsed_feeling = parse_feeling(feeling)

    temp_file_path = None

    try:
        with tempfile.NamedTemporaryFile(
            delete=False,
            suffix=file_extension,
        ) as temp_file:
            content = await file.read()

            if not content:
                raise HTTPException(
                    status_code=400,
                    detail="Il file audio è vuoto.",
                )

            temp_file.write(content)
            temp_file_path = temp_file.name

        result = analyze_complete_audio_file(
            file_path=temp_file_path,
            original_filename=filename,
            softwareType=softwareType,
            instruments=parsed_instruments,
            feeling=parsed_feeling,
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

def parse_instruments(instruments: str) -> list[str]:
    try:
        parsed_instruments = json.loads(instruments)

        if not isinstance(parsed_instruments, list):
            raise ValueError("Il campo instruments deve essere una lista JSON.")

        for item in parsed_instruments:
            if not isinstance(item, str):
                raise ValueError(
                    "Il campo instruments deve contenere solo stringhe."
                )

        return parsed_instruments

    except Exception:
        raise HTTPException(
            status_code=400,
            detail=(
                "Formato instruments non valido. "
                "Invia una lista JSON stringificata di strumenti."
            ),
        )

def parse_feeling(feeling: str) -> dict:
    try:
        parsed_feeling = json.loads(feeling)

        if not isinstance(parsed_feeling, dict):
            raise ValueError("Il campo feeling deve essere un oggetto JSON.")

        for key, value in parsed_feeling.items():
            if not isinstance(key, str):
                raise ValueError("Le chiavi di feeling devono essere stringhe.")

            if not isinstance(value, (int, float)):
                raise ValueError("I valori di feeling devono essere numerici.")

        return parsed_feeling

    except Exception:
        raise HTTPException(
            status_code=400,
            detail=(
                "Formato feeling non valido. "
                "Invia una map JSON stringificata con valori numerici."
            ),
        )