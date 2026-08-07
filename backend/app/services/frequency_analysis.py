import json
import os
import tempfile
import uuid

import numpy as np
import soundfile as sf
from fastapi import HTTPException, UploadFile
from scipy.signal import stft


FREQUENCY_BANDS = {
    "sub": {
        "label": "Sub",
        "range_hz": [20, 60],
    },
    "low": {
        "label": "Low",
        "range_hz": [60, 120],
    },
    "low_mid": {
        "label": "Low-mid",
        "range_hz": [120, 400],
    },
    "mid": {        
        "label": "Mid",        
        "range_hz": [400, 1500],    
    },    
    "presence": {        
        "label": "Presence",
        "range_hz": [1500, 5000],
    },
    "high": {
        "label": "High",
        "range_hz": [5000, 10000],
    },
    "air": {
        "label": "Air",
        "range_hz": [10000, 20000],
    },
}

EPSILON = 1e-12
ACTIVE_FRAME_THRESHOLD_DB = -45


async def analyze_frequency_file(file: UploadFile) -> dict:
    filename = file.filename or ""
    file_extension = os.path.splitext(filename.lower())[1]

    if file_extension not in [".mp3", ".wav"]:
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

            if not content:
                raise HTTPException(
                    status_code=400,
                    detail="Il file audio è vuoto.",
                )

            temp_file.write(content)
            temp_file_path = temp_file.name

        frequency_analysis = analyze_frequency_file_path(
            file_path=temp_file_path,
            original_filename=filename,
        )

        result = {
            "status": "completed",
            "filename": filename,
            "frequency_analysis": frequency_analysis,
        }

        json_file = save_frequency_analysis_json(result)
        result["json_file"] = json_file

        return result

    finally:
        if temp_file_path and os.path.exists(temp_file_path):
            os.remove(temp_file_path)


def analyze_frequency_file_path(
    file_path: str,
    original_filename: str,
) -> dict:
    audio_data, sample_rate = load_audio(file_path)

    channels = audio_data.shape[1]
    mono_audio = convert_to_mono(audio_data)
    normalized_audio = normalize_for_analysis(mono_audio)

    duration_seconds = len(mono_audio) / sample_rate

    if is_silent(normalized_audio):
        raise HTTPException(
            status_code=400,
            detail="Il file audio risulta silenzioso o non analizzabile.",
        )

    frequency_analysis = analyze_tonal_balance(
        audio=normalized_audio,
        sample_rate=sample_rate,
    )

    return {
        "audio_properties": {            "sample_rate": int(sample_rate),            "duration_seconds": round(duration_seconds, 3),
            "channels": int(channels),
            "samples": int(len(mono_audio)),
        },
        **frequency_analysis,
    }


def load_audio(file_path: str) -> tuple[np.ndarray, int]:
    try:
        audio_data, sample_rate = sf.read(
            file_path,
            always_2d=True,
            dtype="float32",
        )
    except Exception:
        raise HTTPException(
            status_code=400,
            detail="Impossibile leggere il file audio. Verifica che sia un MP3/WAV valido.",
        )

    if audio_data.size == 0:
        raise HTTPException(
            status_code=400,
            detail="Il file audio risulta vuoto.",
        )

    return audio_data, sample_rate


def convert_to_mono(audio_data: np.ndarray) -> np.ndarray:
    return np.mean(audio_data, axis=1)


def normalize_for_analysis(audio_data: np.ndarray) -> np.ndarray:
    max_abs_value = np.max(np.abs(audio_data))

    if max_abs_value == 0:
        return audio_data

    return audio_data / max_abs_value


def is_silent(audio: np.ndarray) -> bool:
    max_abs_value = np.max(np.abs(audio))
    return max_abs_value < EPSILON


