import 'package:flutter/material.dart';

/// 日志面板的可自定义主题色板。
///
/// 使用方可以通过 [AppLogsConfig.init] 传入自定义 [AppLogsTheme]，
/// 覆盖默认配色以匹配自己应用的设计系统。
///
/// 不传则使用 [defaultTheme]（暖白系 + 语义色）。
class AppLogsTheme {
  // ── 语义色（用于日志级别、HTTP 方法等）──────────────────────────────────
  /// 主色调 — 浮动按钮背景、TabBar 激活色、搜索框聚焦边框
  final Color primary;

  /// 信息色 — info 级别、GET 方法
  final Color info;

  /// 成功色 — POST 方法、请求 <500ms 耗时
  final Color success;

  /// 灰色 — debug 级别
  final Color debug;

  /// 错误色 — error 级别、DELETE 方法、请求 >1000ms 耗时
  final Color error;

  /// 紫色 — PATCH 方法
  final Color patch;

  const AppLogsTheme({
    this.primary = const Color(0xFF908FFF),
    this.info = const Color(0xFF006AB6),
    this.success = const Color(0xFF00A565),
    this.debug = const Color(0xFF9CA3AF),
    this.error = const Color(0xFFFF1010),
    this.patch = const Color(0xFF7F63C0),
  });

  /// 默认主题色板，沿用 Claude-inspired 暖白系设计。
  static const defaultTheme = AppLogsTheme();
}
