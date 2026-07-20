// ============================================================================
// app_log_models.dart
//
// 【职责】日志系统的数据层：数据模型、全局存储、日志入口。
//
// 包含以下类：
//   1. AppConsoleLogEntry  — Console 日志的单条数据结构
//   2. AppNetworkLogEntry  — Network 请求的单条数据结构（含 copyWith）
//   3. AppLogStore         — 全局单例，存储所有日志，继承 ChangeNotifier
//   4. AppConsoleLogger    — 静态日志入口（debug / info / warn / error）
// ============================================================================

part of 'app_logs.dart';

// ============================================================================
// 数据模型
// ============================================================================

/// Console 日志的单条记录。
class AppConsoleLogEntry {
  final DateTime at;
  final AppLogLevel level;
  final String message;
  final String? tag;

  /// 附加的结构化数据，展示为 JSON 块。
  final Map<String, Object?>? extra;

  const AppConsoleLogEntry({
    required this.at,
    required this.level,
    required this.message,
    this.tag,
    this.extra,
  });
}

/// Error 面板中的错误来源。
enum AppErrorLogSource {
  /// Flutter framework 通过 [FlutterError.onError] 上报的异常。
  flutter,

  /// 根 isolate 中未处理、由 [ui.PlatformDispatcher.onError] 上报的异常。
  unhandled,

  /// `debugPrint` 输出的 Network Error / App Error 错误块。
  console,
}

/// Error 面板中的一条错误记录。
class AppErrorLogEntry {
  /// Store 内的稳定 ID，用于归并更新时保留卡片状态。
  final int id;

  /// 最近一次发生时间。
  final DateTime at;

  /// 第一次发生时间。
  final DateTime firstOccurredAt;
  final AppErrorLogSource source;
  final String message;
  final String? stackTrace;

  /// 当前卡片累计归并的发生次数。
  final int occurrenceCount;

  /// 当前卡片是否包含尚未查看的新错误。
  final bool isUnread;

  const AppErrorLogEntry({
    this.id = 0,
    required this.at,
    DateTime? firstOccurredAt,
    required this.source,
    required this.message,
    this.stackTrace,
    this.occurrenceCount = 1,
    this.isUnread = false,
  }) : firstOccurredAt = firstOccurredAt ?? at;

  AppErrorLogEntry copyWith({
    DateTime? at,
    DateTime? firstOccurredAt,
    int? occurrenceCount,
    bool? isUnread,
  }) {
    return AppErrorLogEntry(
      id: id,
      at: at ?? this.at,
      firstOccurredAt: firstOccurredAt ?? this.firstOccurredAt,
      source: source,
      message: message,
      stackTrace: stackTrace,
      occurrenceCount: occurrenceCount ?? this.occurrenceCount,
      isUnread: isUnread ?? this.isUnread,
    );
  }
}

/// Network 请求当前所处的生命周期状态。
enum AppNetworkLogState { pending, success, error, cancelled }

/// Network 请求的单条记录。
///
/// 一个请求的生命周期分三个阶段：
/// 1. 请求发出时 → [AppLogStore.logNetworkRequest]
/// 2. 请求成功时 → [AppLogStore.logNetworkResponse]
/// 3. 请求失败时 → [AppLogStore.logNetworkError]
class AppNetworkLogEntry {
  final String id;
  final DateTime at;
  final String path;
  final String method;
  final AppNetworkLogState state;
  final Map<String, Object?> request;
  final Map<String, Object?>? response;
  final Map<String, Object?>? error;
  final int? durationMs;

  const AppNetworkLogEntry({
    required this.id,
    required this.at,
    required this.path,
    required this.method,
    AppNetworkLogState? state,
    required this.request,
    this.response,
    this.error,
    this.durationMs,
  }) : state =
           state ??
           (error != null
               ? AppNetworkLogState.error
               : response != null
               ? AppNetworkLogState.success
               : AppNetworkLogState.pending);

  /// 捕获到的完整 URL；手动接入未提供 `url` 时回退为 [path]。
  String get url => request['url']?.toString() ?? path;

