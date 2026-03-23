import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_logs/flutter_app_logs.dart';

void main() {
  // AppLogStore 依赖 SchedulerBinding
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLogStore store;

  setUp(() {
    store = AppLogStore.instance;
    // 重置状态
    store.clearConsole();
    store.clearNetwork();
    // 启用日志，重置级别
    AppLogsConfig.init(enabled: true, consoleMinLevel: AppLogLevel.debug);
  });

  tearDown(() {
    // 恢复默认（disabled）
    AppLogsConfig.init(enabled: false);
  });

  group('AppLogStore — Console 日志', () {
    test('logConsole 添加日志条目', () {
      store.logConsole(level: AppLogLevel.info, message: 'hello');
      expect(store.console.length, 1);
      expect(store.console.first.level, AppLogLevel.info);
      expect(store.console.first.message, 'hello');
    });

    test('logConsole 最新日志在列表前端（倒序）', () {
      store.logConsole(level: AppLogLevel.info, message: 'first');
      store.logConsole(level: AppLogLevel.info, message: 'second');
      expect(store.console.first.message, 'second');
      expect(store.console.last.message, 'first');
    });

    test('logConsole 支持 tag 和 extra', () {
      store.logConsole(
        level: AppLogLevel.debug,
        message: 'with extra',
        tag: 'auth',
        extra: {'userId': 42},
      );
      final entry = store.console.first;
      expect(entry.tag, 'auth');
      expect(entry.extra, {'userId': 42});
    });

    test('enabled=false 时不写入日志', () {
      AppLogsConfig.enabled = false;
      store.logConsole(level: AppLogLevel.info, message: 'ignored');
      expect(store.console, isEmpty);
    });

    test('低于 consoleMinLevel 的日志不写入', () {
      AppLogsConfig.consoleMinLevel = AppLogLevel.warn;
      store.logConsole(level: AppLogLevel.debug, message: 'too low');
      store.logConsole(level: AppLogLevel.info, message: 'still too low');
      store.logConsole(level: AppLogLevel.warn, message: 'ok');
      store.logConsole(level: AppLogLevel.error, message: 'also ok');
      expect(store.console.length, 2);
      expect(store.console[0].message, 'also ok');
      expect(store.console[1].message, 'ok');
    });

    test('容量上限为 500 条', () {
      for (var i = 0; i < 520; i++) {
        store.logConsole(level: AppLogLevel.info, message: 'msg-$i');
      }
      expect(store.console.length, 500);
      // 最新的是 msg-519
      expect(store.console.first.message, 'msg-519');
    });

    test('clearConsole 清除所有 Console 日志', () {
      store.logConsole(level: AppLogLevel.info, message: 'a');
      store.logConsole(level: AppLogLevel.info, message: 'b');
      expect(store.console.length, 2);
      store.clearConsole();
      expect(store.console, isEmpty);
    });

    test('notifyListeners 被调用', () {
      var count = 0;
      store.addListener(() => count++);
      store.logConsole(level: AppLogLevel.info, message: 'trigger');
      expect(count, 1);
    });
  });

  group('AppLogStore — Network 日志', () {
    test('logNetworkRequest 添加请求记录', () {
      store.logNetworkRequest(
        id: 'r1',
        at: DateTime.now(),
        path: '/api/test',
        method: 'GET',
        request: {'url': 'https://example.com/api/test'},
      );
      expect(store.network.length, 1);
      expect(store.network.first.id, 'r1');
      expect(store.network.first.path, '/api/test');
      expect(store.network.first.method, 'GET');
      expect(store.network.first.response, isNull);
    });

    test('logNetworkResponse 更新已有记录', () {
      store.logNetworkRequest(
        id: 'r2',
        at: DateTime.now(),
        path: '/api/data',
        method: 'POST',
        request: {'data': 'body'},
      );
      store.logNetworkResponse(
        id: 'r2',
        at: DateTime.now(),
        response: {'statusCode': 200},
        durationMs: 100,
      );
      expect(store.network.length, 1);
      expect(store.network.first.response, isNotNull);
      expect(store.network.first.response!['statusCode'], 200);
      expect(store.network.first.durationMs, 100);
    });

    test('logNetworkError 更新已有记录', () {
      store.logNetworkRequest(
        id: 'r3',
        at: DateTime.now(),
        path: '/api/fail',
        method: 'DELETE',
        request: {},
      );
      store.logNetworkError(
        id: 'r3',
        at: DateTime.now(),
        error: {'type': 'timeout'},
        durationMs: 5000,
      );
      expect(store.network.length, 1);
      expect(store.network.first.error, isNotNull);
      expect(store.network.first.error!['type'], 'timeout');
    });

    test('logNetworkResponse 对不存在的 id 创建新记录', () {
      store.logNetworkResponse(
        id: 'new-id',
        at: DateTime.now(),
        request: {'path': '/late', 'method': 'PUT'},
        response: {'statusCode': 201},
        durationMs: 50,
      );
      expect(store.network.length, 1);
      expect(store.network.first.id, 'new-id');
      expect(store.network.first.response!['statusCode'], 201);
    });

    test('logNetworkError 对不存在的 id 创建新记录', () {
      store.logNetworkError(
        id: 'err-new',
        at: DateTime.now(),
        request: {'path': '/oops', 'method': 'PATCH'},
        error: {'type': 'cancel'},
      );
      expect(store.network.length, 1);
      expect(store.network.first.error!['type'], 'cancel');
    });

    test('最新网络日志在列表前端（倒序）', () {
      store.logNetworkRequest(
        id: 'a',
        at: DateTime.now(),
        path: '/first',
        method: 'GET',
        request: {},
      );
      store.logNetworkRequest(
        id: 'b',
        at: DateTime.now(),
        path: '/second',
        method: 'GET',
        request: {},
      );
      expect(store.network.first.id, 'b');
      expect(store.network.last.id, 'a');
    });

    test('更新已有记录后移到列表前端', () {
      store.logNetworkRequest(
        id: 'old',
        at: DateTime.now(),
        path: '/old',
        method: 'GET',
        request: {},
      );
      store.logNetworkRequest(
        id: 'new',
        at: DateTime.now(),
        path: '/new',
        method: 'GET',
        request: {},
      );
      // new 在前
      expect(store.network.first.id, 'new');

      // 更新 old → 移到前端
      store.logNetworkResponse(
        id: 'old',
        at: DateTime.now(),
        response: {'ok': true},
      );
      expect(store.network.first.id, 'old');
    });

    test('容量上限为 200 条', () {
      for (var i = 0; i < 210; i++) {
        store.logNetworkRequest(
          id: 'req-$i',
          at: DateTime.now(),
          path: '/api/$i',
          method: 'GET',
          request: {},
        );
      }
      expect(store.network.length, 200);
      // 最新的是 req-209
      expect(store.network.first.id, 'req-209');
    });

    test('enabled=false 时不写入网络日志', () {
      AppLogsConfig.enabled = false;
      store.logNetworkRequest(
        id: 'skip',
        at: DateTime.now(),
        path: '/skip',
        method: 'GET',
        request: {},
      );
      expect(store.network, isEmpty);
    });

    test('clearNetwork 清除所有网络日志', () {
      store.logNetworkRequest(
        id: 'x',
        at: DateTime.now(),
        path: '/x',
        method: 'GET',
        request: {},
      );
      expect(store.network.length, 1);
      store.clearNetwork();
      expect(store.network, isEmpty);
    });
  });

  group('AppLogStore — console 返回不可变列表', () {
    test('外部不能修改 console 列表', () {
      store.logConsole(level: AppLogLevel.info, message: 'test');
      final list = store.console;
      expect(
        () => list.add(
          AppConsoleLogEntry(
            at: DateTime.now(),
            level: AppLogLevel.info,
            message: 'hack',
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('外部不能修改 network 列表', () {
      store.logNetworkRequest(
        id: 'n1',
        at: DateTime.now(),
        path: '/n',
        method: 'GET',
        request: {},
      );
      final list = store.network;
      expect(
        () => list.add(
          AppNetworkLogEntry(
            id: 'hack',
            at: DateTime.now(),
            path: '/hack',
            method: 'GET',
            request: {},
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
