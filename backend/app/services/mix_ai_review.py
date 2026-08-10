import json
import os

from openai import OpenAI

def generate_mix_ai_review(analysis: dict) -> dict:
    api_key = os.getenv("OPENAI_API_KEY")
    model = os.getenv("OPENAI_MODEL", "gpt-4o-mini")

    if not api_key:
        return {
            "status": "skipped",
            "reason": "OPENAI_API_KEY non configurata.",
            "text": None,
        }

    client = OpenAI(api_key=api_key)

    compact_analysis = build_compact_analysis(analysis)
    prompt = build_mix_review_prompt(compact_analysis)

    try:
        response = client.chat.completions.create(
            model=model,
            temperature=0.1,
            max_tokens=1200,
            messages=[
                {
                    "role": "system",
                    "content": (
                        "Sei un senior mixing/mastering engineer. "
                        "Valuti brani già prodotti, mixati e masterizzati, caricati per un ultimo parere prima della release. "
                        "Devi dare feedback professionale, concreto, strategico e non dispersivo. "
                        "Usa solo i dati forniti e la pre-diagnosi. "
                        "Non inventare valori, strumenti o plugin. "
                        "Non proporre rifacimenti completi se bastano micro-correzioni da final check. "
                        "Il feeling indicato dall'utente è l'obiettivo estetico. "
                        "La lista strumenti serve per rendere i consigli più specifici. "
                        "Il software è solo un contesto operativo: prima spiega il problema tecnico, poi eventualmente cita un tool compatibile. "
                        "Rispondi sempre in italiano."
                    ),
                },
                {
                    "role": "user",
                    "content": prompt,
                },
            ],
        )

        text = response.choices[0].message.content

        return {
            "status": "completed",
            "text": text,
        }

    except Exception as e:
        return {
            "status": "failed",
            "reason": str(e),
            "text": None,
        }

def build_compact_analysis(analysis: dict) -> dict:
    technical = analysis.get("technical_metrics", {})
    frequency = analysis.get("frequency_analysis", {})

    software_type = normalize_software_type(
        analysis.get("softwareType", "None")
    )

    raw_feeling = analysis.get("feeling", {})
    raw_instruments = analysis.get("instruments", [])

    loudness = technical.get("loudness", {})
    peaks = technical.get("peaks", {})
    dynamics = technical.get("dynamics", {})
    clipping = technical.get("clipping", {})
    headroom = technical.get("headroom", {})
    audio_properties = technical.get("audio_properties", {})

    bands = frequency.get("bands", {})
    overall = frequency.get("overall", {})
    quality = frequency.get("quality", {})
    warnings = frequency.get("warnings", [])

    compact = {
        "filename": analysis.get("filename"),
        "context": {
            "softwareType": software_type,
            "software": get_software_context(software_type),
        },
        "user_feedback": {
            "feeling": build_feeling_context(raw_feeling),
            "instruments": build_instruments_context(raw_instruments),
        },
        "technical": {
            "duration": audio_properties.get("duration", {}).get("formatted"),
            "sample_rate": audio_properties.get("sample_rate"),
            "bit_depth": audio_properties.get("bit_depth"),
            "lufs_integrated": loudness.get("lufs_integrated"),
            "true_peak_dbtp": peaks.get("true_peak_dbtp"),
            "max_peak_dbfs": peaks.get("max_peak_dbfs"),
            "rms_dbfs": dynamics.get("rms_dbfs"),
            "crest_factor_db": dynamics.get("crest_factor_db"),
            "headroom_db": headroom.get("headroom_db"),
            "clipping_detected": clipping.get("clipping_detected"),
            "clipped_samples": clipping.get("clipped_samples"),
        },
        "tonal_balance": {
            "tonal_profile": overall.get("tonal_profile"),
            "dominant_band": overall.get("dominant_band"),
            "spectral_centroid_hz": overall.get("spectral_centroid_hz"),
            "low_end_percent": overall.get("low_end_percent"),
            "low_mid_percent": overall.get("low_mid_percent"),
            "high_end_percent": overall.get("high_end_percent"),
            "bands": build_compact_bands(bands),
            "warnings": warnings,
        },
        "analysis_quality": {
            "confidence_score": quality.get("confidence_score"),
            "confidence_label": quality.get("confidence_label"),
            "reasons": quality.get("reasons"),
        },
    }

    compact["pre_diagnosis"] = build_pre_diagnosis(compact)

    return compact

