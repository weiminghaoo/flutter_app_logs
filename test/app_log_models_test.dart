import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_logs/flutter_app_logs.dart';

void main() {
  group('AppConsoleLogEntry', () {
    test('构造并读取字段', () {
      final now = DateTime.now();
      final entry2 = AppConsoleLogEntry(
        at: now,
        level: AppLogLevel.warn,
        message: 'warning msg',
        tag: 'net',
        extra: {'code': 200},
      );
      expect(entry2.at, now);
      expect(entry2.level, AppLogLevel.warn);
      expect(entry2.message, 'warning msg');
      expect(entry2.tag, 'net');
      expect(entry2.extra, {'code': 200});
    });

    test('tag and extra default to null', () {
      final entry = AppConsoleLogEntry(
        at: DateTime.now(),
        level: AppLogLevel.debug,
        message: 'test',
      );
      expect(entry.tag, isNull);
      expect(entry.extra, isNull);
    });
  });

  group('AppNetworkLogEntry', () {
    test('构造并读取字段', () {
      final now = DateTime.now();
      final entry = AppNetworkLogEntry(
        id: '1',
        at: now,
        path: '/api/test',
        method: 'GET',
        request: {'url': 'https://example.com/api/test'},
      );
      expect(entry.id, '1');
      expect(entry.at, now);
      expect(entry.path, '/api/test');
      expect(entry.method, 'GET');
      expect(entry.request, {'url': 'https://example.com/api/test'});
      expect(entry.response, isNull);
      expect(entry.error, isNull);
      expect(entry.durationMs, isNull);
    });

    test('copyWith 更新 response 和 durationMs', () {
      final now = DateTime.now();
      final entry = AppNetworkLogEntry(
        id: 'req-1',
        at: now,
        path: '/api/users',
        method: 'POST',
        request: {'data': 'body'},
      );

      final updated = entry.copyWith(
        response: {'statusCode': 200, 'data': 'ok'},
        durationMs: 150,
      );

      // 不变字段
      expect(updated.id, 'req-1');
      expect(updated.path, '/api/users');
      expect(updated.method, 'POST');
      expect(updated.request, {'data': 'body'});

      // 更新字段
      expect(updated.response, {'statusCode': 200, 'data': 'ok'});
      expect(updated.durationMs, 150);
      expect(updated.error, isNull);
    });

    test('copyWith 更新 error', () {
      final entry = AppNetworkLogEntry(
        id: 'req-2',
        at: DateTime.now(),
        path: '/api/fail',
        method: 'DELETE',
        request: {},
      );

      final updated = entry.copyWith(
        error: {'type': 'timeout', 'message': 'Connection timed out'},
        durationMs: 5000,
      );

      expect(updated.error, isNotNull);
      expect(updated.error!['type'], 'timeout');
      expect(updated.durationMs, 5000);
    });

    test('copyWith preserves original when no args given', () {
      final now = DateTime.now();
      final entry = AppNetworkLogEntry(
        id: 'req-3',
        at: now,
        path: '/test',
        method: 'GET',
        request: {'key': 'value'},
        response: {'status': 200},
        error: {'msg': 'err'},
        durationMs: 100,
      );

      final copy = entry.copyWith();
      expect(copy.id, entry.id);
      expect(copy.at, entry.at);
      expect(copy.path, entry.path);
      expect(copy.method, entry.method);
      expect(copy.request, entry.request);
      expect(copy.response, entry.response);
      expect(copy.error, entry.error);
      expect(copy.durationMs, entry.durationMs);
    });
  });
}
