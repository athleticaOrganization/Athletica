from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    ExerciseRecommendationView,
    ExerciseViewSet,
    RoutineViewSet,
    SetLogViewSet,
    TrainingGroupViewSet,
    WorkoutSessionViewSet,
)

router = DefaultRouter()
router.register(r"api/routines", RoutineViewSet, basename="routine")
router.register(r"api/sessions", WorkoutSessionViewSet, basename="session")
router.register(r"api/sets", SetLogViewSet, basename="set")
router.register(r"api/exercises", ExerciseViewSet, basename="exercise")
router.register(r"api/groups", TrainingGroupViewSet, basename="group")

urlpatterns = [
    path(
        "api/routines/recommendations/",
        ExerciseRecommendationView.as_view(),
        name="exercise-recommendations",
    ),
    path("", include(router.urls)),
    # Manual override for the specific athlete active routine path used by the frontend
    path(
        "api/athletes/<int:athlete_id>/routine/",
        RoutineViewSet.as_view({"get": "active_routine"}),
        name="athlete-active-routine",
    ),
]