def normalize_software_type(value: str) -> str:
    if not value:
        return "None"

    normalized = str(value).strip()

    if "." in normalized:
        normalized = normalized.split(".")[-1]

    compact = (
        normalized
        .replace(" ", "")
        .replace("-", "")
        .replace("_", "")
        .lower()
    )

    aliases = {
        "none": "None",
        "logicpro": "LogicPro",
        "abletonlive": "AbletonLive",
        "flstudio": "FLStudio",
        "cubase": "Cubase",
        "protools": "ProTools",
        "studioone": "StudioOne",
        "reaper": "Reaper",
        "garageband": "GarageBand",
        "reason": "Reason",
        "bitwigstudio": "BitwigStudio",
        "cakewalk": "Cakewalk",
        "digitalperformer": "DigitalPerformer",
        "sonar": "Sonar",
        "tracktion": "Tracktion",
        "ardour": "Ardour",
        "mixcraft": "Mixcraft",
        "samplitude": "Samplitude",
        "nuendo": "Nuendo",
        "other": "Other",
    }

    return aliases.get(compact, "Other")

def build_compact_bands(bands: dict) -> dict:
    compact_bands = {}

    for band_key, band_data in bands.items():
        compact_bands[band_key] = {
            "label": band_data.get("label"),
            "range_hz": band_data.get("range_hz"),
            "energy_percent": band_data.get("energy_percent"),
            "status": band_data.get("status"),
            "avg_db": band_data.get("avg_db"),
            "p50_db": band_data.get("p50_db"),
            "p90_db": band_data.get("p90_db"),
        }

    return compact_bands

def build_feeling_context(feeling: dict) -> dict:
    if not isinstance(feeling, dict) or not feeling:
        return {
            "available": False,
            "values": {},
            "dominant_traits": [],
            "low_traits": [],
            "intent": [],
        }

    fields = [
        "warmth",
        "brightness",
        "intimacy",
        "aggression",
        "processing",
        "instrumental",
    ]

    values = {
        field: normalize_feeling_value(feeling.get(field))
        for field in fields
    }

    dominant_traits = [
        key
        for key, value in values.items()
        if value >= 0.66
    ]

    low_traits = [
        key
        for key, value in values.items()
        if value <= 0.33
    ]

    return {
        "available": True,
        "scale": "0.0 = basso / 1.0 = alto",
        "values": values,
        "dominant_traits": dominant_traits,
        "low_traits": low_traits,
        "intent": build_feeling_intent(values),
    }

def normalize_feeling_value(value) -> float:
    if value is None:
        return 0.0

    try:
        numeric_value = float(value)
    except Exception:
        return 0.0

    if numeric_value > 10:
        numeric_value = numeric_value / 100

    elif numeric_value > 1:
        numeric_value = numeric_value / 10

    numeric_value = max(0.0, min(1.0, numeric_value))

    return round(numeric_value, 2)

def build_feeling_intent(values: dict) -> list[str]:
    intent = []

    if values.get("warmth", 0.0) >= 0.66:
        intent.append("calore, corpo e morbidezza")

    if values.get("brightness", 0.0) >= 0.66:
        intent.append("brillantezza, apertura e presenza sugli alti")

    if values.get("intimacy", 0.0) >= 0.66:
        intent.append("intimità, naturalezza e vicinanza percepita")

    if values.get("aggression", 0.0) >= 0.66:
        intent.append("impatto, punch e aggressività controllata")

    if values.get("processing", 0.0) >= 0.66:
        intent.append("suono moderno e processato")

    if values.get("instrumental", 0.0) >= 0.66:
        intent.append("centralità della componente strumentale")

    if not intent:
        intent.append("feeling equilibrato senza priorità estetiche estreme")

    return intent