def analyze_tonal_balance(audio: np.ndarray, sample_rate: int) -> dict:
    frequencies, times, spectrum = calculate_spectrum(
        audio=audio,
        sample_rate=sample_rate,
    )

    power_spectrum = np.abs(spectrum) ** 2

    active_mask = get_active_frames_mask(power_spectrum)
    active_power_spectrum = power_spectrum[:, active_mask]

    frame_stats = calculate_frame_stats(
        active_mask=active_mask,
        total_frames=power_spectrum.shape[1],
    )

    bands = calculate_bands_energy(
        frequencies=frequencies,
        power_spectrum=active_power_spectrum,
    )

    overall = calculate_overall_profile(
        frequencies=frequencies,
        power_spectrum=active_power_spectrum,
        bands=bands,
    )

    quality = calculate_analysis_quality(
        frame_stats=frame_stats,
        bands=bands,
        overall=overall,
    )

    warnings = generate_tonal_warnings(
        bands=bands,
        overall=overall,
    )

    return {        "bands": bands,
        "overall": overall,
        "frame_stats": frame_stats,
        "quality": quality,
        "warnings": warnings,
        "analysis_config": {
            "bands": FREQUENCY_BANDS,
            "method": "STFT",
            "window": "hann",
            "nperseg": 4096,
            "noverlap": 2048,
            "active_frame_threshold_db": ACTIVE_FRAME_THRESHOLD_DB,
            "description": (
                "Energia frequenziale calcolata su audio mono normalizzato. "
                "I frame quasi silenziosi vengono esclusi dall'analisi. "
                "Le bande sono calcolate tramite somma dell'energia sui bin frequenziali."
            ),
        },
    }


def calculate_spectrum(
    audio: np.ndarray,
    sample_rate: int,
) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    frequencies, times, spectrum = stft(
        audio,
        fs=sample_rate,
        window="hann",
        nperseg=4096,
        noverlap=2048,
        boundary=None,
    )

    return frequencies, times, spectrum


def get_active_frames_mask(power_spectrum: np.ndarray) -> np.ndarray:
    frame_energy = np.sum(power_spectrum, axis=0)

    if frame_energy.size == 0:
        return np.array([], dtype=bool)

    max_frame_energy = np.max(frame_energy)

    if max_frame_energy <= EPSILON:
        return np.ones_like(frame_energy, dtype=bool)

    threshold_linear = max_frame_energy * db_to_linear_power(
        ACTIVE_FRAME_THRESHOLD_DB,
    )

    active_mask = frame_energy >= threshold_linear

    if not np.any(active_mask):
        return np.ones_like(frame_energy, dtype=bool)

    return active_mask


def calculate_frame_stats(
    active_mask: np.ndarray,
    total_frames: int,
) -> dict:
    active_frames = int(np.sum(active_mask))

    if total_frames > 0:
        active_frames_percent = (active_frames / total_frames) * 100
    else:
        active_frames_percent = 0.0

    return {
        "total_frames": int(total_frames),
        "active_frames": active_frames,
        "inactive_frames": int(total_frames - active_frames),
        "active_frames_percent": round(active_frames_percent, 2),
    }


def calculate_bands_energy(
    frequencies: np.ndarray,
    power_spectrum: np.ndarray,
) -> dict:
    band_raw_values = {}
    total_band_energy = 0.0

    for band_key, band_config in FREQUENCY_BANDS.items():
        min_hz, max_hz = band_config["range_hz"]

        max_available_hz = float(np.max(frequencies))
        effective_max_hz = min(max_hz, max_available_hz)

        band_mask = (frequencies >= min_hz) & (frequencies < effective_max_hz)

        if not np.any(band_mask):
            band_power_over_time = np.array([0.0])
        else:
            band_power_over_time = np.sum(
                power_spectrum[band_mask, :],
                axis=0,
            )

        avg_power = float(np.mean(band_power_over_time))
        total_band_energy += avg_power

        band_raw_values[band_key] = {
            "avg_power": avg_power,
            "power_over_time": band_power_over_time,
        }

    bands = {}

    for band_key, raw in band_raw_values.items():
        band_config = FREQUENCY_BANDS[band_key]
        power_over_time = raw["power_over_time"]

        db_over_time = power_to_db(power_over_time)

        avg_db = power_to_db(raw["avg_power"])
        p10_db = float(np.percentile(db_over_time, 10))
        p50_db = float(np.percentile(db_over_time, 50))
        p90_db = float(np.percentile(db_over_time, 90))
        peak_db = float(np.max(db_over_time))

        if total_band_energy > 0:
            energy_percent = (raw["avg_power"] / total_band_energy) * 100
        else:
            energy_percent = 0.0

        variation_db = p90_db - p10_db

        bands[band_key] = {
            "label": band_config["label"],
            "range_hz": band_config["range_hz"],
            "avg_db": round(float(avg_db), 2),
            "p10_db": round(p10_db, 2),
            "p50_db": round(p50_db, 2),
            "p90_db": round(p90_db, 2),
            "peak_db": round(peak_db, 2),
            "variation_db": round(float(variation_db), 2),
            "energy_percent": round(float(energy_percent), 2),
            "status": classify_band_status(
                band_key=band_key,
                energy_percent=energy_percent,
            ),
        }

    return bands


