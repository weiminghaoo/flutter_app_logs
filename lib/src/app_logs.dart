// ============================================================================
// app_logs.dart — 调试日志系统 Library 主文件
//
// 【对外使用方式】
//   在任何需要调试日志的地方，只需导入 barrel export：
//   ```dart
//   import 'package:flutter_app_logs/flutter_app_logs.dart';
//   ```
//   就可以使用所有公开 API：
//   - [AppConsoleLogger]   — 写入 Console 日志（debug / info / warn / error）
//   - [AppLogStore]        — 全局日志数据存储（单例）
//   - [AppLogPanelHost]    — 调试面板宿主 Widget（包裹应用根节点）
//   - [AppLogsConfig]      — 全局配置（enabled / minLevel / onCopy / theme）
//   - [AppLogsDioInterceptor] — Dio 拦截器（自动记录网络请求）
// ============================================================================

// ── Dart SDK ──────────────────────────────────────────────────────────────
import 'dart:async'; // Timer（复制提示自动隐藏）
import 'dart:convert'; // JSON 序列化（_prettyJson 使用）
import 'dart:math' as math; // math.max（用于 clamp 边界保护）
import 'dart:ui' as ui; // PlatformDispatcher（捕获未处理异步异常）

// ── Flutter framework ──────────────────────────────────────────────────────
import 'package:flutter/foundation.dart'; // compute（大 JSON 文本格式化放到异步路径）
import 'package:flutter/material.dart'; // Widget、Material 组件树（含 ChangeNotifier）
import 'package:flutter/scheduler.dart'; // SchedulerPhase（构建阶段延迟通知）
import 'package:flutter/services.dart'; // Clipboard（复制到剪贴板）

// ── 插件内部依赖 ───────────────────────────────────────────────────────────
import 'app_log_level.dart'; // AppLogLevel enum
import 'app_logs_config.dart'; // AppLogsConfig 全局配置
// ignore: unused_import
import 'app_logs_theme.dart'; // Part 文件通过 AppLogsConfig.theme 间接使用 AppLogsTheme 类型

// ── Part 文件声明 ──────────────────────────────────────────────────────────
part 'app_log_internal_theme.dart'; // 内部面板色板常量
part 'app_log_models.dart'; // 数据层（Entry / Store / Logger）
part 'app_log_error_capture.dart'; // Flutter / debugPrint 错误捕获
part 'app_log_copy_feedback.dart'; // 复制 helper + 面板内提示层
part 'app_log_widgets.dart'; // 通用 UI 组件（FilterChip / JsonBlock）
part 'app_log_panel_host.dart'; // 宿主 Widget（浮动按钮 + 面板控制）
part 'app_log_bottom_panel.dart'; // 底部面板（_BottomPanel）
part 'app_log_console_tab.dart'; // Console 标签页（_ConsoleTab）
part 'app_log_error_tab.dart'; // Error 标签页（_ErrorTab）
part 'app_log_network_tab.dart'; // Network 标签页（_NetworkTab / _NetworkDetail）