def build_instruments_context(instruments: list[str]) -> dict:
    if not isinstance(instruments, list) or not instruments:
        return {
            "available": False,
            "items": [],
            "counts": {},
            "families": {},
            "notes": [],
        }

    normalized_items = [
        normalize_instrument_name(item)
        for item in instruments
        if isinstance(item, str) and item.strip()
    ]

    counts = {}

    for item in normalized_items:
        counts[item] = counts.get(item, 0) + 1

    families = build_instrument_families(counts)

    return {
        "available": True,
        "items": normalized_items,
        "counts": counts,
        "families": families,
        "notes": build_instrument_notes(families),
    }

def normalize_instrument_name(instrument: str) -> str:
    normalized = instrument.strip().lower()

    aliases = {
        "voce": "vocal",
        "voci": "vocal",
        "vocal": "vocal",
        "vocals": "vocal",
        "lead vocal": "lead_vocal",
        "backing vocals": "backing_vocals",
        "piano": "piano",
        "chitarra": "guitar",
        "chitarre": "guitar",
        "guitar": "guitar",
        "electric guitar": "electric_guitar",
        "acoustic guitar": "acoustic_guitar",
        "basso": "bass",
        "bass": "bass",
        "synth bass": "synth_bass",
        "batteria": "drums",
        "drums": "drums",
        "kick": "kick",
        "snare": "snare",
        "hi hat": "hi_hat",
        "hihat": "hi_hat",
        "percussioni": "percussion",
        "percussion": "percussion",
        "keys": "keys",
        "tastiere": "keys",
        "synth": "synth",
        "pad": "pad",
        "strings": "strings",
        "archi": "strings",
        "brass": "brass",
        "fiati": "brass",
    }

    if normalized in aliases:
        return aliases[normalized]

    return (
        normalized
        .replace(" ", "_")
        .replace("-", "_")
    )

def build_instrument_families(counts: dict) -> dict:
    families = {
        "vocals": 0,
        "guitars": 0,
        "bass": 0,
        "drums": 0,
        "percussion": 0,
        "keys_synths": 0,
        "orchestral": 0,
        "other": 0,
    }

    for instrument, count in counts.items():
        if "vocal" in instrument:
            families["vocals"] += count

        elif "guitar" in instrument:
            families["guitars"] += count

        elif "bass" in instrument:
            families["bass"] += count

        elif instrument in ["drums", "kick", "snare", "hi_hat"]:
            families["drums"] += count

        elif instrument == "percussion":
            families["percussion"] += count

        elif instrument in ["piano", "keys", "synth", "pad"]:
            families["keys_synths"] += count

        elif instrument in ["strings", "brass"]:
            families["orchestral"] += count

        else:
            families["other"] += count

    return {
        key: value
        for key, value in families.items()
        if value > 0
    }

def build_instrument_notes(families: dict) -> list[str]:
    notes = []

    if families.get("vocals", 0) > 0:
        notes.append(
            "Sono presenti voci: valuta intelligibilità, presence, dinamica e spazio rispetto agli strumenti."
        )

    if families.get("guitars", 0) >= 2:
        notes.append(
            "Sono presenti più chitarre: valuta stereo placement, masking nel midrange e harshness."
        )

    elif families.get("guitars", 0) == 1:
        notes.append(
            "È presente una chitarra: valuta corpo, presence e harshness se il midrange è critico."
        )

    if families.get("bass", 0) > 0 and families.get("drums", 0) > 0:
        notes.append(
            "Sono presenti basso e batteria: valuta rapporto kick/basso e controllo 40-120 Hz."
        )

    elif families.get("bass", 0) > 0:
        notes.append(
            "È presente un basso: collega eventuali problemi di low-end alla gestione del basso."
        )

    if families.get("keys_synths", 0) > 0:
        notes.append(
            "Sono presenti piano/keys/synth: valuta corpo, masking e ruolo nel midrange."
        )

    return notes