def power_to_db(power: float | np.ndarray) -> float | np.ndarray:
    return 10 * np.log10(power + EPSILON)


def db_to_linear_power(db_value: float) -> float:
    return float(10 ** (db_value / 10))


def calculate_overall_profile(
    frequencies: np.ndarray,
    power_spectrum: np.ndarray,
    bands: dict,
) -> dict:
    mean_spectrum = np.mean(power_spectrum, axis=1)
    total_power = np.sum(mean_spectrum)

    if total_power > 0:
        spectral_centroid_hz = float(
            np.sum(frequencies * mean_spectrum) / total_power
        )
    else:
        spectral_centroid_hz = 0.0

    dominant_band = find_dominant_band(bands)

    tonal_profile = classify_tonal_profile(
        bands=bands,
        spectral_centroid_hz=spectral_centroid_hz,
    )

    low_end_percent = (
        bands["sub"]["energy_percent"]
        + bands["low"]["energy_percent"]
    )

    low_mid_percent = bands["low_mid"]["energy_percent"]

    high_end_percent = (
        bands["presence"]["energy_percent"]
        + bands["high"]["energy_percent"]
        + bands["air"]["energy_percent"]
    )

    return {
        "dominant_band": dominant_band,
        "tonal_profile": tonal_profile,
        "spectral_centroid_hz": round(spectral_centroid_hz, 2),
        "low_end_percent": round(low_end_percent, 2),
        "low_mid_percent": round(low_mid_percent, 2),
        "high_end_percent": round(high_end_percent, 2),
    }


def find_dominant_band(bands: dict) -> str | None:
    if not bands:
        return None

    dominant_band = max(
        bands.items(),
        key=lambda item: item[1]["energy_percent"],
    )

    return dominant_band[0]


def classify_band_status(
    band_key: str,
    energy_percent: float,
) -> str:
    thresholds = {
        "sub": {
            "low": 2,
            "high": 18,
        },
        "low": {            "low": 3,
            "high": 20,
        },
        "low_mid": {
            "low": 8,
            "high": 28,
        },
        "mid": {
            "low": 10,
            "high": 35,
        },
        "presence": {            "low": 8,
            "high": 32,
        },
        "high": {
            "low": 4,
            "high": 26,
        },
        "air": {            "low": 1,
            "high": 18,
        },
    }

    band_thresholds = thresholds.get(
        band_key,
        {
            "low": 5,
            "high": 30,
        },
    )

    if energy_percent < band_thresholds["low"]:
        return "low"

    if energy_percent > band_thresholds["high"]:
        return "high"

    return "normal"


def classify_tonal_profile(
    bands: dict,
    spectral_centroid_hz: float,
) -> str:
    sub_status = bands["sub"]["status"]
    low_status = bands["low"]["status"]
    low_mid_status = bands["low_mid"]["status"]
    presence_status = bands["presence"]["status"]
    high_status = bands["high"]["status"]
    air_status = bands["air"]["status"]

    low_end_percent = (
        bands["sub"]["energy_percent"]
        + bands["low"]["energy_percent"]
    )

    high_end_percent = (
        bands["presence"]["energy_percent"]
        + bands["high"]["energy_percent"]
        + bands["air"]["energy_percent"]
    )

    if low_mid_status == "high" and high_status == "low":
        return "dark_muddy"

    if sub_status == "high" and low_status == "high":
        return "low_end_heavy"

    if low_end_percent > 42 and high_end_percent < 20:
        return "bass_heavy_dark"

    if presence_status == "low" and high_status == "low" and air_status == "low":
        return "dark"

    if high_status == "high" or air_status == "high":
        return "bright"

    if spectral_centroid_hz < 1200:
        return "warm_dark"

    if spectral_centroid_hz > 4000:
        return "bright_forward"

    return "balanced"