  /// 请求 URL 中的 host；相对路径或非法 URL 返回空字符串。
  String get host => Uri.tryParse(url)?.host ?? '';

  /// HTTP 状态码。Pending、取消和无响应的传输错误通常为 `null`。
  int? get statusCode {
    final raw = response?['statusCode'] ?? error?['statusCode'];
    return switch (raw) {
      int value => value,
      num value => value.toInt(),
      String value => int.tryParse(value),
      _ => null,
    };
  }

  /// 将当前捕获到的请求转换为可复制的 cURL 文本，不会发送请求。
  ///
  /// Dio 拦截器捕获的 Header 使用已经经过 [AppLogsConfig.maskHeaders] 处理的值。
  String toCurl() {
    final arguments = <String>[
      'curl',
      '--request ${_shellQuote(method.toUpperCase())}',
      '--url ${_shellQuote(url)}',
    ];

    final headers = request['headers'];
    if (headers is Map) {
      for (final entry in headers.entries) {
        arguments.add(
          '--header ${_shellQuote('${entry.key}: ${entry.value}')}',
        );
      }
    }

    final data = request['data'];
    if (data is Map && data['type'] == 'FormData') {
      _appendFormDataCurlArguments(arguments, data);
    } else if (data != null) {
      final encoded = data is String ? data : _encodeCurlData(data);
      arguments.add('--data-raw ${_shellQuote(encoded)}');
    }

    return arguments.join(' \\\n  ');
  }

  AppNetworkLogEntry copyWith({
    DateTime? at,
    String? path,
    String? method,
    AppNetworkLogState? state,
    Map<String, Object?>? request,
    Map<String, Object?>? response,
    Map<String, Object?>? error,
    int? durationMs,
  }) {
    return AppNetworkLogEntry(
      id: id,
      at: at ?? this.at,
      path: path ?? this.path,
      method: method ?? this.method,
      state:
          state ??
          (error != null
              ? AppNetworkLogState.error
              : response != null
              ? AppNetworkLogState.success
              : this.state),
      request: request ?? this.request,
      response: response ?? this.response,
      error: error ?? this.error,
      durationMs: durationMs ?? this.durationMs,
    );
  }
}

String _shellQuote(String value) => "'${value.replaceAll("'", "'\"'\"'")}'";

String _encodeCurlData(Object data) {
  try {
    return jsonEncode(data);
  } catch (_) {
    return data.toString();
  }
}

void _appendFormDataCurlArguments(
  List<String> arguments,
  Map<Object?, Object?> data,
) {
  final fields = data['fields'];
  if (fields is Iterable) {
    for (final rawField in fields) {
      if (rawField is! Map) continue;
      final key = rawField['key']?.toString();
      if (key == null || key.isEmpty) continue;
      arguments.add('--form ${_shellQuote('$key=${rawField['value'] ?? ''}')}');
    }
  }

  final files = data['files'];
  if (files is Iterable) {
    for (final rawFile in files) {
      if (rawFile is! Map) continue;
      final key = rawFile['key']?.toString();
      if (key == null || key.isEmpty) continue;
      final filename = rawFile['filename']?.toString() ?? 'file';
      arguments.add('--form ${_shellQuote('$key=@<$filename>')}');
    }
  }
}

// ============================================================================
// 全局日志存储（AppLogStore）
// ============================================================================

/// 全局日志存储，单例模式，继承 ChangeNotifier 以驱动 UI 响应更新。
class AppLogStore extends ChangeNotifier {
  AppLogStore._();

  /// 全局唯一实例
  static final AppLogStore instance = AppLogStore._();

  // ── 内部存储 ──────────────────────────────────────────────────────────────
  final List<AppConsoleLogEntry> _console = <AppConsoleLogEntry>[];
  final List<AppErrorLogEntry> _errors = <AppErrorLogEntry>[];
  final Map<String, AppNetworkLogEntry> _networkById =
      <String, AppNetworkLogEntry>{};
  final List<String> _networkOrder = <String>[];