def build_pre_diagnosis(compact_analysis: dict) -> dict:
    technical = compact_analysis.get("technical", {})
    tonal = compact_analysis.get("tonal_balance", {})
    feedback = compact_analysis.get("user_feedback", {})
    feeling = feedback.get("feeling", {})
    instruments = feedback.get("instruments", {})
    quality = compact_analysis.get("analysis_quality", {})

    technical_risks = build_technical_risks(technical)
    tonal_risks = build_tonal_risks(tonal)
    feeling_alignment = build_feeling_alignment(
        feeling=feeling,
        tonal=tonal,
        technical=technical,
    )
    likely_focus_areas = build_likely_focus_areas(
        technical_risks=technical_risks,
        tonal_risks=tonal_risks,
        feeling_alignment=feeling_alignment,
        instruments=instruments,
    )

    readiness = estimate_release_readiness(
        technical_risks=technical_risks,
        tonal_risks=tonal_risks,
        quality=quality,
    )

    return {
        "release_readiness": readiness,
        "technical_risks": technical_risks,
        "tonal_risks": tonal_risks,
        "feeling_alignment": feeling_alignment,
        "likely_focus_areas": likely_focus_areas,
        "review_strategy": build_review_strategy(readiness),
    }

def build_technical_risks(technical: dict) -> list[dict]:
    risks = []

    true_peak = technical.get("true_peak_dbtp")
    headroom = technical.get("headroom_db")
    clipping_detected = technical.get("clipping_detected")
    clipped_samples = technical.get("clipped_samples")
    crest_factor = technical.get("crest_factor_db")
    lufs = technical.get("lufs_integrated")

    if clipping_detected is True:
        risks.append({
            "level": "high",
            "code": "clipping_detected",
            "message": f"Clipping rilevato: {clipped_samples} campioni clipped.",
        })

    if true_peak is not None:
        if true_peak >= 0:
            risks.append({
                "level": "high",
                "code": "true_peak_over_zero",
                "message": f"True Peak a {true_peak} dBTP: rischio tecnico elevato prima della release.",
            })
        elif true_peak > -0.3:
            risks.append({
                "level": "medium",
                "code": "true_peak_tight",
                "message": f"True Peak a {true_peak} dBTP: margine molto ridotto.",
            })

    if headroom is not None:
        if headroom <= 0.2:
            risks.append({
                "level": "high",
                "code": "very_low_headroom",
                "message": f"Headroom a {headroom} dB: margine quasi assente.",
            })
        elif headroom <= 0.8:
            risks.append({
                "level": "medium",
                "code": "low_headroom",
                "message": f"Headroom a {headroom} dB: margine limitato.",
            })

    if crest_factor is not None:
        if crest_factor < 6:
            risks.append({
                "level": "medium",
                "code": "low_crest_factor",
                "message": f"Crest Factor a {crest_factor} dB: possibile densità/compressione elevata.",
            })

    if lufs is not None:
        if lufs > -7:
            risks.append({
                "level": "medium",
                "code": "very_loud_master",
                "message": f"LUFS integrated a {lufs}: master potenzialmente molto spinto.",
            })

    return risks

