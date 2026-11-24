import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:comunidad_frontend/portal/api.dart';

void main() {
  const configuredBackend = String.fromEnvironment(
    'PORTAL_BACKEND_URL',
    defaultValue: String.fromEnvironment(
      'BACKEND_URL',
      defaultValue: 'http://127.0.0.1:8000',
    ),
  );

  test('catalog connection errors report the resolved backend origin', () async {
    SharedPreferences.setMockInitialValues({'jwt_token': 'test-token'});
    final expectedUrl = Uri.base
        .resolve(configuredBackend)
        .resolve('/superadmin/eventos/catalogos/');

    await http.runWithClient(
      () async {
        await expectLater(
          PortalApi.request('/superadmin/eventos/catalogos/'),
          throwsA(
            predicate(
              (error) =>
                  error.toString() ==
                  'Exception: No se pudo conectar a Django en ${expectedUrl.origin}.',
            ),
          ),
        );
      },
      () => MockClient((request) async {
        expect(request.url, expectedUrl);
        expect(request.headers['Authorization'], 'Bearer test-token');
        throw http.ClientException('Connection failed', request.url);
      }),
    );
  });
}
