from django.urls import path

from .views import (
    CompleteProfileView,
    GoogleLoginView,
)


urlpatterns = [
    path(
        "google/",
        GoogleLoginView.as_view(),
        name="google_login",
    ),
    path(
        "complete-profile/",
        CompleteProfileView.as_view(),
        name="complete_profile",
    ),
]