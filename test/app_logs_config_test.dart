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
      expect(AppLogsConfig.maxConsoleEntries, 500);
      expect(AppLogsConfig.maxNetworkEntries, 200);
      expect(AppLogsConfig.maxErrorEntries, 200);
      expect(AppLogsConfig.maxNetworkBodyCharacters, 100000);
      expect(AppLogsConfig.mergeRepeatedErrors, isTrue);
      expect(AppLogsConfig.errorMergeWindow, const Duration(seconds: 30));
      expect(AppLogsConfig.errorCaptureRules.captureFlutterErrors, isTrue);
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

    test(
      'init sets capacities, body limit, merge window and capture rules',
      () {
        const rules = AppErrorCaptureRules(
          captureFlutterErrors: false,
          captureUnhandledErrors: false,
          captureConsoleErrors: true,
          includeDefaultConsolePatterns: false,
          additionalConsolePatterns: <Pattern>['FATAL:'],
          ignoredPatterns: <Pattern>['ignored'],
        );

        AppLogsConfig.init(
          maxConsoleEntries: 10,
          maxNetworkEntries: 20,
          maxErrorEntries: 30,
          maxNetworkBodyCharacters: 4096,
          errorCaptureRules: rules,
          mergeRepeatedErrors: false,
          errorMergeWindow: const Duration(seconds: 5),
        );

        expect(AppLogsConfig.maxConsoleEntries, 10);
        expect(AppLogsConfig.maxNetworkEntries, 20);
        expect(AppLogsConfig.maxErrorEntries, 30);
        expect(AppLogsConfig.maxNetworkBodyCharacters, 4096);
        expect(AppLogsConfig.errorCaptureRules, same(rules));
        expect(AppLogsConfig.mergeRepeatedErrors, isFalse);
        expect(AppLogsConfig.errorMergeWindow, const Duration(seconds: 5));
      },
    );

    test('init rejects negative limits and merge windows', () {
      expect(
        () => AppLogsConfig.init(maxErrorEntries: -1),
        throwsArgumentError,
      );
      expect(
        () => AppLogsConfig.init(maxNetworkBodyCharacters: -1),
        throwsArgumentError,
      );
      expect(
        () => AppLogsConfig.init(
          errorMergeWindow: const Duration(milliseconds: -1),
        ),
        throwsArgumentError,
      );
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
