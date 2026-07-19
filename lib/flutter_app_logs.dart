/// flutter_app_logs — 应用内调试日志面板
///
/// 在 Flutter 应用中提供一个可拖拽的浮动调试面板，
/// 用于查看 Network 请求、主动记录的 Console 日志和 Flutter Error，类似 vConsole。
///
/// ## 快速开始
///
/// ```dart
/// import 'package:flutter_app_logs/flutter_app_logs.dart';
///
/// // 1. 初始化配置（通常在 main() 或 App.initState 中）
/// AppLogsConfig.init(
///   enabled: true,
///   consoleMinLevel: AppLogLevel.debug,
///   onCopySuccess: (text) => showToast('Copied!'),
/// );
///
/// // 2. 在应用根节点包裹 AppLogPanelHost
/// AppLogPanelHost(child: MyApp());
///
/// // 3. 在业务代码中写日志
/// AppConsoleLogger.info('用户登录成功', tag: 'auth');
///
/// // 4. 添加 Dio 拦截器自动记录网络请求
/// dio.interceptors.add(AppLogsDioInterceptor());
/// ```
library;

// ── 配置 & 枚举 ────────────────────────────────────────────────────────────
export 'src/app_log_level.dart';
export 'src/app_logs_config.dart';
export 'src/app_logs_theme.dart';

// ── 核心 API（日志存储、Console Logger、面板 Widget）─────────────────────────
export 'src/app_logs.dart'
    show
        AppLogStore,
        AppConsoleLogger,
        AppLogPanelHost,
        AppConsoleLogEntry,
        AppErrorLogEntry,
        AppErrorLogSource,
        AppNetworkLogEntry;

// ── Dio 拦截器 ─────────────────────────────────────────────────────────────
export 'src/dio/app_logs_dio_interceptor.dart';
