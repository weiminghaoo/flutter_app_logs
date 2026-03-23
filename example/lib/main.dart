import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_logs/flutter_app_logs.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 初始化配置
  AppLogsConfig.init(
    enabled: true,
    consoleMinLevel: AppLogLevel.debug,
    onCopySuccess: (_) {
      // 接入你自己的 Toast 实现
      debugPrint('Copied to clipboard!');
    },
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_app_logs Demo',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF908FFF)),
      // 2. 包裹 AppLogPanelHost
      builder: (context, child) {
        return AppLogPanelHost(child: child ?? const SizedBox.shrink());
      },
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  late final Dio _dio;

  @override
  void initState() {
    super.initState();
    _dio = Dio(BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'));
    // 3. 添加 Dio 拦截器
    _dio.interceptors.add(AppLogsDioInterceptor());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('flutter_app_logs Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: () {
                AppConsoleLogger.debug('Debug message', tag: 'demo');
                AppConsoleLogger.info('Info message', tag: 'demo');
                AppConsoleLogger.warn('Warning message', tag: 'demo');
                AppConsoleLogger.error(
                  'Error message',
                  tag: 'demo',
                  extra: {'code': 500, 'detail': 'Something went wrong'},
                );
              },
              child: const Text('Write Console Logs'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                try {
                  await _dio.get('/posts/1');
                } catch (e) {
                  debugPrint('Request error: $e');
                }
              },
              child: const Text('GET /posts/1'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                try {
                  await _dio.get('/invalid-endpoint-404');
                } catch (e) {
                  debugPrint('Request error: $e');
                }
              },
              child: const Text('GET /invalid (Error)'),
            ),
          ],
        ),
      ),
    );
  }
}
