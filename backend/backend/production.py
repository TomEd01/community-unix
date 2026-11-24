import os

from .settings import *  # noqa: F403

DEBUG = False
ALLOWED_HOSTS = [host.strip() for host in os.environ['ALLOWED_HOSTS'].split(',') if host.strip()]
if not ALLOWED_HOSTS:
    raise ValueError('ALLOWED_HOSTS must contain at least one host')

DATABASES = {
    **DATABASES,  # noqa: F405
    'default': {
        **DATABASES['default'],  # noqa: F405
        'OPTIONS': {
            **DATABASES['default']['OPTIONS'],  # noqa: F405
            'sslmode': os.environ.get('DB_SSLMODE', 'require'),
        },
    },
}

STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'  # noqa: F405
CSRF_TRUSTED_ORIGINS = [
    origin.strip() for origin in os.environ.get('CSRF_TRUSTED_ORIGINS', '').split(',') if origin.strip()
]
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
