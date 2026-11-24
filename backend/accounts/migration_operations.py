from django.db import migrations
from django.db.migrations.recorder import MigrationRecorder


class AddSharedInstructorProcedencia(migrations.AddField):
    """Handle the same field added independently by both 0002 migrations."""

    def __init__(self, *, other_migration, **kwargs):
        self.other_migration = other_migration
        super().__init__(**kwargs)

    def database_forwards(self, app_label, schema_editor, from_state, to_state):
        model = to_state.apps.get_model(app_label, self.model_name)
        if not self.allow_migrate_model(schema_editor.connection.alias, model):
            return

        field = model._meta.get_field(self.name)
        connection = schema_editor.connection
        with connection.cursor() as cursor:
            columns = connection.introspection.get_table_description(
                cursor, model._meta.db_table
            )
        column = next((column for column in columns if column.name == field.column), None)
        if column is None:
            recorder = MigrationRecorder(connection)
            if (app_label, self.other_migration) in recorder.applied_migrations():
                raise RuntimeError(
                    "accounts_instructor.procedencia is missing even though the other "
                    "0002 migration is applied; inspect the database before migrating."
                )
            return super().database_forwards(app_label, schema_editor, from_state, to_state)

        column_type = connection.introspection.get_field_type(column.type_code, column)
        if (
            column_type != "CharField"
            or column.null_ok
            or (column.internal_size is not None and column.internal_size != 100)
        ):
            raise RuntimeError(
                "Existing accounts_instructor.procedencia column is incompatible; "
                "expected a non-null varchar(100). Inspect the database before migrating."
            )

    def database_backwards(self, app_label, schema_editor, from_state, to_state):
        recorder = MigrationRecorder(schema_editor.connection)
        if (app_label, self.other_migration) in recorder.applied_migrations():
            return
        super().database_backwards(app_label, schema_editor, from_state, to_state)
