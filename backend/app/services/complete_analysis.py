import json
import os
import uuid

from app.services.audio_analysis import analyze_audio_file
from app.services.frequency_analysis import analyze_frequency_file_path
from app.services.mix_ai_review import generate_mix_ai_review

def analyze_complete_audio_file(
    file_path: str,
    original_filename: str,
    softwareType: str = "None",
    instruments: list[str] | None = None,
    feeling: dict | None = None,
) -> dict:
    if instruments is None:
        instruments = []

    if feeling is None:
        feeling = {}

    technical_metrics = analyze_audio_file(
        file_path=file_path,
        original_filename=original_filename,
    )

    frequency_analysis = analyze_frequency_file_path(
        file_path=file_path,
        original_filename=original_filename,
    )

    combined_analysis = {
        "status": "completed",
        "filename": original_filename,
        "softwareType": softwareType,
        "instruments": instruments,
        "feeling": feeling,
        "technical_metrics": technical_metrics,
        "frequency_analysis": frequency_analysis,
    }

    ai_mix_review = generate_mix_ai_review(
        analysis=combined_analysis,
    )

    result = {
        **combined_analysis,
        "ai_mix_review": ai_mix_review,
    }

    json_file = save_complete_analysis_json(result)
    result["json_file"] = json_file

    return result

def save_complete_analysis_json(result: dict) -> dict:
    output_dir = os.path.join(
        "app",
        "storage",
        "analysis",
    )

    os.makedirs(
        output_dir,
        exist_ok=True,
    )

    json_filename = f"{uuid.uuid4()}_complete_analysis.json"
    json_file_path = os.path.join(
        output_dir,
        json_filename,
    )

    with open(
        json_file_path,
        "w",
        encoding="utf-8",
    ) as json_file:
        json.dump(
            result,
            json_file,
            indent=4,
            ensure_ascii=False,
        )

    return {
        "filename": json_filename,
        "path": json_file_path,
    }