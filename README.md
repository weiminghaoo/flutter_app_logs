# flutter_app_logs

简体中文 | [English](README_EN.md)

[![pub package](https://img.shields.io/pub/v/flutter_app_logs.svg)](https://pub.dev/packages/flutter_app_logs)
[![GitHub](https://img.shields.io/badge/GitHub-wildcatDownstairs/flutter__app__logs-181717?logo=github&logoColor=white)](https://github.com/wildcatDownstairs/flutter_app_logs)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Flutter 应用内调试面板 — 通过可拖拽浮动按钮 + 底部面板，实时查看 **Console 日志** 和 **Network 请求记录**，类似前端的 [vConsole](https://github.com/niconi/vConsole)。

<p align="center">
  <img src="https://raw.githubusercontent.com/wildcatDownstairs/flutter_app_logs/main/doc/screenshot_network_list.png" width="260" alt="Network 请求列表" />
  &nbsp;
  <img src="https://raw.githubusercontent.com/wildcatDownstairs/flutter_app_logs/main/doc/screenshot_network_detail.png" width="260" alt="Network 请求详情" />
  &nbsp;
  <img src="https://raw.githubusercontent.com/wildcatDownstairs/flutter_app_logs/main/doc/screenshot_console.png" width="260" alt="Console 日志" />
  &nbsp;
  <img src="https://raw.githubusercontent.com/wildcatDownstairs/flutter_app_logs/main/doc/screenshot_firebase_flow.png" width="260" alt="FireBase 登录流程" />
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
  flutter_app_logs: ^0.1.5
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

## 完整示例

下面是 `example/lib/main.dart` 的核心接入代码（初始化 → 根节点包裹 → Dio 拦截器）：

```dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_logs/flutter_app_logs.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 步骤 1：初始化 ─────────────────────────────────────────────────────
  AppLogsConfig.init(
    enabled: true,                       // 生产环境设为 false（或 kDebugMode）
    consoleMinLevel: AppLogLevel.debug,
    maskHeaders: true,                   // 脱敏 Authorization / Token / Cookie
    onCopySuccess: (text) => print('已复制 ${text.length} 字符'),
  );

  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ── 步骤 2：在 builder 中包裹 AppLogPanelHost ───────────────────────
      builder: (context, child) {
        return AppLogPanelHost(child: child ?? const SizedBox.shrink());
      },
      home: const DemoHomePage(),
    );
  }
}

class _DemoHomePageState extends State<DemoHomePage> {
  late final Dio _dio;

  @override
  void initState() {
    super.initState();
    // ── 步骤 3：Dio 拦截器 ────────────────────────────────────────────────
    _dio = Dio(BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'));
    _dio.interceptors.add(AppLogsDioInterceptor());
  }
  // ...
}
```

<details>
<summary>📄 查看完整 example/lib/main.dart（510 行，含 Console / Network / 手动写入等全部演示）</summary>

```dart
// ignore_for_file: avoid_print

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_logs/flutter_app_logs.dart';

// ============================================================================
// flutter_app_logs 完整示例
//
// 本示例演示了 flutter_app_logs 插件的全部核心功能：
//
//   1. 初始化配置（AppLogsConfig.init）
//   2. 在根节点包裹 AppLogPanelHost 显示浮动调试按钮
//   3. 使用 AppConsoleLogger 写入 debug / info / warn / error 日志
//   4. 使用 AppLogsDioInterceptor 自动记录 Dio 网络请求
//   5. 自定义主题色板（AppLogsTheme）
//   6. 敏感 Header 脱敏（maskHeaders）
//   7. 复制成功回调（onCopySuccess）
//
// 运行方式：
//   cd example
//   flutter run
//
// 运行后，点击屏幕右下角的浮动按钮即可打开日志面板。
// ============================================================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 步骤 1：初始化 flutter_app_logs ──────────────────────────────────────
  //
  // 通常在 main() 中调用一次即可。生产环境设为 enabled: false（或 kDebugMode）。
  //
  // 参数说明：
  //   enabled         → 主开关。关闭后所有日志写入和 UI 渲染均短路，零开销。
  //   consoleMinLevel → 低于此级别的 Console 日志不会被记录。
  //   maskHeaders     → 是否脱敏 Authorization / Token / Cookie 等敏感 Header。
  //   onCopySuccess   → 复制成功后的回调。插件不内置 Toast，由接入方决定提示方式。
  //   theme           → 自定义面板配色。不传则使用默认主题。
  AppLogsConfig.init(
    enabled: true,
    consoleMinLevel: AppLogLevel.debug,
    maskHeaders: true,
    onCopySuccess: (copiedText) {
      // 这里演示一个简单的 print，实际项目中替换为你的 Toast / SnackBar
      print('[onCopySuccess] 已复制 ${copiedText.length} 个字符');
    },
    // 可选：自定义主题色板（取消注释即可使用）
    // theme: const AppLogsTheme(
    //   primary: Color(0xFF6366F1),   // Indigo
    //   info: Color(0xFF0EA5E9),      // Sky blue
    //   success: Color(0xFF22C55E),   // Green
    //   debug: Color(0xFF9CA3AF),     // Grey
    //   error: Color(0xFFEF4444),     // Red
    //   patch: Color(0xFFA855F7),     // Purple
    // ),
  );

  runApp(const ExampleApp());
}

// ============================================================================
// ExampleApp — 应用根节点
// ============================================================================

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_app_logs Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF908FFF),
        useMaterial3: true,
      ),

      // ── 步骤 2：在 builder 中包裹 AppLogPanelHost ─────────────────────
      //
      // AppLogPanelHost 会在屏幕上显示一个可拖拽的浮动按钮。
      // 点击按钮可打开底部面板，查看 Console 和 Network 日志。
      //
      // 当 AppLogsConfig.enabled == false 时，AppLogPanelHost 直接返回
      // child，不渲染任何额外 UI，生产环境零开销。
      builder: (context, child) {
        return AppLogPanelHost(child: child ?? const SizedBox.shrink());
      },
      home: const DemoHomePage(),
    );
  }
}

// ============================================================================
// DemoHomePage — 演示页面
// ============================================================================

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({super.key});

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> {
  late final Dio _dio;

  @override
  void initState() {
    super.initState();

    // ── 步骤 3：创建 Dio 实例并添加拦截器 ────────────────────────────────
    //
    // AppLogsDioInterceptor 是一个标准的 Dio Interceptor，放入拦截器链即可。
    // 它会自动记录每个请求的生命周期（request → response / error），
    // 包括耗时、Headers、请求体、响应体等信息。
    //
    // 建议放在拦截器链的最前面（或至少在业务拦截器之前），
    // 以便捕获完整的请求信息。
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://jsonplaceholder.typicode.com',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          // 演示 maskHeaders 功能：这些 Header 在面板中会被脱敏显示
          'Authorization':
              'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.example',
          'X-Device-Id': 'device-abc-123-xyz',
        },
      ),
    );
    _dio.interceptors.add(AppLogsDioInterceptor());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('flutter_app_logs'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 提示文字 ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '点击右下角的浮动按钮打开日志面板 →\n'
                  '点击下方按钮产生日志数据',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
              ),
              const SizedBox(height: 24),

              // ── Section: Console Logs ──────────────────────────────────
              _buildSectionHeader('Console 日志'),
              const SizedBox(height: 12),
              _buildActionButton(
                label: '写入 4 种级别的日志',
                color: const Color(0xFF908FFF),
                onPressed: _writeConsoleLogs,
              ),
              const SizedBox(height: 8),
              _buildActionButton(
                label: '写入带 extra 数据的日志',
                color: const Color(0xFF7F63C0),
                onPressed: _writeConsoleLogsWithExtra,
              ),
              const SizedBox(height: 8),
              _buildActionButton(
                label: '批量写入 20 条日志',
                color: const Color(0xFF6B7280),
                onPressed: _writeBatchConsoleLogs,
              ),
              const SizedBox(height: 24),

              // ── Section: Network Logs ──────────────────────────────────
              _buildSectionHeader('Network 日志'),
              const SizedBox(height: 12),
              _buildActionButton(
                label: 'GET /posts/1（成功）',
                color: const Color(0xFF006AB6),
                onPressed: _requestGetSuccess,
              ),
              const SizedBox(height: 8),
              _buildActionButton(
                label: 'POST /posts（成功）',
                color: const Color(0xFF00A565),
                onPressed: _requestPostSuccess,
              ),
              const SizedBox(height: 8),
              _buildActionButton(
                label: 'GET /not-found（404 错误）',
                color: const Color(0xFFFF1010),
                onPressed: _requestGetError,
              ),
              const SizedBox(height: 8),
              _buildActionButton(
                label: 'GET 超时测试（连接超时）',
                color: const Color(0xFFFF6B35),
                onPressed: _requestTimeout,
              ),
              const SizedBox(height: 24),

              // ── Section: 直接操作 AppLogStore ──────────────────────────
              _buildSectionHeader('直接操作 AppLogStore'),
              const SizedBox(height: 12),
              _buildActionButton(
                label: '手动写入 Network 日志',
                color: const Color(0xFF0EA5E9),
                onPressed: _writeNetworkLogManually,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      label: '清空 Console',
                      color: const Color(0xFF9CA3AF),
                      onPressed: () {
                        AppLogStore.instance.clearConsole();
                        _showSnackBar('Console 日志已清空');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      label: '清空 Network',
                      color: const Color(0xFF9CA3AF),
                      onPressed: () {
                        AppLogStore.instance.clearNetwork();
                        _showSnackBar('Network 日志已清空');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Console 日志示例
  // ══════════════════════════════════════════════════════════════════════════

  /// 写入 4 种级别的 Console 日志
  void _writeConsoleLogs() {
    AppConsoleLogger.debug('这是一条 debug 日志', tag: 'example');
    AppConsoleLogger.info('这是一条 info 日志', tag: 'example');
    AppConsoleLogger.warn('这是一条 warn 日志', tag: 'example');
    AppConsoleLogger.error('这是一条 error 日志', tag: 'example');
    _showSnackBar('已写入 4 条 Console 日志');
  }

  /// 写入带 extra 数据的日志（演示 tag 和 extra 的使用）
  void _writeConsoleLogsWithExtra() {
    AppConsoleLogger.info(
      '用户登录成功',
      tag: 'auth',
      extra: {
        'userId': 'usr_12345',
        'loginMethod': 'email',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    AppConsoleLogger.warn(
      '接口返回了非预期的字段',
      tag: 'api',
      extra: {
        'endpoint': '/api/v1/user/profile',
        'unexpectedField': 'legacy_name',
        'suggestion': '后端可能需要更新 API 文档',
      },
    );

    AppConsoleLogger.error(
      '支付流程异常中断',
      tag: 'payment',
      extra: {
        'orderId': 'ORD-2024-001',
        'step': 'verify_card',
        'errorCode': 'CARD_DECLINED',
        'amount': 9800,
        'currency': 'JPY',
      },
    );

    _showSnackBar('已写入 3 条带 extra 的日志');
  }

  /// 批量写入 20 条日志（演示搜索和滚动）
  void _writeBatchConsoleLogs() {
    for (var i = 1; i <= 20; i++) {
      final level = AppLogLevel.values[i % 4];
      switch (level) {
        case AppLogLevel.debug:
          AppConsoleLogger.debug('批量日志 #$i — debug 级别', tag: 'batch');
        case AppLogLevel.info:
          AppConsoleLogger.info('批量日志 #$i — info 级别', tag: 'batch');
        case AppLogLevel.warn:
          AppConsoleLogger.warn('批量日志 #$i — warn 级别', tag: 'batch');
        case AppLogLevel.error:
          AppConsoleLogger.error('批量日志 #$i — error 级别', tag: 'batch');
      }
    }
    _showSnackBar('已写入 20 条 Console 日志');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Network 日志示例（通过 Dio 拦截器自动记录）
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _requestGetSuccess() async {
    _showSnackBar('正在请求 GET /posts/1 ...');
    try {
      final response = await _dio.get('/posts/1');
      AppConsoleLogger.info(
        'GET /posts/1 成功: statusCode=${response.statusCode}',
        tag: 'network',
      );
    } on DioException catch (e) {
      AppConsoleLogger.error('GET /posts/1 失败: ${e.message}', tag: 'network');
    }
  }

  Future<void> _requestPostSuccess() async {
    _showSnackBar('正在请求 POST /posts ...');
    try {
      final response = await _dio.post(
        '/posts',
        data: {
          'title': 'flutter_app_logs 测试',
          'body': '这是一条通过 Dio 发送的 POST 请求，用于演示请求体记录功能。',
          'userId': 1,
        },
      );
      AppConsoleLogger.info(
        'POST /posts 成功: statusCode=${response.statusCode}',
        tag: 'network',
      );
    } on DioException catch (e) {
      AppConsoleLogger.error('POST /posts 失败: ${e.message}', tag: 'network');
    }
  }

  Future<void> _requestGetError() async {
    _showSnackBar('正在请求 GET /not-found ...');
    try {
      await _dio.get('/not-found-endpoint-12345');
    } on DioException catch (e) {
      AppConsoleLogger.error(
        'GET /not-found 失败: ${e.response?.statusCode ?? e.type.name}',
        tag: 'network',
      );
    }
  }

  Future<void> _requestTimeout() async {
    _showSnackBar('正在请求超时测试（10.255.255.1）...');
    final timeoutDio = Dio(
      BaseOptions(
        baseUrl: 'https://10.255.255.1',
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
      ),
    );
    timeoutDio.interceptors.add(AppLogsDioInterceptor());

    try {
      await timeoutDio.get('/timeout-test');
    } on DioException catch (e) {
      AppConsoleLogger.error(
        '超时测试结果: ${e.type.name} — ${e.message}',
        tag: 'network',
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 直接操作 AppLogStore（高级用法）
  // ══════════════════════════════════════════════════════════════════════════

  void _writeNetworkLogManually() {
    final id = 'manual-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    // 第一步：记录请求发出
    AppLogStore.instance.logNetworkRequest(
      id: id,
      at: now,
      path: '/api/v1/manual/test',
      method: 'PUT',
      request: {
        'method': 'PUT',
        'baseUrl': 'https://example.com',
        'path': '/api/v1/manual/test',
        'url': 'https://example.com/api/v1/manual/test',
        'headers': {'Content-Type': 'application/json'},
        'data': {'key': 'value', 'timestamp': now.toIso8601String()},
      },
    );

    // 第二步：模拟 200ms 后收到响应
    Future.delayed(const Duration(milliseconds: 200), () {
      AppLogStore.instance.logNetworkResponse(
        id: id,
        at: DateTime.now(),
        request: {
          'method': 'PUT',
          'path': '/api/v1/manual/test',
          'url': 'https://example.com/api/v1/manual/test',
        },
        response: {
          'statusCode': 200,
          'data': {'success': true, 'message': '这是手动写入的 Network 日志'},
        },
        durationMs: 200,
      );
    });

    _showSnackBar('已手动写入 Network 日志（PUT 请求）');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // UI 辅助
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1F2937),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontSize: 15)),
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
```

</details>

> 也可以直接运行 example：`cd example && flutter run`

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
