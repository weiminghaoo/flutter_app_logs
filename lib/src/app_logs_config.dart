import 'app_log_level.dart';
import 'app_logs_theme.dart';

/// 自动 Error 捕获规则。
///
/// 默认保持 0.1.x 的捕获行为，同时允许宿主应用关闭某类全局错误、扩展
/// `debugPrint` 错误块的起始规则，或忽略包含指定模式的自动错误。
class AppErrorCaptureRules {
  /// 是否捕获 [FlutterError.onError] 上报的 framework 错误。
  final bool captureFlutterErrors;

  /// 是否捕获根 isolate 中未处理的异步异常。
  final bool captureUnhandledErrors;

  /// 是否捕获 `debugPrint` 输出的多行错误块。
  final bool captureConsoleErrors;

  /// 是否启用插件内置的 Network / App / Unhandled Exception 起始规则。
  final bool includeDefaultConsolePatterns;

  /// 额外的 `debugPrint` 错误块起始模式。
  ///
  /// `String` 使用包含匹配，`RegExp` 使用正则匹配。
  final List<Pattern> additionalConsolePatterns;

  /// 自动捕获后需要忽略的消息模式，适用于所有自动 Error 来源。
  ///
  /// 手动调用 `AppLogStore.logError()` 不受此规则影响。
  final List<Pattern> ignoredPatterns;

  const AppErrorCaptureRules({
    this.captureFlutterErrors = true,
    this.captureUnhandledErrors = true,
    this.captureConsoleErrors = true,
    this.includeDefaultConsolePatterns = true,
    this.additionalConsolePatterns = const <Pattern>[],
    this.ignoredPatterns = const <Pattern>[],
  });
}

/// 全局配置类，控制日志面板的行为和外观。
///
/// 在应用启动时调用一次 [init] 即可：
///
/// ```dart
/// AppLogsConfig.init(
///   enabled: true,
///   consoleMinLevel: AppLogLevel.debug,
///   onCopySuccess: (text) => showToast('Copied!'),
/// );
/// ```
///
/// 所有属性都提供了合理的默认值，最小化集成成本。
class AppLogsConfig {
  AppLogsConfig._();

  /// 是否启用日志面板。
  ///
  /// 设为 `false` 时：
  /// - [AppLogPanelHost] 直接返回 child，零开销
  /// - [AppLogStore] 的所有写入方法短路返回
  /// - [AppConsoleLogger] 的所有静态方法不做任何事
  static bool enabled = false;

  /// Console 日志的最低显示级别。
  ///
  /// 低于此级别的日志不会被写入 [AppLogStore]，也不会在面板中显示。
  /// 默认 [AppLogLevel.debug]（显示所有级别）。
  static AppLogLevel consoleMinLevel = AppLogLevel.debug;

  /// 是否遮盖 Network 日志中的敏感 Headers（如 Authorization）。
  ///
  /// 默认 `false`（开发调试时需要看到完整 Headers）。
  static bool maskHeaders = false;

  /// Console 最多保留的日志条数。默认 500，设为 0 时不保留。
  static int maxConsoleEntries = 500;

  /// Network 最多保留的请求条数。默认 200，设为 0 时不保留。
  static int maxNetworkEntries = 200;

  /// Error 最多保留的错误卡片数。默认 200，设为 0 时不保留。
  static int maxErrorEntries = 200;

  /// 单个 Network request / response body 捕获后的最大字符数。
  ///
  /// 默认 100,000。超过后保存带 `...(truncated)` 的文本；这也意味着
  /// Copy as cURL 只能使用已捕获的截断内容。设为 0 时不捕获 body。
  static int maxNetworkBodyCharacters = 100000;

  /// 自动 Error 捕获规则。
  static AppErrorCaptureRules errorCaptureRules = const AppErrorCaptureRules();

  /// 是否归并短时间内完全相同的 Error。默认开启。
  static bool mergeRepeatedErrors = true;

  /// 重复 Error 的归并时间窗口。默认 30 秒。
  static Duration errorMergeWindow = const Duration(seconds: 30);

  /// 复制成功后的回调。
  ///
  /// 插件内部在 JSON 块 copy、日志条目长按复制、请求路径复制后调用此回调。
  /// 使用方可以在这里接入自己的 Toast/SnackBar 实现。
  ///
  /// 示例：
  /// ```dart
  /// onCopySuccess: (text) => AppToast.show('コピーしました'),
  /// ```
  ///
  /// 如果不设置，复制操作会静默完成（不显示任何提示）。
  static void Function(String copiedText)? onCopySuccess;

  /// 自定义主题色板。
  ///
  /// 不传则使用 [AppLogsTheme.defaultTheme]。
  static AppLogsTheme theme = AppLogsTheme.defaultTheme;

  /// 一次性初始化所有配置。
  ///
  /// 建议在 `main()` 或 `App.initState()` 中调用一次。
  static void init({
    bool enabled = false,
    AppLogLevel consoleMinLevel = AppLogLevel.debug,
    bool maskHeaders = false,
    int maxConsoleEntries = 500,
    int maxNetworkEntries = 200,
    int maxErrorEntries = 200,
    int maxNetworkBodyCharacters = 100000,
    AppErrorCaptureRules errorCaptureRules = const AppErrorCaptureRules(),
    bool mergeRepeatedErrors = true,
    Duration errorMergeWindow = const Duration(seconds: 30),
    void Function(String copiedText)? onCopySuccess,
    AppLogsTheme theme = AppLogsTheme.defaultTheme,
  }) {
    if (maxConsoleEntries < 0) {
      throw ArgumentError.value(
        maxConsoleEntries,
        'maxConsoleEntries',
        'must be greater than or equal to 0',
      );
    }
    if (maxNetworkEntries < 0) {
      throw ArgumentError.value(
        maxNetworkEntries,
        'maxNetworkEntries',
        'must be greater than or equal to 0',
      );
    }
    if (maxErrorEntries < 0) {
      throw ArgumentError.value(
        maxErrorEntries,
        'maxErrorEntries',
        'must be greater than or equal to 0',
      );
    }
    if (maxNetworkBodyCharacters < 0) {
      throw ArgumentError.value(
        maxNetworkBodyCharacters,
        'maxNetworkBodyCharacters',
        'must be greater than or equal to 0',
      );
    }
    if (errorMergeWindow.isNegative) {
      throw ArgumentError.value(
        errorMergeWindow,
        'errorMergeWindow',
        'must not be negative',
      );
    }

    AppLogsConfig.enabled = enabled;
    AppLogsConfig.consoleMinLevel = consoleMinLevel;
    AppLogsConfig.maskHeaders = maskHeaders;
    AppLogsConfig.maxConsoleEntries = maxConsoleEntries;
    AppLogsConfig.maxNetworkEntries = maxNetworkEntries;
    AppLogsConfig.maxErrorEntries = maxErrorEntries;
    AppLogsConfig.maxNetworkBodyCharacters = maxNetworkBodyCharacters;
    AppLogsConfig.errorCaptureRules = errorCaptureRules;
    AppLogsConfig.mergeRepeatedErrors = mergeRepeatedErrors;
    AppLogsConfig.errorMergeWindow = errorMergeWindow;
    AppLogsConfig.onCopySuccess = onCopySuccess;
    AppLogsConfig.theme = theme;
  }
}
