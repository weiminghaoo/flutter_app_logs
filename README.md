简体中文 | [English](README_EN.md)

# flutter_app_logs

[![pub package](https://img.shields.io/pub/v/flutter_app_logs.svg)](https://pub.dev/packages/flutter_app_logs)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Flutter 应用内调试面板 — 通过可拖拽浮动按钮 + 底部面板，实时查看 **Console 日志** 和 **Network 请求记录**，类似前端的 [vConsole](https://github.com/niconi/vConsole)。

<p align="center">
  <img src="https://raw.githubusercontent.com/wildcatDownstairs/flutter_app_logs/main/doc/screenshot_console.png" width="280" alt="Console Tab" />
  &nbsp;&nbsp;
  <img src="https://raw.githubusercontent.com/wildcatDownstairs/flutter_app_logs/main/doc/screenshot_network.png" width="280" alt="Network Tab" />
</p>

---

## 特性

- **Console 日志面板** — 查看 debug / info / warn / error 四级日志，支持级别筛选和关键词搜索
- **Network 日志面板** — 检查 HTTP 请求、响应和错误，显示耗时、Headers、请求体、响应体
- **可拖拽浮动按钮** — 在屏幕任意位置拖动，不遮挡业务 UI
- **内置 Dio 拦截器** — `AppLogsDioInterceptor` 一行代码接入，自动记录请求全生命周期
- **生产环境零开销** — `enabled: false` 时所有写入短路，UI 直接返回 `child`
- **可自定义主题** — 通过 `AppLogsTheme` 覆盖面板全部配色
- **敏感 Header 脱敏** — `maskHeaders: true` 自动遮盖 Authorization / Token / Cookie 等
- **复制回调** — 不内置 Toast；通过 `onCopySuccess` 回调让接入方自行决定提示方式

## 安装

```yaml
dependencies:
  flutter_app_logs: ^0.1.0
```

```bash
flutter pub get
```

## 快速开始

**3 步接入，开箱即用：**

### 1. 初始化配置

```dart
import 'package:flutter_app_logs/flutter_app_logs.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 通常在 main() 中调用一次
  AppLogsConfig.init(
    enabled: true, // 生产环境设为 false（或 kDebugMode）
    consoleMinLevel: AppLogLevel.debug,
    onCopySuccess: (text) => showToast('已复制'),
  );

  runApp(const MyApp());
}
```

### 2. 包裹 AppLogPanelHost

```dart
MaterialApp(
  builder: (context, child) {
    return AppLogPanelHost(child: child ?? const SizedBox.shrink());
  },
  home: const MyHomePage(),
);
```

### 3. 写日志 & 添加拦截器

```dart
// Console 日志 — 在业务代码的任意位置调用
AppConsoleLogger.info('用户登录成功', tag: 'auth');
AppConsoleLogger.error('支付失败', tag: 'payment', extra: {'code': 500});

// Network 日志 — 添加 Dio 拦截器即可
final dio = Dio();
dio.interceptors.add(AppLogsDioInterceptor());
```

完成！点击屏幕上的浮动按钮即可打开日志面板。

## API 参考

### AppLogsConfig

全局配置类，通过 `AppLogsConfig.init()` 一次性初始化。

| 属性 | 类型 | 默认值 | 说明 |
|---|---|---|---|
| `enabled` | `bool` | `false` | 主开关 — 控制所有日志写入和 UI 渲染 |
| `consoleMinLevel` | `AppLogLevel` | `.debug` | Console 最低日志级别 |
| `maskHeaders` | `bool` | `false` | 是否脱敏敏感 Headers（Authorization 等） |
| `onCopySuccess` | `void Function(String)?` | `null` | 复制成功后的回调 |
| `theme` | `AppLogsTheme` | `defaultTheme` | 自定义主题色板 |

### AppLogLevel

日志级别枚举，按严重程度从低到高排列：

```
debug < info < warn < error
```

低于 `consoleMinLevel` 的日志不会被写入。

### AppConsoleLogger

静态方法，在任意位置调用：

```dart
AppConsoleLogger.debug('调试信息', tag: 'module');
AppConsoleLogger.info('正常信息', tag: 'module');
AppConsoleLogger.warn('警告信息', tag: 'module');
AppConsoleLogger.error('错误信息', tag: 'module', extra: {'key': 'value'});
```

| 参数 | 类型 | 说明 |
|---|---|---|
| `message` | `String` | 日志文本（必填） |
| `tag` | `String?` | 标签，用于分类和搜索 |
| `extra` | `Map<String, dynamic>?` | 附加数据，在面板中展开显示 |

### AppLogStore

单例（`AppLogStore.instance`），基于 `ChangeNotifier`。

```dart
final store = AppLogStore.instance;

// 写入
store.logConsole(level: AppLogLevel.info, message: '...', tag: 'tag');
store.logNetworkRequest(id: '1', at: DateTime.now(), path: '/api', method: 'GET', request: {...});
store.logNetworkResponse(id: '1', at: DateTime.now(), request: {...}, response: {...}, durationMs: 120);
store.logNetworkError(id: '1', at: DateTime.now(), request: {...}, error: {...});

// 读取（只读）
List<AppConsoleLogEntry> logs = store.console;
List<AppNetworkLogEntry> reqs = store.network;

// 清空
store.clearConsole();
store.clearNetwork();
```

容量限制：Console 500 条、Network 200 条，超出自动淘汰最旧记录。

### AppLogsDioInterceptor

标准 Dio `Interceptor` 子类，一行代码添加：

```dart
dio.interceptors.add(AppLogsDioInterceptor());
```

自动记录 request → response / error 全生命周期，包含耗时、Headers、请求体、响应体。

建议放在拦截器链的**最前面**（在业务拦截器之前），以捕获完整的请求信息。

### AppLogPanelHost

包裹应用根节点的 Widget。显示可拖拽浮动按钮，点击打开 Console / Network 双标签面板。

```dart
AppLogPanelHost(child: yourApp)
```

当 `enabled` 为 `false` 时直接返回 `child`，零开销。

## 自定义主题

```dart
AppLogsConfig.init(
  enabled: true,
  theme: const AppLogsTheme(
    primary: Color(0xFF6366F1),   // 主色调 — 浮动按钮、TabBar 激活色
    info: Color(0xFF0EA5E9),      // 信息色 — info 级别、GET 方法
    success: Color(0xFF22C55E),   // 成功色 — POST 方法、<500ms 耗时
    debug: Color(0xFF9CA3AF),     // 灰色 — debug 级别
    error: Color(0xFFEF4444),     // 错误色 — error 级别、DELETE 方法
    patch: Color(0xFFA855F7),     // 紫色 — PATCH 方法
  ),
);
```

## 非 Dio 网络库集成

如果使用 `http`、`graphql_flutter` 等其他网络库，可直接调用 `AppLogStore` 手动记录：

```dart
final id = 'req-${DateTime.now().millisecondsSinceEpoch}';

// 请求发出时
AppLogStore.instance.logNetworkRequest(
  id: id,
  at: DateTime.now(),
  path: '/api/users',
  method: 'GET',
  request: {'method': 'GET', 'url': 'https://example.com/api/users'},
);

// 响应返回后
AppLogStore.instance.logNetworkResponse(
  id: id,
  at: DateTime.now(),
  request: {'method': 'GET', 'url': 'https://example.com/api/users'},
  response: {'statusCode': 200, 'data': {...}},
  durationMs: 150,
);
```

## 生产环境安全

```dart
AppLogsConfig.init(
  // 推荐：使用 kDebugMode 自动判断
  enabled: kDebugMode,
);
```

当 `enabled: false` 时：
- `AppLogPanelHost` 直接返回 `child`，不渲染任何额外 UI
- `AppLogStore` 的所有写入方法立即返回（短路）
- `AppConsoleLogger` 的所有静态方法不执行任何操作
- `AppLogsDioInterceptor` 仅调用 `handler.next()`，不记录数据

**零运行时开销，无需条件编译或 tree-shaking。**

## FAQ

### Q: 为什么不内置 Toast？

插件不引入任何 Toast/SnackBar 依赖，避免与宿主应用的 Toast 实现冲突。通过 `onCopySuccess` 回调，你可以接入自己的 Toast 方案（如 `fluttertoast`、`SnackBar`、或自定义 Overlay）。

### Q: 浮动按钮会遮挡业务 UI 吗？

浮动按钮支持自由拖拽到屏幕任意位置。如果仍然觉得碍事，在生产环境设置 `enabled: false` 即可完全移除。

### Q: 日志有数量上限吗？

Console 上限 500 条，Network 上限 200 条。超出后自动淘汰最旧的记录（FIFO）。

### Q: 与现有的 Dio 拦截器冲突吗？

不冲突。`AppLogsDioInterceptor` 是一个标准的 Dio `Interceptor`，它只读取请求/响应数据，不修改任何内容，始终调用 `handler.next()` 传递给下一个拦截器。

### Q: 支持哪些 Flutter 版本？

Flutter >= 3.29.0，Dart SDK >= 3.7.0。

## 许可证

MIT — 详见 [LICENSE](LICENSE)
