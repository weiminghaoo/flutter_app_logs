import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_logs/flutter_app_logs.dart';

void main() {
  // 每次测试前重置 AppLogsConfig 到默认值
  setUp(() {
    AppLogsConfig.init(
      enabled: false,
      consoleMinLevel: AppLogLevel.debug,
      maskHeaders: false,
      onCopySuccess: null,
      theme: AppLogsTheme.defaultTheme,
    );
  });

  group('AppLogsConfig', () {
    test('default values after init with no args', () {
      AppLogsConfig.init();
      expect(AppLogsConfig.enabled, isFalse);
      expect(AppLogsConfig.consoleMinLevel, AppLogLevel.debug);
      expect(AppLogsConfig.maskHeaders, isFalse);
      expect(AppLogsConfig.onCopySuccess, isNull);
      expect(AppLogsConfig.theme, same(AppLogsTheme.defaultTheme));
    });

    test('init sets enabled', () {
      AppLogsConfig.init(enabled: true);
      expect(AppLogsConfig.enabled, isTrue);
    });

    test('init sets consoleMinLevel', () {
      AppLogsConfig.init(consoleMinLevel: AppLogLevel.warn);
      expect(AppLogsConfig.consoleMinLevel, AppLogLevel.warn);
    });

    test('init sets maskHeaders', () {
      AppLogsConfig.init(maskHeaders: true);
      expect(AppLogsConfig.maskHeaders, isTrue);
    });

    test('init sets onCopySuccess callback', () {
      String? captured;
      AppLogsConfig.init(onCopySuccess: (text) => captured = text);
      expect(AppLogsConfig.onCopySuccess, isNotNull);
      AppLogsConfig.onCopySuccess!('hello');
      expect(captured, 'hello');
    });

    test('init sets custom theme', () {
      const custom = AppLogsTheme(primary: Colors.pink);
      AppLogsConfig.init(theme: custom);
      expect(AppLogsConfig.theme.primary, Colors.pink);
    });

    test('can overwrite config by calling init again', () {
      AppLogsConfig.init(enabled: true, consoleMinLevel: AppLogLevel.error);
      expect(AppLogsConfig.enabled, isTrue);
      expect(AppLogsConfig.consoleMinLevel, AppLogLevel.error);

      AppLogsConfig.init(enabled: false, consoleMinLevel: AppLogLevel.info);
      expect(AppLogsConfig.enabled, isFalse);
      expect(AppLogsConfig.consoleMinLevel, AppLogLevel.info);
    });

    test('static fields can be set directly', () {
      AppLogsConfig.enabled = true;
      expect(AppLogsConfig.enabled, isTrue);
      AppLogsConfig.maskHeaders = true;
      expect(AppLogsConfig.maskHeaders, isTrue);
    });
  });
}
