import numpy as np
import pyloudnorm as pyln
import soundfile as sf
from fastapi import HTTPException
from mutagen import File as MutagenFile
from scipy.signal import resample_poly


def analyze_audio_file(file_path: str, original_filename: str) -> dict:
    metadata_audio = MutagenFile(file_path)

    if (
        metadata_audio is None
        or metadata_audio.info is None
        or not hasattr(metadata_audio.info, "length")
    ):
        raise HTTPException(
            status_code=400,
            detail="Impossibile leggere la durata del file audio.",
        )

    duration_seconds_float = float(metadata_audio.info.length)
    duration_seconds = int(round(duration_seconds_float))
    minutes = duration_seconds // 60
    seconds = duration_seconds % 60

    try:
        audio_data, sample_rate = sf.read(
            file_path,
            always_2d=True,
        )
    except Exception:
        raise HTTPException(
            status_code=400,
            detail="Impossibile decodificare il file audio. Verifica che sia un MP3/WAV valido.",
        )

    if audio_data.size == 0:
        raise HTTPException(
            status_code=400,
            detail="Il file audio risulta vuoto.",
        )

    audio_data = audio_data.astype(np.float64)
    channels = audio_data.shape[1]
    mono_audio = np.mean(audio_data, axis=1)

    max_abs_peak = float(np.max(np.abs(audio_data)))

    if max_abs_peak > 0:
        peak_dbfs = float(20 * np.log10(max_abs_peak))
    else:
        peak_dbfs = float("-inf")

    rms_linear = float(np.sqrt(np.mean(np.square(audio_data))))

    if rms_linear > 0:
        rms_dbfs = float(20 * np.log10(rms_linear))
    else:
        rms_dbfs = float("-inf")

    if rms_linear > 0:
        crest_factor_db = float(peak_dbfs - rms_dbfs)
        crest_factor_linear = float(max_abs_peak / rms_linear)
    else:
        crest_factor_db = None
        crest_factor_linear = None

    if np.isfinite(peak_dbfs):
        headroom_db = float(0 - peak_dbfs)
    else:
        headroom_db = None

    clipping_threshold = 0.999
    clipped_samples = int(np.sum(np.abs(audio_data) >= clipping_threshold))
    total_samples = int(audio_data.size)

    if total_samples > 0:
        clipping_percentage = float((clipped_samples / total_samples) * 100)
    else:
        clipping_percentage = 0.0

    clipping_detected = clipped_samples > 0

    meter = pyln.Meter(sample_rate)

    try:
        lufs_integrated = float(meter.integrated_loudness(mono_audio))
    except Exception:
        lufs_integrated = None

    lufs_short_term_values = calculate_window_loudness(
        audio=mono_audio,
        sample_rate=sample_rate,
        meter=meter,
        window_seconds=3.0,
        hop_seconds=1.0,
    )

    lufs_momentary_values = calculate_window_loudness(
        audio=mono_audio,
        sample_rate=sample_rate,
        meter=meter,
        window_seconds=0.4,
        hop_seconds=0.1,
    )

    true_peak_linear = None
    true_peak_dbtp = None

    try:
        oversampled_audio = resample_poly(
            audio_data,
            up=4,
            down=1,
            axis=0,
        )

        true_peak_linear = float(np.max(np.abs(oversampled_audio)))

        if true_peak_linear > 0:
            true_peak_dbtp = float(20 * np.log10(true_peak_linear))
        else:
            true_peak_dbtp = float("-inf")
    except Exception:
        pass

    bit_depth = None
    audio_format = None
    audio_subtype = None

    try:
        audio_info = sf.info(file_path)
        audio_format = audio_info.format
        audio_subtype = audio_info.subtype

        subtype_to_bit_depth = {            "PCM_16": 16,
            "PCM_24": 24,
            "PCM_32": 32,
            "FLOAT": 32,
            "DOUBLE": 64,
        }

        bit_depth = subtype_to_bit_depth.get(audio_info.subtype)
    except Exception:
        pass

    technical_metrics = {
        "loudness": {            "lufs_integrated": (                round(lufs_integrated, 2)
                if lufs_integrated is not None and np.isfinite(lufs_integrated)
                else None
            ),
            "lufs_short_term": lufs_short_term_values,
            "lufs_momentary": lufs_momentary_values,
        },
        "peaks": {            "true_peak_dbtp": (
                round(true_peak_dbtp, 2)
                if true_peak_dbtp is not None and np.isfinite(true_peak_dbtp)
                else None
            ),
            "true_peak_linear": (
                round(true_peak_linear, 6)
                if true_peak_linear is not None
                else None
            ),
            "max_peak_dbfs": (
                round(peak_dbfs, 2)
                if np.isfinite(peak_dbfs)
                else None
            ),
            "max_peak_linear": round(max_abs_peak, 6),
        },
        "dynamics": {
            "rms_dbfs": (
                round(rms_dbfs, 2)
                if np.isfinite(rms_dbfs)
                else None
            ),
            "rms_linear": round(rms_linear, 6),
            "crest_factor_db": (
                round(crest_factor_db, 2)
                if crest_factor_db is not None
                else None
            ),
            "crest_factor_linear": (
                round(crest_factor_linear, 4)
                if crest_factor_linear is not None
                else None
            ),
        },
        "audio_properties": {
            "duration": {
                "minutes": minutes,
                "seconds": seconds,
                "total_seconds": duration_seconds,
                "total_seconds_float": round(duration_seconds_float, 3),
                "formatted": f"{minutes}:{seconds:02d}",
            },
            "sample_rate": int(sample_rate),
            "channels": int(channels),
            "bit_depth": bit_depth,
            "format": audio_format,
            "subtype": audio_subtype,
        },
        "clipping": {
            "clipping_detected": clipping_detected,
            "clipped_samples": clipped_samples,
            "total_samples": total_samples,
            "clipping_percentage": round(clipping_percentage, 6),
            "threshold": clipping_threshold,
        },
        "headroom": {
            "headroom_db": (
                round(headroom_db, 2)
                if headroom_db is not None and np.isfinite(headroom_db)
                else None
            ),
            "based_on": "max_peak_dbfs",
        },
    }

    return technical_metrics


def calculate_window_loudness(
    audio: np.ndarray,
    sample_rate: int,
    meter: pyln.Meter,
    window_seconds: float,
    hop_seconds: float,
) -> list[dict]:
    values = []

    window_samples = int(window_seconds * sample_rate)
    hop_samples = int(hop_seconds * sample_rate)

    if len(audio) < window_samples:
        return values

    for start in range(
        0,
        len(audio) - window_samples + 1,
        hop_samples,
    ):
        chunk = audio[start:start + window_samples]

        try:
            value = float(meter.integrated_loudness(chunk))

            if np.isfinite(value):
                values.append(
                    {
                        "start_seconds": round(start / sample_rate, 3),
                        "end_seconds": round(
                            (start + window_samples) / sample_rate,
                            3,
                        ),
                        "lufs": round(value, 2),
                    }
                )

        except Exception:
            continue

    return values