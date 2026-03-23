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
    // ── 步骤 4：使用 AppConsoleLogger 写入日志 ─────────────────────────────
    //
    // 提供 4 个静态方法，对应 4 种日志级别：
    //   AppConsoleLogger.debug()  → 调试信息
    //   AppConsoleLogger.info()   → 正常流程
    //   AppConsoleLogger.warn()   → 警告（非致命）
    //   AppConsoleLogger.error()  → 错误（需要排查）
    //
    // 参数：
    //   message → 日志文本（必填）
    //   tag     → 标签（可选），用于分类和搜索
    //   extra   → 附加数据（可选），Map 类型，在面板中展开显示

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

  /// GET 请求 — 成功场景
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

  /// POST 请求 — 成功场景（演示请求体记录）
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

  /// GET 请求 — 404 错误场景
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

  /// GET 请求 — 超时场景
  Future<void> _requestTimeout() async {
    _showSnackBar('正在请求超时测试（10.255.255.1）...');

    // 创建一个专用的 Dio 实例，设置极短的超时时间
    final timeoutDio = Dio(
      BaseOptions(
        // 使用一个不可达的 IP 地址触发连接超时
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

  /// 手动写入 Network 日志（不通过 Dio 拦截器）
  ///
  /// 适用于使用 http、graphql_flutter 等非 Dio 网络库的场景。
  /// 你可以直接调用 AppLogStore 的 API 手动记录请求。
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