  bool _notifyScheduledAfterFrame = false;
  int _nextErrorId = 1;

  // ── 只读访问器 ────────────────────────────────────────────────────────────
  List<AppConsoleLogEntry> get console => List.unmodifiable(_console);

  List<AppErrorLogEntry> get errors => List.unmodifiable(_errors);

  /// 尚未在 Error Tab 中查看的错误卡片数。
  int get unreadErrorCount => _errors.where((entry) => entry.isUnread).length;

  List<AppNetworkLogEntry> get network => List.unmodifiable(
    _networkOrder.map((id) => _networkById[id]).whereType<AppNetworkLogEntry>(),
  );

  // ── 清除操作 ──────────────────────────────────────────────────────────────
  void clearConsole() {
    if (_console.isEmpty) return;
    _console.clear();
    _notifyListenersSafely();
  }

  void clearErrors() {
    if (_errors.isEmpty) return;
    _errors.clear();
    _notifyListenersSafely();
  }

  /// 将当前 Error 卡片全部标记为已读。
  void markErrorsRead() {
    if (!_errors.any((entry) => entry.isUnread)) return;
    for (var index = 0; index < _errors.length; index++) {
      final entry = _errors[index];
      if (entry.isUnread) {
        _errors[index] = entry.copyWith(isUnread: false);
      }
    }
    _notifyListenersSafely();
  }

  void clearNetwork() {
    if (_networkById.isEmpty) return;
    _networkById.clear();
    _networkOrder.clear();
    _notifyListenersSafely();
  }

  // ── 写入操作 ──────────────────────────────────────────────────────────────

  void logConsole({
    required AppLogLevel level,
    required String message,
    String? tag,
    Map<String, Object?>? extra,
  }) {
    if (!AppLogsConfig.enabled) return;
    if (level.index < AppLogsConfig.consoleMinLevel.index) return;
    _console.insert(
      0,
      AppConsoleLogEntry(
        at: DateTime.now(),
        level: level,
        message: message,
        tag: tag,
        extra: extra,
      ),
    );
    final maxEntries = AppLogsConfig.maxConsoleEntries;
    if (_console.length > maxEntries) {
      _console.removeRange(maxEntries, _console.length);
    }
    _notifyListenersSafely();
  }

  void logError({
    required AppErrorLogSource source,
    required String message,
    StackTrace? stackTrace,
    DateTime? at,
  }) {
    if (!AppLogsConfig.enabled) return;
    final occurredAt = at ?? DateTime.now();
    final stackTraceText = stackTrace?.toString();
    final mergeWindow = AppLogsConfig.errorMergeWindow;
    final mergeIndex =
        AppLogsConfig.mergeRepeatedErrors
            ? _errors.indexWhere((entry) {
              final elapsed = occurredAt.difference(entry.at);
              return entry.source == source &&
                  entry.message == message &&
                  entry.stackTrace == stackTraceText &&
                  !elapsed.isNegative &&
                  elapsed <= mergeWindow;
            })
            : -1;

    if (mergeIndex >= 0) {
      final previous = _errors.removeAt(mergeIndex);
      _errors.insert(
        0,
        previous.copyWith(
          at: occurredAt,
          occurrenceCount: previous.occurrenceCount + 1,
          isUnread: true,
        ),
      );
    } else {
      _errors.insert(
        0,
        AppErrorLogEntry(
          id: _nextErrorId++,
          at: occurredAt,
          source: source,
          message: message,
          stackTrace: stackTraceText,
          isUnread: true,
        ),
      );
    }

    final maxEntries = AppLogsConfig.maxErrorEntries;
    if (_errors.length > maxEntries) {
      _errors.removeRange(maxEntries, _errors.length);
    }
    _notifyListenersSafely();
  }

  void logNetworkRequest({
    required String id,
    required DateTime at,
    required String path,
    required String method,
    required Map<String, Object?> request,
  }) {
    if (!AppLogsConfig.enabled) return;
    _upsertNetwork(
      id,
      AppNetworkLogEntry(
        id: id,
        at: at,
        path: path,
        method: method,
        request: request,
      ),
    );
  }

