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
            temperature=0.15,
            max_tokens=900,
            messages=[
                {
                    "role": "system",
                    "content": (
                        "Sei un senior mixing/mastering engineer. "
                        "Stai valutando una produzione già finita, caricata dall'utente "
                        "per ricevere un parere finale prima della release. "
                        "Devi dare un giudizio professionale, strategico e utile: "
                        "cosa funziona, cosa rischia di compromettere il risultato, "
                        "e quali interventi pratici fare senza proporre rifacimenti "
                        "completi se non strettamente necessario. "
                        "Usa solo i dati forniti. Non inventare valori. "
                        "Non essere generico. "
                        "Il software indicato è solo un contesto operativo: "
                        "prima dai il consiglio tecnico, poi suggerisci eventualmente "
                        "strumenti compatibili. "
                        "Rispondi in italiano, in modo sintetico e operativo."
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
    softwareType = analysis.get("softwareType", "None")

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

    return {
        "filename": analysis.get("filename"),
        "context": {
            "softwareType": softwareType,
            "software": get_software_context(softwareType),
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

def get_software_context(softwareType: str) -> dict:
    contexts = {
        "None": {
            "label": "software non specificato",
            "native_tools": {},
            "notes": [
                "Fornisci consigli DAW-agnostic.",
                "Usa categorie generiche: EQ, EQ dinamica, compressore, multibanda, limiter, metering e gain staging.",
                "Non nominare plugin specifici.",
            ],
        },
        "LogicPro": {
            "label": "Logic Pro",
            "native_tools": {
                "eq": ["Channel EQ", "Linear Phase EQ"],
                "compression": ["Compressor"],
                "multiband": ["Multipressor"],
                "limiting": ["Limiter", "Adaptive Limiter"],
                "metering": ["Loudness Meter"],
            },
            "notes": [
                "Preferisci strumenti nativi solo se coerenti con il problema rilevato.",
                "Non forzare un tool specifico se basta gain staging, EQ o ascolto comparativo.",
            ],
        },
        "AbletonLive": {
            "label": "Ableton Live",
            "native_tools": {
                "eq": ["EQ Eight"],
                "utility": ["Utility"],
                "compression": ["Compressor", "Glue Compressor"],
                "multiband": ["Multiband Dynamics"],
                "limiting": ["Limiter"],
                "metering": ["Spectrum"],
            },
            "notes": [
                "Usa tool nativi solo quando aiutano a tradurre meglio il consiglio tecnico.",
                "Utility può essere utile per gain, mono compatibility e controllo del low-end.",
            ],
        },
        "FLStudio": {
            "label": "FL Studio",
            "native_tools": {
                "eq": ["Parametric EQ 2"],
                "compression": ["Fruity Compressor"],
                "multiband": ["Maximus"],
                "limiting": ["Fruity Limiter"],
                "metering": ["Wave Candy"],
            },
            "notes": [
                "Usa strumenti nativi solo se coerenti con il problema rilevato.",
                "Maximus è utile solo quando serve controllo multibanda, non come soluzione generica.",
            ],
        },
        "Cubase": {
            "label": "Cubase",
            "native_tools": {
                "eq": ["Frequency EQ"],
                "compression": ["Compressor"],
                "multiband": ["Multiband Compressor"],
                "limiting": ["Limiter"],
                "metering": ["SuperVision"],
            },
            "notes": [
                "Frequency EQ può essere suggerito per interventi correttivi o dinamici se coerente con il problema.",
                "SuperVision può essere usato per verificare loudness, spettro e fase.",
            ],
        },
        "ProTools": {
            "label": "Pro Tools",
            "native_tools": {
                "eq": ["EQ III"],
                "compression": ["Dyn3 Compressor/Limiter"],
                "gain": ["Clip Gain"],
                "routing": ["Bus routing"],
                "metering": ["Metering plugin"],
            },
            "notes": [
                "Dai priorità a gain staging, clip gain e controllo sui bus quando il problema riguarda livelli o headroom.",
                "Non forzare processing sul master se è più sensato intervenire sui bus.",
            ],
        },
        "StudioOne": {
            "label": "Studio One",
            "native_tools": {
                "eq": ["Pro EQ"],
                "compression": ["Compressor"],
                "multiband": ["Multiband Dynamics"],
                "limiting": ["Limiter"],
                "metering": ["Level Meter"],
            },
            "notes": [
                "Preferisci tool nativi solo se coerenti con il dato analizzato.",
                "Non suggerire processing pesante se il problema è risolvibile con gain staging o micro-correzioni.",
            ],
        },
        "Reaper": {
            "label": "REAPER",
            "native_tools": {
                "eq": ["ReaEQ"],
                "compression": ["ReaComp"],
                "multiband": ["ReaXcomp"],
                "limiting": ["Limiter plugin"],
                "metering": ["JS analyzers"],
            },
            "notes": [
                "Suggerisci strumenti Rea solo se aiutano davvero a eseguire l'intervento tecnico.",
                "Mantieni i consigli compatibili con un workflow flessibile e DAW-agnostic.",
            ],
        },
        "GarageBand": {
            "label": "GarageBand",
            "native_tools": {
                "eq": ["Visual EQ"],
                "compression": ["Compressor"],
                "limiting": ["Limiter"],
                "metering": [],
            },
            "notes": [
                "Dai consigli semplici e applicabili con strumenti essenziali.",
                "Evita workflow troppo complessi o da mastering avanzato.",
            ],
        },
        "Reason": {
            "label": "Reason",
            "native_tools": {
                "eq": ["Channel EQ", "MClass Equalizer"],
                "compression": ["MClass Compressor"],
                "multiband": [],
                "limiting": ["MClass Maximizer"],
                "metering": ["Spectrum EQ", "meters"],
            },
            "notes": [
                "Suggerisci interventi compatibili con rack e channel strip.",
                "Preferisci correzioni mirate su sorgenti o bus prima del master.",
            ],
        },
        "BitwigStudio": {
            "label": "Bitwig Studio",
            "native_tools": {
                "eq": ["EQ+", "EQ-5"],
                "compression": ["Compressor"],
                "multiband": ["Multiband FX"],
                "limiting": ["Peak Limiter"],
                "metering": ["Spectrum Analyzer"],
            },
            "notes": [
                "Usa strumenti modulari solo se realmente utili al problema rilevato.",
                "Mantieni i consigli orientati a micro-correzioni finali.",
            ],
        },
        "Cakewalk": {
            "label": "Cakewalk",
            "native_tools": {
                "eq": ["ProChannel EQ"],
                "compression": ["ProChannel Compressor"],
                "multiband": [],
                "limiting": ["Limiter"],
                "metering": ["Metering tools"],
            },
            "notes": [
                "Suggerisci interventi compatibili con ProChannel quando utile.",
                "Dai priorità a EQ, gain staging e controllo del master bus.",
            ],
        },
        "DigitalPerformer": {
            "label": "Digital Performer",
            "native_tools": {
                "eq": ["MasterWorks EQ"],
                "compression": ["MasterWorks Compressor"],
                "multiband": [],
                "limiting": ["MasterWorks Limiter"],
                "metering": ["Metering tools"],
            },
            "notes": [
                "Mantieni i consigli tecnici e non eccessivamente plugin-specific.",
                "Suggerisci tool nativi solo se coerenti con il problema.",
            ],
        },
        "Sonar": {
            "label": "Sonar",
            "native_tools": {
                "eq": ["ProChannel EQ"],
                "compression": ["ProChannel Compressor"],
                "multiband": [],
                "limiting": ["Limiter"],
                "metering": ["Metering tools"],
            },
            "notes": [
                "Suggerisci interventi compatibili con ProChannel quando utile.",
                "Evita consigli troppo legati a plugin esterni.",
            ],
        },
        "Tracktion": {
            "label": "Tracktion",
            "native_tools": {
                "eq": ["EQ"],
                "compression": ["Compressor"],
                "multiband": [],
                "limiting": ["Limiter"],
                "metering": ["Metering tools"],
            },
            "notes": [
                "Dai consigli DAW-agnostic con riferimento a strumenti nativi generici.",
                "Non forzare nomi di plugin se non necessari.",
            ],
        },
        "Ardour": {
            "label": "Ardour",
            "native_tools": {
                "eq": ["ACE EQ"],
                "compression": ["ACE Compressor"],
                "multiband": [],
                "limiting": ["Limiter"],
                "metering": ["Metering tools"],
            },
            "notes": [
                "Mantieni i consigli compatibili con strumenti nativi o generici.",
                "Non suggerire plugin commerciali esterni.",
            ],
        },
        "Mixcraft": {
            "label": "Mixcraft",
            "native_tools": {
                "eq": ["EQ"],
                "compression": ["Compressor"],
                "multiband": [],
                "limiting": ["Limiter"],
                "metering": ["Metering tools"],
            },
            "notes": [
                "Dai consigli semplici, chiari e applicabili con strumenti standard.",
                "Evita catene di mastering complesse.",
            ],
        },
        "Samplitude": {
            "label": "Samplitude",
            "native_tools": {
                "eq": ["Equalizer"],
                "compression": ["Compressor"],
                "multiband": ["Multiband Dynamics"],
                "limiting": ["Limiter"],
                "metering": ["Metering tools"],
            },
            "notes": [
                "Suggerisci interventi sul master o sugli oggetti audio solo se coerenti.",
                "Mantieni il focus su correzioni finali mirate.",
            ],
        },
        "Nuendo": {
            "label": "Nuendo",
            "native_tools": {
                "eq": ["Frequency EQ"],
                "compression": ["Compressor"],
                "multiband": ["Multiband Compressor"],
                "limiting": ["Limiter"],
                "metering": ["SuperVision"],
            },
            "notes": [
                "Nuendo condivide molti strumenti con Cubase: usa riferimenti compatibili.",
                "Suggerisci tool nativi solo se coerenti con il dato analizzato.",
            ],
        },
        "Other": {
            "label": "software non specificato",
            "native_tools": {},
            "notes": [
                "Fornisci consigli DAW-agnostic.",
                "Usa categorie generiche: EQ, EQ dinamica, compressore, multibanda, limiter, metering e gain staging.",
                "Non nominare plugin specifici.",
            ],
        },
    }

    return contexts.get(softwareType, contexts["Other"])

def build_mix_review_prompt(compact_analysis: dict) -> str:
    software = compact_analysis.get("context", {}).get("software", {})
    software_label = software.get("label", "software non specificato")

    analysis_json = json.dumps(
        compact_analysis,
        indent=2,
        ensure_ascii=False,
    )

    return f"""
Valuta questa produzione audio già finalizzata o quasi finalizzata.

L'utente ha caricato il brano per capire se il mix/master è pronto, se ci sono rischi tecnici e quali micro-interventi conviene fare prima della release.

Software indicato: {software_label}

Il software è solo un contesto operativo.
Non partire dal software: parti sempre dai dati audio.
Se suggerisci un tool, deve essere coerente con context.software.native_tools.
Se il software è non specificato, usa solo categorie generiche e non nominare plugin specifici.

DATI:
{analysis_json}

Formato obbligatorio:

## Giudizio finale

2-3 frasi massimo.
Dì chiaramente se il brano sembra:
- pronto;
- quasi pronto con correzioni leggere;
- da rivedere prima della release.

Motiva il giudizio con 2-3 dati reali.

## Evidenze tecniche

5-8 bullet point massimo.
Ogni bullet deve contenere un dato numerico o uno status reale.
Non commentare ogni dato: seleziona solo quelli decisivi.

## Cosa funziona

Massimo 3 bullet point.
Solo punti positivi supportati dai dati.

## Cosa sistemare

Massimo 3 bullet point.
Per ogni punto indica:
- problema;
- dato che lo dimostra;
- impatto sul risultato finale.

## Interventi consigliati in {software_label}

Massimo 5 bullet point.
Ogni bullet deve seguire questo schema:
- Azione tecnica concreta.
- Area/frequenza/processo su cui intervenire.
- Motivo dell'intervento.
- Eventuale tool compatibile dal context, solo se utile.

Esempio di stile:
- Controlla il sub tra 20-60 Hz sugli elementi che generano low-end, evitando tagli aggressivi sul master; se serve, usa un EQ nativo compatibile indicato nel context.
- Se il true peak è vicino a 0 dBTP, abbassa il ceiling del limiter finale e ricontrolla loudness e headroom.
- Se high/air sono bassi, valuta un'apertura controllata sulle sorgenti brillanti o sul bus, evitando boost generici sul master.

## Priorità prima della release

Massimo 3 priorità numerate.
Devono essere ordinate dalla più importante alla meno importante.

Regole:
- Non superare 450 parole.
- Non scrivere introduzioni.
- Non spiegare cosa sono LUFS, RMS, crest factor o true peak.
- Non essere didattico.
- Non essere vago.
- Non proporre dieci alternative.
- Non inventare plugin, funzioni o strumenti non presenti nel context.
- Non suggerire di cambiare DAW.
- Non suggerire plugin esterni a pagamento.
- Non proporre un remix completo se bastano correzioni da final check.
- Non dire "potrebbe" in modo generico: se sei incerto, spiega perché.
- Se la confidence è alta, sii diretto.
- Se la confidence è media o bassa, segnala cautela.
"""