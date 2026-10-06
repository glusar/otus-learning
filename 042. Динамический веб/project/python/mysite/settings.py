import os


BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

SECRET_KEY = os.getenv(
    "MYSITE_SECRET_KEY",
    "dev-secret-key"
)

DEBUG = os.getenv("DEBUG", "False").lower() == "true"

ALLOWED_HOSTS = [
    "localhost",
    "127.0.0.1",
    "0.0.0.0",
    "*",
]

ROOT_URLCONF = "mysite.urls"

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
]

INSTALLED_APPS = []

TEMPLATES = []

WSGI_APPLICATION = "mysite.wsgi.application"

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": os.path.join(BASE_DIR, "db.sqlite3"),
    }
}