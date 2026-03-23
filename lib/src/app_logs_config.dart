import 'app_log_level.dart';
import 'app_logs_theme.dart';

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
    void Function(String copiedText)? onCopySuccess,
    AppLogsTheme theme = AppLogsTheme.defaultTheme,
  }) {
    AppLogsConfig.enabled = enabled;
    AppLogsConfig.consoleMinLevel = consoleMinLevel;
    AppLogsConfig.maskHeaders = maskHeaders;
    AppLogsConfig.onCopySuccess = onCopySuccess;
    AppLogsConfig.theme = theme;
  }
}
