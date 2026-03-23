// ============================================================================
// app_log_internal_theme.dart
//
// 【职责】定义调试日志面板专用的内部颜色常量。
//
// 这些色值仅在 logging 模块内部使用，外部业务不应直接依赖。
// 语义色（日志级别、HTTP 方法）通过 AppLogsTheme 从外部注入。
// ============================================================================

part of 'app_logs.dart';

// ── 面板主色板（Claude-inspired 米黄暖白系）───────────────────────────────
abstract final class _LP {
  // ── 背景色 ──────────────────────────────────────────────────────────────
  /// 面板主背景 — 暖奶油白
  static const bg = Color(0xFFF5F3EE);

  /// 卡片/条目背景 — 比 bg 稍深的暖白
  static const paper = Color(0xFFEDEAE3);

  // ── 边框色 ──────────────────────────────────────────────────────────────
  /// 暖灰边框
  static const border = Color(0xFFE5DECE);

  // ── 文字色 ──────────────────────────────────────────────────────────────
  /// 主文字 — 深暖黑
  static const textPri = Color(0xFF1A1614);

  /// 次要文字 — 暖中灰
  static const textSec = Color(0xFF7A726A);

  // ── Badge（方法/标签徽标）────────────────────────────────────────────────
  /// 方法徽标背景 — 浅桃粉
  static const badgeBg = Color(0xFFFDE8D8);

  /// 方法徽标文字 — 橙棕
  static const badgeText = Color(0xFFC05621);

  // ── 手柄 ────────────────────────────────────────────────────────────────
  /// 拖拽手柄胶囊颜色 — 暖灰
  static const handle = Color(0xFFD4CDBF);
}

// ── JSON 语法高亮色（亮色主题，与面板暖白系配色一致）─────────────────────
abstract final class _JC {
  /// 代码块背景
  static const bg = Color(0xFFF2F0EB);

  /// 代码块上边框
  static const border = Color(0xFFD9D3C7);

  /// "json" 语言标签文字 / 折叠省略提示文字
  static const label = Color(0xFF9B9284);

  // ── JSON 值类型着色 ──────────────────────────────────────────────────────
  /// JSON key（属性名）— 深蓝
  static const key = Color(0xFF005CC5);

  /// string 类型的值 — 森林绿
  static const string_ = Color(0xFF22863A);

  /// number 类型的值 — 紫色
  static const number = Color(0xFF6F42C1);

  /// boolean / null 值 — 橙色
  static const bool_ = Color(0xFFE36209);

  /// 括号 `{} []`、冒号 `:`、逗号 `,` — 暖灰
  static const punct = Color(0xFF6A6055);

  /// 默认文字 — 暖近黑
  static const base = Color(0xFF1A1614);
}