def build_tonal_risks(tonal: dict) -> list[dict]:
    risks = []

    tonal_profile = tonal.get("tonal_profile")
    low_end = tonal.get("low_end_percent")
    low_mid = tonal.get("low_mid_percent")
    high_end = tonal.get("high_end_percent")
    bands = tonal.get("bands", {})

    if tonal_profile:
        profile = str(tonal_profile).lower()

        if "muddy" in profile:
            risks.append({
                "level": "medium",
                "code": "muddy_profile",
                "message": f"Profilo tonale '{tonal_profile}': rischio di mix poco definito.",
            })

        if "dark" in profile:
            risks.append({
                "level": "low",
                "code": "dark_profile",
                "message": f"Profilo tonale '{tonal_profile}': carattere scuro da verificare rispetto al feeling.",
            })

        if "bright" in profile:
            risks.append({
                "level": "low",
                "code": "bright_profile",
                "message": f"Profilo tonale '{tonal_profile}': brillantezza da verificare rispetto al feeling.",
            })

    if low_end is not None and low_end >= 40:
        risks.append({
            "level": "medium",
            "code": "dominant_low_end",
            "message": f"Low-end al {low_end}%: basse frequenze molto presenti.",
        })

    if low_mid is not None and low_mid >= 38:
        risks.append({
            "level": "medium",
            "code": "dominant_low_mid",
            "message": f"Low-mid al {low_mid}%: possibile accumulo di corpo/muddiness.",
        })

    if high_end is not None and high_end <= 3:
        risks.append({
            "level": "low",
            "code": "low_high_end",
            "message": f"High-end al {high_end}%: mix tendenzialmente poco aperto.",
        })

    for band_key, band_data in bands.items():
        status = band_data.get("status")

        if status == "high":
            risks.append({
                "level": "low",
                "code": f"{band_key}_high",
                "message": f"Banda {band_key} in stato high.",
            })

        if status == "low":
            risks.append({
                "level": "low",
                "code": f"{band_key}_low",
                "message": f"Banda {band_key} in stato low.",
            })

    return risks

def build_feeling_alignment(
    feeling: dict,
    tonal: dict,
    technical: dict,
) -> list[dict]:
    if not feeling.get("available"):
        return []

    values = feeling.get("values", {})

    warmth = values.get("warmth", 0.0)
    brightness = values.get("brightness", 0.0)
    intimacy = values.get("intimacy", 0.0)
    aggression = values.get("aggression", 0.0)
    processing = values.get("processing", 0.0)
    instrumental = values.get("instrumental", 0.0)

    low_mid = tonal.get("low_mid_percent")
    high_end = tonal.get("high_end_percent")
    tonal_profile = str(tonal.get("tonal_profile") or "").lower()
    true_peak = technical.get("true_peak_dbtp")
    headroom = technical.get("headroom_db")
    crest_factor = technical.get("crest_factor_db")

    alignment = []

    if warmth >= 0.66:
        if low_mid is not None and low_mid > 42:
            alignment.append({
                "status": "partial_conflict",
                "trait": "warmth",
                "message": "Il calore richiesto è presente come corpo/low-mid, ma rischia di diventare eccessivo o muddy.",
            })
        else:
            alignment.append({
                "status": "aligned",
                "trait": "warmth",
                "message": "Il calore richiesto può essere coerente se il low-mid resta controllato.",
            })

    if brightness <= 0.33:
        if high_end is not None and high_end <= 4:
            alignment.append({
                "status": "aligned",
                "trait": "brightness",
                "message": "La bassa brightness richiesta è coerente con un high-end contenuto e un carattere più scuro.",
            })
        else:
            alignment.append({
                "status": "partial_conflict",
                "trait": "brightness",
                "message": "L'utente non cerca molta brillantezza: eventuali boost sugli alti vanno evitati o limitati alla presence utile.",
            })

    elif brightness >= 0.66:
        if high_end is not None and high_end <= 4:
            alignment.append({
                "status": "conflict",
                "trait": "brightness",
                "message": "L'utente cerca brillantezza, ma l'high-end risulta contenuto.",
            })

    if intimacy >= 0.66:
        if true_peak is not None and true_peak >= 0:
            alignment.append({
                "status": "partial_conflict",
                "trait": "intimacy",
                "message": "L'intimità richiesta può essere penalizzata da un master troppo vicino al limite tecnico.",
            })
        elif headroom is not None and headroom <= 0.3:
            alignment.append({
                "status": "partial_conflict",
                "trait": "intimacy",
                "message": "L'intimità richiesta può soffrire se il limiting/headroom è troppo stretto.",
            })
        else:
            alignment.append({
                "status": "aligned",
                "trait": "intimacy",
                "message": "L'intimità richiesta suggerisce micro-correzioni trasparenti e non processing invasivo.",
            })

    if aggression <= 0.33:
        if crest_factor is not None and crest_factor < 6:
            alignment.append({
                "status": "partial_conflict",
                "trait": "aggression",
                "message": "L'utente non cerca aggressività, ma la densità dinamica potrebbe far percepire il master come troppo spinto.",
            })
        else:
            alignment.append({
                "status": "aligned",
                "trait": "aggression",
                "message": "La bassa aggressività richiesta orienta verso un master naturale e non eccessivamente compresso.",
            })

    if processing <= 0.33:
        alignment.append({
            "status": "preference",
            "trait": "processing",
            "message": "Il processing basso richiesto indica che gli interventi dovrebbero essere trasparenti e poco invasivi.",
        })

    if instrumental >= 0.66:
        alignment.append({
            "status": "preference",
            "trait": "instrumental",
            "message": "La centralità strumentale richiede attenzione a piano, armonie, corpo e chiarezza del midrange.",
        })

    if "dark" in tonal_profile and brightness <= 0.33:
        alignment.append({
            "status": "aligned",
            "trait": "tonal_character",
            "message": "Il carattere scuro del mix può essere coerente con la brightness bassa richiesta.",
        })

    return alignment

