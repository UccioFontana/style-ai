import json
import os

from openai import OpenAI

def generate_mix_ai_review(technical_metrics: dict) -> dict:
    api_key = os.getenv("OPENAI_API_KEY")
    model = os.getenv("OPENAI_MODEL", "gpt-4o-mini")

    if not api_key:
        return {
            "status": "skipped",
            "reason": "OPENAI_API_KEY non configurata.",
            "text": None,
        }

    client = OpenAI(api_key=api_key)

    prompt = build_mix_review_prompt(technical_metrics)

    try:
        response = client.chat.completions.create(
            model=model,
            temperature=0.3,
            messages=[
                {
                    "role": "system",
                    "content": (
                        "Sei un mixing engineer esperto. "
                        "Analizzi metriche tecniche audio e produci conclusioni pratiche, "
                        "chiare e utili per migliorare un mix musicale. "
                        "Rispondi sempre in italiano. "
                        "Non inventare valori non presenti. "
                        "Se un dato è mancante, dichiaralo chiaramente."
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

def build_mix_review_prompt(technical_metrics: dict) -> str:
    metrics_json = json.dumps(
        technical_metrics,
        indent=2,
        ensure_ascii=False,
    )

    return f"""
Analizza queste metriche tecniche di un file audio e produci una valutazione del mix.

Metriche:
{metrics_json}

Voglio una risposta testuale strutturata così:

1. Valutazione generale del mix
2. Loudness
3. Picchi, true peak e headroom
4. Dinamica, RMS e crest factor
5. Clipping
6. Possibili problemi tecnici
7. Consigli pratici di miglioramento

Regole:
- Usa un linguaggio chiaro.
- Non essere troppo prolisso.
- Non dare per certo ciò che non si può dedurre dai dati.
- Se il mix sembra troppo compresso, dillo.
- Se il mix sembra avere poco headroom, dillo.
- Se il true peak è vicino o sopra 0 dBTP, segnala rischio clipping/inter-sample peak.
- Se ci sono dati non disponibili, evidenzialo.
"""