  void logNetworkResponse({
    required String id,
    required DateTime at,
    Map<String, Object?>? request,
    required Map<String, Object?> response,
    int? durationMs,
  }) {
    if (!AppLogsConfig.enabled) return;
    final existing = _networkById[id];
    final next = (existing ??
            AppNetworkLogEntry(
              id: id,
              at: at,
              path: request?['path']?.toString() ?? '',
              method: request?['method']?.toString() ?? '',
              request: request ?? const <String, Object?>{},
            ))
        .copyWith(
          at: at,
          state: AppNetworkLogState.success,
          request: request ?? existing?.request,
          response: response,
          durationMs: durationMs,
        );
    _upsertNetwork(id, next);
  }

  void logNetworkError({
    required String id,
    required DateTime at,
    Map<String, Object?>? request,
    required Map<String, Object?> error,
    Map<String, Object?>? response,
    int? durationMs,
    AppNetworkLogState state = AppNetworkLogState.error,
  }) {
    if (!AppLogsConfig.enabled) return;
    final existing = _networkById[id];
    final next = (existing ??
            AppNetworkLogEntry(
              id: id,
              at: at,
              path: request?['path']?.toString() ?? '',
              method: request?['method']?.toString() ?? '',
              request: request ?? const <String, Object?>{},
            ))
        .copyWith(
          at: at,
          state: state,
          request: request ?? existing?.request,
          response: response ?? existing?.response,
          error: error,
          durationMs: durationMs,
        );
    _upsertNetwork(id, next);
  }

  // ── 内部工具方法 ──────────────────────────────────────────────────────────

  void _upsertNetwork(String id, AppNetworkLogEntry entry) {
    _networkById[id] = entry;
    _networkOrder.remove(id);
    _networkOrder.insert(0, id);
    final maxEntries = AppLogsConfig.maxNetworkEntries;
    if (_networkOrder.length > maxEntries) {
      final overflow = _networkOrder.sublist(maxEntries);
      for (final removeId in overflow) {
        _networkById.remove(removeId);
      }
      _networkOrder.removeRange(maxEntries, _networkOrder.length);
    }
    _notifyListenersSafely();
  }

  void _notifyListenersSafely() {
    final schedulerPhase = SchedulerBinding.instance.schedulerPhase;
    if (schedulerPhase == SchedulerPhase.persistentCallbacks) {
      if (_notifyScheduledAfterFrame) return;
      _notifyScheduledAfterFrame = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notifyScheduledAfterFrame = false;
        notifyListeners();
      });
      return;
    }

    notifyListeners();
  }
}

// ============================================================================
// 静态日志入口（AppConsoleLogger）
// ============================================================================

/// Console 日志的静态调用入口。
///
/// ```dart
/// AppConsoleLogger.info('用户登录成功', tag: 'auth');
/// AppConsoleLogger.error('提现失败', tag: 'wallet', extra: {'code': 500});
/// ```
class AppConsoleLogger {
  AppConsoleLogger._();

  static void log(
    AppLogLevel level,
    String message, {
    String? tag,
    Map<String, Object?>? extra,
  }) {
    AppLogStore.instance.logConsole(
      level: level,
      message: message,
      tag: tag,
      extra: extra,
    );
  }

  static void debug(
    String message, {
    String? tag,
    Map<String, Object?>? extra,
  }) => log(AppLogLevel.debug, message, tag: tag, extra: extra);

  static void info(
    String message, {
    String? tag,
    Map<String, Object?>? extra,
  }) => log(AppLogLevel.info, message, tag: tag, extra: extra);

  static void warn(
    String message, {
    String? tag,
    Map<String, Object?>? extra,
  }) => log(AppLogLevel.warn, message, tag: tag, extra: extra);

  static void error(
    String message, {
    String? tag,
    Map<String, Object?>? extra,
  }) => log(AppLogLevel.error, message, tag: tag, extra: extra);
}
