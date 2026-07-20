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
      expect(entry.state, AppNetworkLogState.pending);
      expect(entry.url, 'https://example.com/api/test');
      expect(entry.host, 'example.com');
      expect(entry.statusCode, isNull);
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
      expect(updated.state, AppNetworkLogState.success);
      expect(updated.statusCode, 200);
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
      expect(updated.state, AppNetworkLogState.error);
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

    test('cancelled 状态可独立于 error payload 保存', () {
      final entry = AppNetworkLogEntry(
        id: 'req-cancelled',
        at: DateTime.now(),
        path: '/cancelled',
        method: 'GET',
        state: AppNetworkLogState.cancelled,
        request: const {'url': 'https://api.example.com/cancelled'},
        error: const {'type': 'cancel'},
      );

      expect(entry.state, AppNetworkLogState.cancelled);
      expect(entry.statusCode, isNull);
    });

    test('toCurl 输出完整 URL、脱敏 Header 和 JSON body', () {
      final entry = AppNetworkLogEntry(
        id: 'curl-json',
        at: DateTime.now(),
        path: '/orders',
        method: 'POST',
        request: const <String, Object?>{
          'url': 'https://api.example.com/orders?page=1',
          'headers': <String, Object?>{
            'Content-Type': 'application/json',
            'Authorization': '***fghijk',
          },
          'data': <String, Object?>{'name': "O'Reilly", 'count': 2},
        },
      );

      final curl = entry.toCurl();

      expect(curl, startsWith('curl \\\n'));
      expect(curl, contains("--request 'POST'"));
      expect(curl, contains("--url 'https://api.example.com/orders?page=1'"));
      expect(curl, contains("--header 'Authorization: ***fghijk'"));
      expect(curl, isNot(contains('Bearer')));
      expect(curl, contains("O'\"'\"'Reilly"));
    });

    test('toCurl 为 FormData 文件生成明确占位路径', () {
      final entry = AppNetworkLogEntry(
        id: 'curl-form',
        at: DateTime.now(),
        path: '/upload',
        method: 'POST',
        request: const <String, Object?>{
          'url': 'https://api.example.com/upload',
          'data': <String, Object?>{
            'type': 'FormData',
            'fields': <Object?>[
              <String, Object?>{'key': 'title', 'value': 'avatar'},
            ],
            'files': <Object?>[
              <String, Object?>{'key': 'file', 'filename': 'avatar.png'},
            ],
          },
        },
      );

      final curl = entry.toCurl();

      expect(curl, contains("--form 'title=avatar'"));
      expect(curl, contains("--form 'file=@<avatar.png>'"));
    });
  });

  group('AppErrorLogEntry', () {
    test('构造并读取错误来源与堆栈', () {
      final now = DateTime.now();
      final entry = AppErrorLogEntry(
        at: now,
        source: AppErrorLogSource.unhandled,
        message: 'type cast failed',
        stackTrace: '#0 parser (schema.g.dart:10:3)',
      );

      expect(entry.at, now);
      expect(entry.source, AppErrorLogSource.unhandled);
      expect(entry.message, 'type cast failed');
      expect(entry.stackTrace, contains('schema.g.dart'));
    });
  });
}