def calculate_analysis_quality(
    frame_stats: dict,
    bands: dict,
    overall: dict,
) -> dict:
    score = 1.0
    reasons = []

    active_frames_percent = frame_stats["active_frames_percent"]

    if active_frames_percent < 30:
        score -= 0.35
        reasons.append(
            "Pochi frame attivi rilevati: l'audio potrebbe contenere molte pause o sezioni poco significative."
        )
    elif active_frames_percent < 60:
        score -= 0.15
        reasons.append(
            "Una parte rilevante del file è stata esclusa perché poco energetica."
        )

    if overall["low_end_percent"] > 55:
        score -= 0.15
        reasons.append(
            "Distribuzione molto concentrata sul low-end: l'interpretazione tonale potrebbe essere meno bilanciata."
        )

    if overall["high_end_percent"] < 8:
        score -= 0.10
        reasons.append(
            "Alte frequenze molto basse: possibile file compresso, scuro o con perdita di dettaglio."
        )

    extreme_bands = [
        band_key
        for band_key, band_data in bands.items()
        if band_data["status"] in ["low", "high"]
    ]

    if len(extreme_bands) >= 5:
        score -= 0.10
        reasons.append(
            "Molte bande risultano estreme: il profilo potrebbe richiedere verifica manuale."
        )

    score = max(0.0, min(1.0, score))

    if score >= 0.8:
        label = "high"
    elif score >= 0.55:
        label = "medium"
    else:
        label = "low"

    if not reasons:
        reasons.append(
            "Analisi stabile: numero di frame attivi e distribuzione energetica sufficientemente coerenti."
        )

    return {        "confidence_score": round(score, 2),
        "confidence_label": label,
        "reasons": reasons,
    }


def generate_tonal_warnings(
    bands: dict,
    overall: dict,
) -> list[str]:
    warnings = []

    if bands["sub"]["status"] == "high":
        warnings.append(
            "Il contenuto sub sembra molto presente. Verifica che il low-end non domini il mix."
        )

    if bands["low"]["status"] == "high":
        warnings.append(
            "La banda low è molto presente. Controlla kick, basso e fondamentali nella zona 60–120 Hz."
        )

    if bands["low_mid"]["status"] == "high":
        warnings.append(
            "Possibile accumulo sulle basse-medie frequenze: il mix potrebbe risultare muddy o poco definito."
        )

    if bands["presence"]["status"] == "low":
        warnings.append(
            "La zona presence risulta poco presente: voce, synth lead e strumenti principali potrebbero perdere intelligibilità."
        )

    if bands["high"]["status"] == "low" and bands["air"]["status"] == "low":
        warnings.append(
            "Le alte frequenze risultano contenute: il mix potrebbe suonare scuro o chiuso."
        )

    if bands["high"]["status"] == "high" or bands["air"]["status"] == "high":
        warnings.append(
            "Le alte frequenze risultano molto presenti: attenzione a brillantezza eccessiva, harshness o sibilanza."
        )

    if overall["tonal_profile"] == "dark_muddy":
        warnings.append(
            "Profilo tonale rilevato: scuro e potenzialmente muddy."
        )

    if overall["tonal_profile"] == "low_end_heavy":
        warnings.append(
            "Profilo tonale rilevato: low-end dominante."
        )

    if overall["tonal_profile"] == "bass_heavy_dark":
        warnings.append(
            "Profilo tonale rilevato: basso dominante e alte frequenze relativamente contenute."
        )

    if not warnings:
        warnings.append(
            "Non emergono warning tonali evidenti da questa prima analisi."
        )

    return warnings


def save_frequency_analysis_json(result: dict) -> dict:
    output_dir = os.path.join(
        "app",
        "storage",
        "analysis",
    )

    os.makedirs(
        output_dir,
        exist_ok=True,
    )

    json_filename = f"{uuid.uuid4()}_frequency_analysis.json"
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