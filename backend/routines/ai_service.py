import json
import os

import google.generativeai as genai


def generate_exercise_recommendations(user_profile, workout_history, available_exercises):
    """
    Uses Gemini API to generate exercise recommendations.
    """
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key or api_key == "tu_api_key_de_gemini_aqui":
        # Fallback for development if key is missing
        return _get_mock_recommendations(available_exercises)

    genai.configure(api_key=api_key)

    # Correct model path for v1beta API
    for model_name in ["models/gemini-1.5-flash", "models/gemini-pro"]:
        try:
            model = genai.GenerativeModel(model_name)
            break
        except Exception:  # nosec B112
            continue


    else:
        model = genai.GenerativeModel("gemini-pro")

    # Prepare data for prompt
    profile_str = f"Age: {user_profile.age}, Height: {user_profile.height}cm, Weight: {user_profile.weight}kg, Activity Level: {user_profile.activity_level}"

    history_str = "\n".join(
        [
            f"- {session.routine.title} on {session.date.strftime('%Y-%m-%d')}"
            for session in workout_history[:5]
        ]
    )

    # 1. Improve exercise context with muscle group
    exercises_list = ", ".join(
        [f"{ex.name} ({ex.muscle or 'General'})" for ex in available_exercises]
    )

    # 2. PROMPT REFINADO
    prompt = f"""
    Eres un entrenador personal de élite de la app Athletica.
    Tu tarea es recomendar exactamente 3 ejercicios basados en el perfil del usuario, su historial y la lista disponible.

    [DATOS DEL USUARIO]
    - Perfil: {profile_str}
    - Historial Reciente: {history_str}
    - Ejercicios Disponibles en la Base de Datos: {exercises_list}

    [REGLAS CRÍTICAS DE EJECUCIÓN]
    1. IDIOMA: Todo el JSON debe estar en ESPAÑOL.
    2. VARIABILIDAD: Cada ejercicio debe tener una razón biomecánica diferente.
    3. DETALLE TÉCNICO: Para cada ejercicio, define Series, Repeticiones (o tiempo) y Descanso (segundos) según el perfil del usuario.
    4. BREVEDAD: La 'reason' debe ser menor a 12 palabras.
    5. VIDEO: Para cada ejercicio, busca y proporciona un ID de video de YouTube (solo el código de 11 caracteres) que sea un tutorial técnico de alta calidad en español o inglés.
    6. CERO TEXTO EXTRA: Devuelve ÚNICAMENTE el arreglo JSON.

    [ESQUEMA JSON REQUERIDO]
    [
        {{
            "exercise_name": "Nombre exacto",
            "reason": "Razón ultra corta",
            "sets": 3,
            "reps": "12" o "30s",
            "rest": 60,
            "instructions": "Tip rápido de ejecución",
            "youtube_id": "ID_DE_VIDEO"
        }},
        ...
    ]
    """

    try:
        response = model.generate_content(prompt)
        text = response.text.strip()
        # Clean up possible markdown code blocks
        if text.startswith("```json"):
            text = text[7:-3].strip()
        elif text.startswith("```"):
            text = text[3:-3].strip()

        recommendations = json.loads(text)

        # Post-process: ensure real IDs for common exercises (case-insensitive)
        YOUTUBE_MAP = {
            "kettlebell swing": "ysS-SAs_X_U",
            "jalón al pecho": "CAwf7n6Luuc",
            "sentadilla": "gcNh17Ckjgg",
            "aperturas posteriores": "V8dZ3pkI9XQ",
            "press de banca": "vcBig73ojpE",
        }

        for rec in recommendations:
            name_lower = rec["exercise_name"].lower()
            # Try to match the name in our mapping
            for key, val in YOUTUBE_MAP.items():
                if key in name_lower:
                    rec["youtube_id"] = val
                    break

        return recommendations

    except Exception as e:
        print(f"Error calling Gemini API: {e}")
        return _get_mock_recommendations(available_exercises)


def _get_mock_recommendations(available_exercises):
    """Fallback with high-quality verified YouTube IDs."""
    import random

    YOUTUBE_MAPPING = {
        "jalón al pecho": "L815_F4fI3w",  # Official CrossFit
        "aperturas posteriores": "nZ_7I999p_I",  # Verified technician
        "sentadilla": "gcNh17Ckjgg",  # Squat University
        "press de banca": "rT7DgCr-3ps",  # Rogue Fitness
        "kettlebell swing": "ysS-SAs_X_U",  # High quality
    }

    DEFAULT_VIDEO = "gcNh17Ckjgg"  # Squat University (very stable for embedding)

    reasons = [
        "Potencia tu fuerza explosiva y estabilidad central.",
        "Ideal para corregir desequilibrios musculares.",
        "Optimiza tu rango de movimiento y previene lesiones.",
        "Aumenta la densidad muscular y mejora tu postura.",
    ]

    if not available_exercises:
        return [
            {
                "exercise_name": "Jalón al pecho",
                "reason": "Excelente para fortalecer tus cadenas musculares posteriores.",
                "sets": 3,
                "reps": "12",
                "rest": 60,
                "muscle": "Espalda",
                "instructions": "Mantén los codos hacia abajo y el pecho arriba.",
                "youtube_id": YOUTUBE_MAPPING["jalón al pecho"],
            }
        ]

    selected = random.sample(list(available_exercises), min(len(available_exercises), 3))  # nosec B311

    results = []
    for ex in selected:
        name_lower = ex.name.lower()
        results.append(
            {
                "exercise_name": ex.name,
                "reason": random.choice(reasons),  # nosec B311

                "sets": 3,
                "reps": "12",
                "rest": 60,
                "muscle": ex.muscle if ex.muscle else "General",
                "instructions": "Realiza el movimiento con control total.",
                "youtube_id": YOUTUBE_MAPPING.get(name_lower, DEFAULT_VIDEO),
            }
        )

    return results
