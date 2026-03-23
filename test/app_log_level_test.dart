import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_logs/flutter_app_logs.dart';

void main() {
  group('AppLogLevel', () {
    test('enum values are in ascending severity order', () {
      expect(AppLogLevel.debug.index, 0);
      expect(AppLogLevel.info.index, 1);
      expect(AppLogLevel.warn.index, 2);
      expect(AppLogLevel.error.index, 3);
    });

    test('has exactly 4 values', () {
      expect(AppLogLevel.values.length, 4);
    });

    test('index comparison works for level filtering', () {
      // debug < info < warn < error
      expect(AppLogLevel.debug.index < AppLogLevel.info.index, isTrue);
      expect(AppLogLevel.info.index < AppLogLevel.warn.index, isTrue);
      expect(AppLogLevel.warn.index < AppLogLevel.error.index, isTrue);
    });
  });
}
