import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_logs/flutter_app_logs.dart';

void main() {
  group('AppLogsTheme', () {
    test('defaultTheme has correct color values', () {
      const theme = AppLogsTheme.defaultTheme;
      expect(theme.primary, const Color(0xFF908FFF));
      expect(theme.info, const Color(0xFF006AB6));
      expect(theme.success, const Color(0xFF00A565));
      expect(theme.debug, const Color(0xFF9CA3AF));
      expect(theme.error, const Color(0xFFFF1010));
      expect(theme.patch, const Color(0xFF7F63C0));
    });

    test('default constructor produces same values as defaultTheme', () {
      const theme = AppLogsTheme();
      expect(theme.primary, AppLogsTheme.defaultTheme.primary);
      expect(theme.info, AppLogsTheme.defaultTheme.info);
      expect(theme.success, AppLogsTheme.defaultTheme.success);
      expect(theme.debug, AppLogsTheme.defaultTheme.debug);
      expect(theme.error, AppLogsTheme.defaultTheme.error);
      expect(theme.patch, AppLogsTheme.defaultTheme.patch);
    });

    test('custom theme overrides specific colors', () {
      const customTheme = AppLogsTheme(primary: Colors.red, info: Colors.blue);
      expect(customTheme.primary, Colors.red);
      expect(customTheme.info, Colors.blue);
      // 其余保持默认
      expect(customTheme.success, const Color(0xFF00A565));
      expect(customTheme.debug, const Color(0xFF9CA3AF));
      expect(customTheme.error, const Color(0xFFFF1010));
      expect(customTheme.patch, const Color(0xFF7F63C0));
    });

    test('can be used as const', () {
      // 编译时常量检查
      const theme = AppLogsTheme(primary: Colors.amber);
      expect(theme.primary, Colors.amber);
    });
  });
}
