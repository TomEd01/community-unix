from django.db import connection
from django.db.migrations.executor import MigrationExecutor
from django.test import TransactionTestCase


class InstructorProcedenciaMigrationTests(TransactionTestCase):
    initial = ("accounts", "0001_initial")
    instructor = ("accounts", "0002_instructor_procedencia")
    externo = ("accounts", "0002_remove_externo_procedencia_externo_tipo_experiencia_and_more")
    latest = ("accounts", "0004_horarioclase_vinculoalumno")

    def migrate(self, targets):
        executor = MigrationExecutor(connection)
        executor.migrate(targets)
        return executor.loader.project_state(targets).apps

    def setUp(self):
        super().setUp()
        self.migrate([self.initial])

    def tearDown(self):
        self.migrate([self.latest])
        super().tearDown()

    def columns(self, table):
        with connection.cursor() as cursor:
            return {
                column.name: column
                for column in connection.introspection.get_table_description(cursor, table)
            }

    def test_both_branch_orders_preserve_instructor_data_and_reverse(self):
        for first in (self.instructor, self.externo):
            with self.subTest(first=first):
                apps = self.migrate([first])
                user = apps.get_model("accounts", "Usuario").objects.create(
                    email=f"{first[1]}@example.com", nombre_completo="Test", rol="instructor"
                )
                instructor = apps.get_model("accounts", "Instructor").objects.create(
                    usuario_id=user.pk,
                    numero_control=first[1][:20],
                    departamento="Test",
                    especialidad="Test",
                    grado_academico="Test",
                    procedencia="Preserved",
                )

                apps = self.migrate([self.latest])
                self.assertEqual(
                    apps.get_model("accounts", "Instructor").objects.get(pk=instructor.pk).procedencia,
                    "Preserved",
                )
                self.assertIn("tipo_experiencia", self.columns("accounts_externo"))
                self.assertNotIn("procedencia", self.columns("accounts_externo"))

                apps = self.migrate([first])
                self.assertEqual(
                    apps.get_model("accounts", "Instructor").objects.get(pk=instructor.pk).procedencia,
                    "Preserved",
                )
                self.migrate([self.latest])
                self.migrate([self.initial])
                self.assertNotIn("procedencia", self.columns("accounts_instructor"))
                self.assertIn("procedencia", self.columns("accounts_externo"))

    def test_missing_column_after_other_branch_fails_explicitly(self):
        self.migrate([self.instructor])
        with connection.cursor() as cursor:
            cursor.execute("ALTER TABLE accounts_instructor DROP COLUMN procedencia")
        try:
            with self.assertRaisesMessage(RuntimeError, "is missing"):
                self.migrate([self.latest])
        finally:
            with connection.cursor() as cursor:
                cursor.execute(
                    "ALTER TABLE accounts_instructor "
                    "ADD COLUMN procedencia varchar(100) NOT NULL DEFAULT 'itc'"
                )

    def test_incompatible_existing_column_fails_explicitly(self):
        if connection.vendor != "postgresql":
            self.skipTest("PostgreSQL-specific schema alteration")
        with connection.cursor() as cursor:
            cursor.execute(
                "ALTER TABLE accounts_instructor ADD COLUMN procedencia varchar(20)"
            )
        try:
            with self.assertRaisesMessage(RuntimeError, "column is incompatible"):
                self.migrate([self.instructor])
        finally:
            with connection.cursor() as cursor:
                cursor.execute("ALTER TABLE accounts_instructor DROP COLUMN procedencia")
