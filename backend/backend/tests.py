import importlib.util
import os
from pathlib import Path
from unittest.mock import patch

from django.test import SimpleTestCase


class ProductionSettingsTests(SimpleTestCase):
    def load_production_settings(self):
        spec = importlib.util.spec_from_file_location(
            'backend._production_test', Path(__file__).with_name('production.py')
        )
        assert spec is not None and spec.loader is not None
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return vars(module)

    def test_production_settings(self):
        with patch.dict(os.environ, {
            'ALLOWED_HOSTS': ' example.com, www.example.com ',
            'CSRF_TRUSTED_ORIGINS': 'https://example.com',
        }):
            settings = self.load_production_settings()

        self.assertFalse(settings['DEBUG'])
        self.assertEqual(settings['ALLOWED_HOSTS'], ['example.com', 'www.example.com'])
        self.assertEqual(settings['CSRF_TRUSTED_ORIGINS'], ['https://example.com'])
        self.assertEqual(settings['STATIC_URL'], '/static/')
        self.assertEqual(settings['SECURE_PROXY_SSL_HEADER'], ('HTTP_X_FORWARDED_PROTO', 'https'))
        self.assertTrue(settings['SESSION_COOKIE_SECURE'])
        self.assertTrue(settings['CSRF_COOKIE_SECURE'])

    def test_empty_hosts_are_rejected(self):
        with patch.dict(os.environ, {'ALLOWED_HOSTS': ' , '}):
            with self.assertRaises(ValueError):
                self.load_production_settings()

    def test_database_sslmode_can_be_configured(self):
        with patch.dict(os.environ, {'ALLOWED_HOSTS': 'example.com', 'DB_SSLMODE': 'disable'}):
            settings = self.load_production_settings()
        self.assertEqual(settings['DATABASES']['default']['OPTIONS']['sslmode'], 'disable')

    def test_database_sslmode_defaults_to_require(self):
        with patch.dict(os.environ, {'ALLOWED_HOSTS': 'example.com'}, clear=True):
            settings = self.load_production_settings()
        self.assertEqual(settings['DATABASES']['default']['OPTIONS']['sslmode'], 'require')