def build_likely_focus_areas(
    technical_risks: list[dict],
    tonal_risks: list[dict],
    feeling_alignment: list[dict],
    instruments: dict,
) -> list[str]:
    focus = []

    families = instruments.get("families", {})
    items = instruments.get("items", [])

    risk_codes = {
        risk.get("code")
        for risk in technical_risks + tonal_risks
    }

    if "true_peak_over_zero" in risk_codes or "true_peak_tight" in risk_codes:
        focus.append("limiter finale / ceiling / headroom")

    if "dominant_low_mid" in risk_codes or "muddy_profile" in risk_codes:
        if "piano" in items:
            focus.append("piano: controllo 180-350 Hz e gestione del corpo")
        if families.get("vocals", 0) > 0:
            focus.append("voce: intelligibilità e spazio rispetto al piano")
        focus.append("bus armonico / low-mid")

    if "low_high_end" in risk_codes:
        if families.get("vocals", 0) > 0:
            focus.append("voce: presence utile senza aumentare troppo l'air")
        if "piano" in items:
            focus.append("piano: attacco e definizione")
        focus.append("presence controllata")

    if families.get("vocals", 0) > 0 and "voce" not in focus:
        focus.append("voce: intelligibilità, dinamica e presenza")

    if families.get("keys_synths", 0) > 0:
        focus.append("piano/keys: corpo, masking e ruolo nel midrange")

    if not focus:
        focus.append("master bus: micro-correzioni, metering e traduzione")

    return list(dict.fromkeys(focus))

def estimate_release_readiness(
    technical_risks: list[dict],
    tonal_risks: list[dict],
    quality: dict,
) -> dict:
    high_risks = [
        risk
        for risk in technical_risks + tonal_risks
        if risk.get("level") == "high"
    ]

    medium_risks = [
        risk
        for risk in technical_risks + tonal_risks
        if risk.get("level") == "medium"
    ]

    confidence_label = quality.get("confidence_label")

    if high_risks:
        status = "da_rivedere_prima_della_release"
        explanation = "Sono presenti rischi tecnici importanti da correggere prima della release."

    elif len(medium_risks) >= 2:
        status = "quasi_pronto_con_correzioni_mirate"
        explanation = "Il brano sembra vicino alla release, ma alcune aree meritano correzioni mirate."

    elif medium_risks:
        status = "quasi_pronto_con_micro_correzioni"
        explanation = "Il brano sembra quasi pronto, con possibili micro-correzioni di final check."

    else:
        status = "pronto_o_quasi_pronto"
        explanation = "Non emergono rischi tecnici forti dai dati disponibili."

    if confidence_label and str(confidence_label).lower() in ["low", "bassa", "medium", "media"]:
        explanation += " La confidence non è massima, quindi il giudizio va letto con cautela."

    return {
        "status": status,
        "explanation": explanation,
        "high_risk_count": len(high_risks),
        "medium_risk_count": len(medium_risks),
    }

