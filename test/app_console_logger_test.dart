import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_logs/flutter_app_logs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AppLogStore.instance.clearConsole();
    AppLogsConfig.init(enabled: true, consoleMinLevel: AppLogLevel.debug);
  });

  tearDown(() {
    AppLogsConfig.init(enabled: false);
  });

  group('AppConsoleLogger', () {
    test('debug() 写入 debug 级别日志', () {
      AppConsoleLogger.debug('debug msg', tag: 'test');
      final entry = AppLogStore.instance.console.first;
      expect(entry.level, AppLogLevel.debug);
      expect(entry.message, 'debug msg');
      expect(entry.tag, 'test');
    });

    test('info() 写入 info 级别日志', () {
      AppConsoleLogger.info('info msg');
      expect(AppLogStore.instance.console.first.level, AppLogLevel.info);
      expect(AppLogStore.instance.console.first.message, 'info msg');
    });

    test('warn() 写入 warn 级别日志', () {
      AppConsoleLogger.warn('warn msg');
      expect(AppLogStore.instance.console.first.level, AppLogLevel.warn);
    });

    test('error() 写入 error 级别日志', () {
      AppConsoleLogger.error('error msg', extra: {'code': 500});
      final entry = AppLogStore.instance.console.first;
      expect(entry.level, AppLogLevel.error);
      expect(entry.extra, {'code': 500});
    });

    test('log() 支持任意级别', () {
      AppConsoleLogger.log(AppLogLevel.warn, 'custom level');
      expect(AppLogStore.instance.console.first.level, AppLogLevel.warn);
    });

    test('enabled=false 时所有方法不写入', () {
      AppLogsConfig.enabled = false;
      AppConsoleLogger.debug('a');
      AppConsoleLogger.info('b');
      AppConsoleLogger.warn('c');
      AppConsoleLogger.error('d');
      expect(AppLogStore.instance.console, isEmpty);
    });

    test('受 consoleMinLevel 控制', () {
      AppLogsConfig.consoleMinLevel = AppLogLevel.error;
      AppConsoleLogger.debug('no');
      AppConsoleLogger.info('no');
      AppConsoleLogger.warn('no');
      AppConsoleLogger.error('yes');
      expect(AppLogStore.instance.console.length, 1);
      expect(AppLogStore.instance.console.first.message, 'yes');
    });
  });
}
