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
                        "Stai valutando una produzione già finita, caricata dall'utente per ricevere un parere finale. "
                        "Devi dare un giudizio professionale, strategico e utile: cosa funziona, cosa rischia di compromettere il risultato, "
                        "e quali interventi pratici fare prima della release. "
                        "Usa solo i dati forniti. Non inventare valori. Non essere generico. "
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

def build_mix_review_prompt(compact_analysis: dict) -> str:
    analysis_json = json.dumps(
        compact_analysis,
        indent=2,
        ensure_ascii=False,
    )

    return f"""
Valuta questa produzione audio già finalizzata o quasi finalizzata.

L'utente ha caricato il brano per capire se il mix/master è pronto, se ci sono rischi tecnici e quali interventi conviene fare prima della release.

DATI:
{analysis_json}

Produci una review professionale, breve e strategica.

Formato obbligatorio:

## Giudizio finale

Scrivi 2-3 frasi.
Devi dire chiaramente se il brano sembra:
- pronto;
- quasi pronto con correzioni leggere;
- da rivedere prima della release.

Motiva il giudizio usando i dati principali.

## Evidenze tecniche

Elenca 5-8 bullet point massimo.
Ogni bullet deve contenere un dato numerico o uno status reale.
Esempio:
- True Peak: -0.3 dBTP, vicino al limite.
- Low-end: 42.3%, quindi piuttosto dominante.
- Clipping: assente.

## Cosa funziona

Massimo 3 bullet point.
Indica solo aspetti positivi supportati dai dati.
Non fare complimenti generici.

## Cosa sistemare

Massimo 3 bullet point.
Per ogni punto indica:
- problema;
- dato che lo dimostra;
- impatto sul risultato finale.

## Interventi consigliati

Massimo 5 bullet point.
Devono essere azioni pratiche da mixing/mastering engineer.
Ogni consiglio deve dire dove intervenire e perché.
Esempi:
- Abbassa il limiter ceiling a -1.0 dBTP se il true peak è troppo vicino a 0.
- Controlla 20-60 Hz su kick/basso se il sub è alto.
- Usa EQ dinamica sul low-end se il basso domina solo in alcuni momenti.
- Valuta un boost controllato tra 5-10 kHz se high/air sono bassi.
- Verifica il mix su speaker piccoli se il low-end è dominante.

## Priorità prima della release

Scrivi massimo 3 priorità numerate.
Devono essere ordinate dalla più importante alla meno importante.

Regole:
- Non superare 450 parole.
- Non scrivere introduzioni.
- Non spiegare cosa sono LUFS, RMS, crest factor o true peak.
- Non essere didattico.
- Non essere vago.
- Non proporre dieci alternative.
- Non dire "potrebbe" in modo generico: se sei incerto, spiega perché.
- Se la confidence è alta, sii diretto.
- Se la confidence è media o bassa, segnala cautela.
- Considera che l'utente ha già finito produzione, mix e master: dai consigli realistici da ultimo check, non da rifacimento completo.
"""