def build_review_strategy(readiness: dict) -> list[str]:
    status = readiness.get("status")

    if status == "da_rivedere_prima_della_release":
        return [
            "Sii diretto sui rischi tecnici.",
            "Dai priorità a correzioni su limiter, headroom, clipping o tonal balance.",
            "Evita consigli estetici secondari prima dei problemi tecnici.",
        ]

    if status in [
        "quasi_pronto_con_correzioni_mirate",
        "quasi_pronto_con_micro_correzioni",
    ]:
        return [
            "Imposta il feedback come final check.",
            "Suggerisci interventi piccoli, pratici e ordinati per impatto.",
            "Evita di proporre un remix completo.",
        ]

    return [
        "Conferma ciò che funziona.",
        "Suggerisci solo rifiniture leggere.",
        "Mantieni il focus sulla coerenza artistica e sulla traduzione finale.",
    ]

def get_software_context(software_type: str) -> dict:
    contexts = {
        "None": build_generic_software_context("software non specificato"),
        "Other": build_generic_software_context("software non specificato"),
        "LogicPro": build_generic_software_context(
            "Logic Pro",
            {
                "eq": ["Channel EQ", "Linear Phase EQ"],
                "compression": ["Compressor"],
                "multiband": ["Multipressor"],
                "limiting": ["Limiter", "Adaptive Limiter"],
                "metering": ["Loudness Meter"],
            },
        ),
        "AbletonLive": build_generic_software_context(
            "Ableton Live",
            {
                "eq": ["EQ Eight"],
                "utility": ["Utility"],
                "compression": ["Compressor", "Glue Compressor"],
                "multiband": ["Multiband Dynamics"],
                "limiting": ["Limiter"],
                "metering": ["Spectrum"],
            },
        ),
        "FLStudio": build_generic_software_context(
            "FL Studio",
            {
                "eq": ["Parametric EQ 2"],
                "compression": ["Fruity Compressor"],
                "multiband": ["Maximus"],
                "limiting": ["Fruity Limiter"],
                "metering": ["Wave Candy"],
            },
        ),
        "Cubase": build_generic_software_context(
            "Cubase",
            {
                "eq": ["Frequency EQ"],
                "compression": ["Compressor"],
                "multiband": ["Multiband Compressor"],
                "limiting": ["Limiter"],
                "metering": ["SuperVision"],
            },
        ),
        "ProTools": build_generic_software_context(
            "Pro Tools",
            {
                "eq": ["EQ III"],
                "compression": ["Dyn3 Compressor/Limiter"],
                "gain": ["Clip Gain"],
                "routing": ["Bus routing"],
            },
        ),
        "StudioOne": build_generic_software_context(
            "Studio One",
            {
                "eq": ["Pro EQ"],
                "compression": ["Compressor"],
                "multiband": ["Multiband Dynamics"],
                "limiting": ["Limiter"],
                "metering": ["Level Meter"],
            },
        ),
        "Reaper": build_generic_software_context(
            "REAPER",
            {
                "eq": ["ReaEQ"],
                "compression": ["ReaComp"],
                "multiband": ["ReaXcomp"],
            },
        ),
        "GarageBand": build_generic_software_context(
            "GarageBand",
            {
                "eq": ["Visual EQ"],
                "compression": ["Compressor"],
                "limiting": ["Limiter"],
            },
        ),
        "Reason": build_generic_software_context("Reason"),
        "BitwigStudio": build_generic_software_context("Bitwig Studio"),
        "Cakewalk": build_generic_software_context("Cakewalk"),
        "DigitalPerformer": build_generic_software_context("Digital Performer"),
        "Sonar": build_generic_software_context("Sonar"),
        "Tracktion": build_generic_software_context("Tracktion"),
        "Ardour": build_generic_software_context("Ardour"),
        "Mixcraft": build_generic_software_context("Mixcraft"),
        "Samplitude": build_generic_software_context("Samplitude"),
        "Nuendo": build_generic_software_context("Nuendo"),
    }

    return contexts.get(software_type, contexts["Other"])

