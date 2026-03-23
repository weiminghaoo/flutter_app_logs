/// 日志级别枚举。
///
/// 按严重程度从低到高排列：debug < info < warn < error。
/// [index] 值用于级别过滤比较：level.index >= minLevel.index 才会被记录。
enum AppLogLevel {
  /// 调试级别 — 开发期详细信息，生产环境通常过滤掉
  debug,

  /// 信息级别 — 关键业务路径的正常流程记录
  info,

  /// 警告级别 — 非致命异常/降级，可以继续执行
  warn,

  /// 错误级别 — 错误/异常，需要关注和排查
  error,
}
