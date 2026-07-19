// ============================================================================
// app_log_error_capture.dart — Flutter 与 debugPrint 错误捕获
// ============================================================================

part of 'app_logs.dart';

/// 在 [AppLogPanelHost] 挂载期间接入 Flutter 的全局错误出口。
///
/// 所有 hook 都会继续调用原 handler；未处理异步异常仍返回原 handler 的结果，
/// 没有原 handler 时返回 false，让 Flutter 保持原本的控制台输出行为。
class _AppErrorCapture {
  _AppErrorCapture._();

  static final _AppErrorCapture instance = _AppErrorCapture._();

  static final RegExp _consoleErrorStart = RegExp(
    r'(?:^|\n)(?:🚨\s*\[(?:Network|App) Error[^\]]*\]|'
    r'(?:\[ERROR:flutter\/[^\]]+\]\s*)?Unhandled Exception:)',
  );

  int _attachmentCount = 0;
  DebugPrintCallback? _previousDebugPrint;
  FlutterExceptionHandler? _previousFlutterError;
  ui.ErrorCallback? _previousPlatformError;
  DebugPrintCallback? _installedDebugPrint;
  FlutterExceptionHandler? _installedFlutterError;
  ui.ErrorCallback? _installedPlatformError;
  Timer? _consoleFlushTimer;
  final StringBuffer _consoleErrorBuffer = StringBuffer();
  int _consoleCaptureSuppressionDepth = 0;

  T withoutDebugPrintCapture<T>(T Function() action) {
    _consoleCaptureSuppressionDepth += 1;
    try {
      return action();
    } finally {
      _consoleCaptureSuppressionDepth -= 1;
    }
  }

  void attach() {
    _attachmentCount += 1;
    if (_attachmentCount != 1) return;

    _previousDebugPrint = debugPrint;
    _installedDebugPrint = (String? message, {int? wrapWidth}) {
      _captureDebugPrint(message);
      _previousDebugPrint?.call(message, wrapWidth: wrapWidth);
    };
    debugPrint = _installedDebugPrint!;

    _previousFlutterError = FlutterError.onError;
    _installedFlutterError = (FlutterErrorDetails details) {
      AppLogStore.instance.logError(
        source: AppErrorLogSource.flutter,
        message: details.exceptionAsString(),
        stackTrace: details.stack,
      );
      final previous = _previousFlutterError;
      if (previous != null) {
        previous(details);
      } else {
        FlutterError.presentError(details);
      }
    };
    FlutterError.onError = _installedFlutterError;

    _previousPlatformError = ui.PlatformDispatcher.instance.onError;
    _installedPlatformError = (Object error, StackTrace stackTrace) {
      AppLogStore.instance.logError(
        source: AppErrorLogSource.unhandled,
        message: error.toString(),
        stackTrace: stackTrace,
      );
      return _previousPlatformError?.call(error, stackTrace) ?? false;
    };
    ui.PlatformDispatcher.instance.onError = _installedPlatformError;
  }

  void detach() {
    if (_attachmentCount == 0) return;
    _attachmentCount -= 1;
    if (_attachmentCount != 0) return;

    _flushConsoleError();
    if (identical(debugPrint, _installedDebugPrint)) {
      debugPrint = _previousDebugPrint ?? debugPrintThrottled;
    }
    if (identical(FlutterError.onError, _installedFlutterError)) {
      FlutterError.onError = _previousFlutterError;
    }
    if (identical(
      ui.PlatformDispatcher.instance.onError,
      _installedPlatformError,
    )) {
      ui.PlatformDispatcher.instance.onError = _previousPlatformError;
    }

    _previousDebugPrint = null;
    _previousFlutterError = null;
    _previousPlatformError = null;
    _installedDebugPrint = null;
    _installedFlutterError = null;
    _installedPlatformError = null;
  }

  void _captureDebugPrint(String? message) {
    if (_consoleCaptureSuppressionDepth > 0 ||
        !AppLogsConfig.enabled ||
        message == null ||
        message.isEmpty) {
      return;
    }

    if (_consoleErrorStart.hasMatch(message)) {
      _flushConsoleError();
    } else if (_consoleErrorBuffer.isEmpty) {
      return;
    }

    if (_consoleErrorBuffer.isNotEmpty) _consoleErrorBuffer.writeln();
    _consoleErrorBuffer.write(message);
    _consoleFlushTimer?.cancel();
    _consoleFlushTimer = Timer(
      const Duration(milliseconds: 100),
      _flushConsoleError,
    );
  }

  void _flushConsoleError() {
    _consoleFlushTimer?.cancel();
    _consoleFlushTimer = null;
    if (_consoleErrorBuffer.isEmpty) return;

    final message = _consoleErrorBuffer.toString();
    _consoleErrorBuffer.clear();
    AppLogStore.instance.logError(
      source: AppErrorLogSource.console,
      message: message,
    );
  }
}