def build_generic_software_context(
    label: str,
    native_tools: dict | None = None,
) -> dict:
    return {
        "label": label,
        "native_tools": native_tools or {},
    }

def build_mix_review_prompt(compact_analysis: dict) -> str:
    software = compact_analysis.get("context", {}).get("software", {})
    software_label = software.get("label", "software non specificato")

    analysis_json = json.dumps(
        compact_analysis,
        indent=2,
        ensure_ascii=False,
    )

    return f"""
Analizza questa produzione audio già mixata/masterizzata.

L'utente ha caricato un brano finito o quasi finito per ricevere un parere professionale prima della release.

Software indicato: {software_label}

Usa solo:
- dati tecnici;
- tonal balance;
- feeling desiderato;
- strumenti dichiarati;
- pre-diagnosi backend;
- software indicato.

La pre-diagnosi backend è un supporto decisionale: usala per dare priorità ai problemi, ma scrivi la review in modo naturale e professionale.

DATI:
{analysis_json}

OBIETTIVO:
Produrre un feedback utile per una persona che ha già finito produzione, mix e master.
Non fare un tutorial.
Non essere dispersivo.
Non proporre un remix completo se bastano micro-correzioni.

FORMATO OBBLIGATORIO:

## Giudizio completo

Scrivi un giudizio professionale di 7-10 righe.

Devi includere:
- se il brano sembra pronto, quasi pronto o da rivedere;
- il principale motivo tecnico;
- il principale motivo artistico;
- eventuali rischi su true peak, headroom, clipping, dinamica o tonal balance;
- coerenza tra mix attuale e feeling desiderato;
- tono prudente se la confidence non è alta.

Non usare elenco puntato in questa sezione.

## Feeling dato dal mix al momento

Scrivi 4-5 bullet point.

Ogni bullet deve collegare:
- un elemento del feeling desiderato;
- un dato tecnico o frequenziale;
- una conclusione concreta sul feeling reale del mix.

Se il mix risulta coerente con il feeling richiesto, dillo chiaramente.
Se c'è conflitto, spiega il conflitto.

## Punti di forza

Scrivi 3-4 bullet point.

Ogni punto deve essere supportato da:
- dato tecnico reale;
- assenza di un problema;
- coerenza tra dati, feeling e strumenti;
- buona direzione artistica deducibile dai dati.

Non scrivere complimenti generici.

## Cosa e come migliorare

Scrivi 4-5 bullet point.

Ogni bullet deve contenere:
- problema rilevato;
- dato che lo giustifica;
- dove intervenire, possibilmente su uno strumento dichiarato;
- come intervenire in modo pratico;
- perché migliora il risultato;
- eventuale tool nativo in {software_label}, solo se presente in context.software.native_tools e davvero utile.

REGOLE FINALI:
- Non superare 700 parole.
- Non inventare dati.
- Non inventare plugin.
- Non citare strumenti non presenti.
- Non spiegare cosa sono LUFS, RMS, crest factor o true peak.
- Non suggerire cambio DAW.
- Non suggerire plugin esterni a pagamento.
- Se un dato non è disponibile, non usarlo.
- Rispondi solo con le quattro sezioni richieste.
"""