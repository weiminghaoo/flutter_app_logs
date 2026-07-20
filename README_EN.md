# flutter_app_logs

[简体中文](README.md) | English

[![pub package](https://img.shields.io/pub/v/flutter_app_logs.svg)](https://pub.dev/packages/flutter_app_logs)
[![GitHub](https://img.shields.io/badge/GitHub-wildcatDownstairs/flutter__app__logs-181717?logo=github&logoColor=white)](https://github.com/wildcatDownstairs/flutter_app_logs)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

An in-app debug panel for Flutter — inspect **Network requests**, opt-in **Console logs**, and Flutter **Errors** via a draggable floating button + bottom sheet UI, similar to [vConsole](https://github.com/niconi/vConsole) for web.

<p align="center">
  <img src="https://raw.githubusercontent.com/wildcatDownstairs/flutter_app_logs/main/doc/screenshot_network_list.png" width="260" alt="Network request list" />
  &nbsp;
  <img src="https://raw.githubusercontent.com/wildcatDownstairs/flutter_app_logs/main/doc/screenshot_network_detail.png" width="260" alt="Network request detail" />
  &nbsp;
  <img src="https://raw.githubusercontent.com/wildcatDownstairs/flutter_app_logs/main/doc/screenshot_console.png" width="260" alt="Console logs" />
  &nbsp;
  <img src="https://raw.githubusercontent.com/wildcatDownstairs/flutter_app_logs/main/doc/screenshot_error.png" width="260" alt="Error panel" />
</p>

---

## Features

- **Console Log Panel** — view lifecycle and flow logs explicitly recorded with `AppConsoleLogger`, with level filtering and keyword search
- **Error Panel** — automatically captures `FlutterError`, unhandled root-isolate exceptions, and multiline `debugPrint` errors, with configurable rules, source filters, duplicate merging, and unread counts
- **Network Log Panel** — inspect HTTP requests, responses, and errors with timing, headers, and body, plus combined method / status / host / duration filters
- **Request lifecycle** — requests appear as Pending immediately, then update to success, error, or Cancelled
- **Copy as cURL** — copy a reproducible cURL command from request details without replaying it automatically
- **Draggable FAB** — freely drag the floating button anywhere on screen
- **Built-in Dio Interceptor** — `AppLogsDioInterceptor`, one line to integrate
- **Zero overhead in production** — when `enabled: false`, all writes short-circuit and UI returns `child` directly
- **Customizable theme** — override all panel colors via `AppLogsTheme`
- **Sensitive header masking** — `maskHeaders: true` masks Authorization / Token / Cookie headers
- **Copy callback** — no built-in toast; provide `onCopySuccess` to use your own notification

## Installation

```yaml
dependencies:
  flutter_app_logs: ^0.2.0
```

```bash
flutter pub get
```

## Quick Start

**3 steps to integrate:**

### 1. Initialize

```dart
import 'package:flutter_app_logs/flutter_app_logs.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogsConfig.init(
    enabled: true, // set to false in production (or use kDebugMode)
    consoleMinLevel: AppLogLevel.debug,
    onCopySuccess: (text) => showToast('Copied!'),
  );

  runApp(const MyApp());
}
```

### 2. Wrap with AppLogPanelHost

```dart
MaterialApp(
  builder: (context, child) {
    return AppLogPanelHost(child: child ?? const SizedBox.shrink());
  },
  home: const MyHomePage(),
);
```

`AppLogPanelHost` enables Error capture while mounted. `AppConsoleLogger` remains an explicit API for lifecycle and flow logs, and those records stay separate from captured errors.

### 3. Log & intercept

```dart
// Console logs — call from anywhere
AppConsoleLogger.info('User logged in', tag: 'auth');
AppConsoleLogger.error('Payment failed', tag: 'payment', extra: {'code': 500});

// Network logs — just add the Dio interceptor
final dio = Dio();
dio.interceptors.add(AppLogsDioInterceptor());
```

Done! Tap the floating button on screen to open the debug panel.

## Network Panel Features

<p align="center">
  <img src="https://raw.githubusercontent.com/wildcatDownstairs/flutter_app_logs/main/doc/screenshot_network_filters.png" width="300" alt="Combined Network filters" />
  &nbsp;
  <img src="https://raw.githubusercontent.com/wildcatDownstairs/flutter_app_logs/main/doc/screenshot_network_curl.png" width="300" alt="Network details and Copy as cURL" />
</p>

### Combined Method / Status / Host / Duration filters

Tap the search icon in the panel header to expand the Network toolbar. Filters can be combined across:

- `Method`: dynamically populated from the captured GET, POST, and other methods
- `Status`: Pending, 2xx, 3xx, 4xx, 5xx, transport Error without an HTTP response, and Cancelled
- `Host`: dynamically populated from complete request URLs
- `Duration`: `<500ms`, `500ms–1s`, and `≥1s`

Filter groups use AND semantics. The search field can still match URL, path, host, method, and status at the same time. Filtering only reads locally captured logs and never sends another request.

### Pending and Cancelled

With `AppLogsDioInterceptor`, `onRequest` immediately creates a Pending entry. The same entry is updated when a response or error arrives. Requests cancelled through Dio's `CancelToken` appear as Cancelled:

```dart
final dio = Dio();

// Put it before business interceptors so Pending is recorded early and
// forwarded responses / errors can complete the same entry.
dio.interceptors.add(AppLogsDioInterceptor());
```

If a business interceptor returns its own response or consumes an error without forwarding the corresponding handler, later interceptors cannot observe that event. Place the log interceptor first in the chain for the most complete lifecycle.

### Copy as cURL

Open Network details and tap the terminal icon on the right to copy cURL. The adjacent regular copy icon copies only the complete URL. The generated command includes the method, complete URL, captured headers, and a JSON / string body or FormData fields.

Enable sensitive-header masking during initialization so copied commands do not expose live credentials:

```dart
AppLogsConfig.init(
  enabled: kDebugMode,
  maskHeaders: true,
  onCopySuccess: (text) => showToast('Copied!'),
);
```

Notes:

- Copy as cURL only writes to the clipboard; it never sends or replays the request.
- With `maskHeaders: true`, Authorization, Token, Cookie, Device ID, and App Check values are masked before cURL generation. Replace them yourself if the command must call a real endpoint.
- Regular Dio `FormData` fields become `--form` arguments. File bytes are not read; file fields use an `@<filename>` placeholder that must be replaced with a local file path before execution.
- `onCopySuccess` is optional. The package has no Toast dependency; connect your own Toast, SnackBar, or Overlay if the host app needs copy feedback.

## Error Panel Integration

### Automatic capture

After both `AppLogsConfig.init(enabled: true)` and the root-level `AppLogPanelHost` wrapper are in place, the Error panel automatically captures these sources while `AppLogPanelHost` is mounted:

- Flutter framework errors reported through `FlutterError.onError`
- Unhandled root-isolate exceptions reported through `PlatformDispatcher.onError`
- Multiline `debugPrint` error blocks beginning with `🚨 [Network Error]`, `🚨 [App Error...]`, `Unhandled Exception:`, or `[ERROR:flutter/...] Unhandled Exception:`

The package forwards each error to the previously installed handler and preserves the original console output. Consecutive `debugPrint` lines are grouped into one entry, so existing output like this needs no migration:

```dart
debugPrint('🚨 [Network Error] POST https://api.example.com/orders');
debugPrint('   Status: 500');
debugPrint('   Message: Server error');
debugPrint('   Response: {"code": 500}');
```

`AppConsoleLogger.error(...)` still writes to the **Console** panel. Use it for explicit lifecycle, business-flow, and expected-state logs; runtime exceptions and captured console error blocks belong to the separate **Error** panel.

### Configure automatic capture rules

Use `AppErrorCaptureRules` to control each automatic source and extend or ignore `debugPrint` error patterns:

```dart
AppLogsConfig.init(
  enabled: kDebugMode,
  errorCaptureRules: AppErrorCaptureRules(
    captureFlutterErrors: true,
    captureUnhandledErrors: true,
    captureConsoleErrors: true,
    includeDefaultConsolePatterns: true,
    additionalConsolePatterns: [
      RegExp(r'^FATAL:'),
      '[Payment Failure]',
    ],
    ignoredPatterns: [
      'A known harmless framework warning',
    ],
  ),
);
```

- `additionalConsolePatterns` identifies new multiline error starts. Strings use contains matching; `RegExp` values use regular-expression matching.
- `ignoredPatterns` filters the completed automatic message for Flutter, Unhandled, and Console sources.
- Capture switches and ignored patterns affect automatic capture only. Explicit `AppLogStore.logError()` calls are always retained.
- The package still forwards previous Flutter / Platform handlers and preserves console output whether or not an error is captured.

### Manual error injection

If business code catches an exception before it reaches Flutter's global error handlers, write it directly to the Error panel:

```dart
try {
  await submitOrder();
} catch (error, stackTrace) {
  AppLogStore.instance.logError(
    source: AppErrorLogSource.console,
    message: error.toString(),
    stackTrace: stackTrace,
  );
}
```

Use `.flutter` for framework errors, `.unhandled` for unhandled exceptions, and `.console` for console- or application-provided errors.

### Read and clear data

```dart
final List<AppErrorLogEntry> errors = AppLogStore.instance.errors;
final int unreadCount = AppLogStore.instance.unreadErrorCount;

// Explicitly mark current Error entries as read.
AppLogStore.instance.markErrorsRead();

// Clears only Error entries; Network and Console remain unchanged.
AppLogStore.instance.clearErrors();
```

Identical `source + message + stackTrace` values merge into one card within 30 seconds by default and display an `×N` count. `firstOccurredAt` stores the first time, `at` stores the latest time, and `occurrenceCount` stores the total. A repeated read error becomes unread again, while the badge counts cards rather than occurrences. Opening the Error Tab marks the currently visible errors as read.

Expand the Error search toolbar to filter by Flutter, Unhandled, or Console source. Console entries can still display NETWORK, APP, or CONSOLE labels on their cards.

<p align="center">
  <img src="https://raw.githubusercontent.com/wildcatDownstairs/flutter_app_logs/main/doc/screenshot_error_filters.png" width="360" alt="Error source filters" />
</p>

Duplicate merging is configurable:

```dart
AppLogsConfig.init(
  mergeRepeatedErrors: true,
  errorMergeWindow: const Duration(seconds: 30),
);
```

### Log capacity and Network body length

```dart
AppLogsConfig.init(
  maxConsoleEntries: 500,
  maxNetworkEntries: 200,
  maxErrorEntries: 200,
  maxNetworkBodyCharacters: 100000,
);
```

- Set any entry capacity to `0` to retain no records for that category.
- The oldest records are evicted first when a limit is exceeded.
- `maxNetworkBodyCharacters` applies to both request and response bodies; set it to `0` to capture no body.
- Oversized bodies are stored as text ending in `...(truncated)`. Details and Copy as cURL use captured data, so a truncated cURL command may not replay the complete request.

## Full Example

Here's the core integration code from `example/lib/main.dart` (init → root wrapper → Dio interceptor):

```dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_logs/flutter_app_logs.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Step 1: Initialize ─────────────────────────────────────────────────
  AppLogsConfig.init(
    enabled: true,                       // set false in production (or kDebugMode)
    consoleMinLevel: AppLogLevel.debug,
    maskHeaders: true,                   // mask Authorization / Token / Cookie
    onCopySuccess: (text) => print('Copied ${text.length} chars'),
  );

  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ── Step 2: Wrap with AppLogPanelHost ────────────────────────────────
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
    // ── Step 3: Dio interceptor ───────────────────────────────────────────
    _dio = Dio(BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'));
    _dio.interceptors.add(AppLogsDioInterceptor());
  }
  // ...
}
```

<details>
<summary>View complete example/lib/main.dart (510 lines — Console / Network / manual writes & more)</summary>

```dart
// ignore_for_file: avoid_print

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_logs/flutter_app_logs.dart';

// ============================================================================
// flutter_app_logs Full Example
//
// This example demonstrates all core features of the flutter_app_logs plugin:
//
//   1. Initialize configuration (AppLogsConfig.init)
//   2. Wrap root with AppLogPanelHost to show the floating debug button
//   3. Write debug / info / warn / error logs via AppConsoleLogger
//   4. Auto-record Dio network requests via AppLogsDioInterceptor
//   5. Custom theme palette (AppLogsTheme)
//   6. Sensitive header masking (maskHeaders)
//   7. Copy success callback (onCopySuccess)
//
// To run:
//   cd example
//   flutter run
//
// After launch, tap the floating button in the bottom-right corner to open
// the debug panel.
// ============================================================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Step 1: Initialize flutter_app_logs ───────────────────────────────────
  //
  // Call once in main(). Set enabled: false (or kDebugMode) in production.
  //
  // Parameters:
  //   enabled         → Master switch. When off, all writes and UI are no-ops.
  //   consoleMinLevel → Console logs below this level are not recorded.
  //   maskHeaders     → Mask Authorization / Token / Cookie headers.
  //   onCopySuccess   → Callback after copy. No built-in toast — you decide.
  //   theme           → Custom panel colors. Uses defaults if omitted.
  AppLogsConfig.init(
    enabled: true,
    consoleMinLevel: AppLogLevel.debug,
    maskHeaders: true,
    onCopySuccess: (copiedText) {
      // Simple print for demo — replace with your Toast / SnackBar in real apps
      print('[onCopySuccess] Copied ${copiedText.length} characters');
    },
    // Optional: custom theme palette (uncomment to use)
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
// ExampleApp — App root
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

      // ── Step 2: Wrap with AppLogPanelHost ─────────────────────────────
      //
      // AppLogPanelHost shows a draggable floating button on screen.
      // Tap to open the bottom panel with Console and Network tabs.
      //
      // When AppLogsConfig.enabled == false, AppLogPanelHost returns
      // child directly — zero overhead in production.
      builder: (context, child) {
        return AppLogPanelHost(child: child ?? const SizedBox.shrink());
      },
      home: const DemoHomePage(),
    );
  }
}

// ============================================================================
// DemoHomePage — Demo page
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

    // ── Step 3: Create Dio instance and add interceptor ─────────────────
    //
    // AppLogsDioInterceptor is a standard Dio Interceptor. Just add it.
    // It auto-records each request lifecycle (request → response / error),
    // including timing, headers, request body, and response body.
    //
    // Recommended: place first in the interceptor chain (before business
    // interceptors) to capture complete request information.
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://jsonplaceholder.typicode.com',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          // Demo maskHeaders: these headers will be masked in the panel
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
              // ── Hint text ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Tap the floating button (bottom-right) to open the panel →\n'
                  'Tap buttons below to generate log data',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
              ),
              const SizedBox(height: 24),

              // ── Section: Console Logs ──────────────────────────────────
              _buildSectionHeader('Console Logs'),
              const SizedBox(height: 12),
              _buildActionButton(
                label: 'Write 4 log levels',
                color: const Color(0xFF908FFF),
                onPressed: _writeConsoleLogs,
              ),
              const SizedBox(height: 8),
              _buildActionButton(
                label: 'Write logs with extra data',
                color: const Color(0xFF7F63C0),
                onPressed: _writeConsoleLogsWithExtra,
              ),
              const SizedBox(height: 8),
              _buildActionButton(
                label: 'Batch write 20 logs',
                color: const Color(0xFF6B7280),
                onPressed: _writeBatchConsoleLogs,
              ),
              const SizedBox(height: 24),

              // ── Section: Network Logs ──────────────────────────────────
              _buildSectionHeader('Network Logs'),
              const SizedBox(height: 12),
              _buildActionButton(
                label: 'GET /posts/1 (success)',
                color: const Color(0xFF006AB6),
                onPressed: _requestGetSuccess,
              ),
              const SizedBox(height: 8),
              _buildActionButton(
                label: 'POST /posts (success)',
                color: const Color(0xFF00A565),
                onPressed: _requestPostSuccess,
              ),
              const SizedBox(height: 8),
              _buildActionButton(
                label: 'GET /not-found (404 error)',
                color: const Color(0xFFFF1010),
                onPressed: _requestGetError,
              ),
              const SizedBox(height: 8),
              _buildActionButton(
                label: 'GET timeout test',
                color: const Color(0xFFFF6B35),
                onPressed: _requestTimeout,
              ),
              const SizedBox(height: 24),

              // ── Section: Direct AppLogStore access ─────────────────────
              _buildSectionHeader('Direct AppLogStore Access'),
              const SizedBox(height: 12),
              _buildActionButton(
                label: 'Manual network log write',
                color: const Color(0xFF0EA5E9),
                onPressed: _writeNetworkLogManually,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      label: 'Clear Console',
                      color: const Color(0xFF9CA3AF),
                      onPressed: () {
                        AppLogStore.instance.clearConsole();
                        _showSnackBar('Console logs cleared');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      label: 'Clear Network',
                      color: const Color(0xFF9CA3AF),
                      onPressed: () {
                        AppLogStore.instance.clearNetwork();
                        _showSnackBar('Network logs cleared');
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
  // Console log examples
  // ══════════════════════════════════════════════════════════════════════════

  void _writeConsoleLogs() {
    AppConsoleLogger.debug('This is a debug log', tag: 'example');
    AppConsoleLogger.info('This is an info log', tag: 'example');
    AppConsoleLogger.warn('This is a warn log', tag: 'example');
    AppConsoleLogger.error('This is an error log', tag: 'example');
    _showSnackBar('Wrote 4 console logs');
  }

  void _writeConsoleLogsWithExtra() {
    AppConsoleLogger.info(
      'User login successful',
      tag: 'auth',
      extra: {
        'userId': 'usr_12345',
        'loginMethod': 'email',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    AppConsoleLogger.warn(
      'API returned unexpected field',
      tag: 'api',
      extra: {
        'endpoint': '/api/v1/user/profile',
        'unexpectedField': 'legacy_name',
        'suggestion': 'Backend may need to update API docs',
      },
    );

    AppConsoleLogger.error(
      'Payment flow interrupted',
      tag: 'payment',
      extra: {
        'orderId': 'ORD-2024-001',
        'step': 'verify_card',
        'errorCode': 'CARD_DECLINED',
        'amount': 9800,
        'currency': 'JPY',
      },
    );

    _showSnackBar('Wrote 3 logs with extra data');
  }

  void _writeBatchConsoleLogs() {
    for (var i = 1; i <= 20; i++) {
      final level = AppLogLevel.values[i % 4];
      switch (level) {
        case AppLogLevel.debug:
          AppConsoleLogger.debug('Batch log #$i — debug level', tag: 'batch');
        case AppLogLevel.info:
          AppConsoleLogger.info('Batch log #$i — info level', tag: 'batch');
        case AppLogLevel.warn:
          AppConsoleLogger.warn('Batch log #$i — warn level', tag: 'batch');
        case AppLogLevel.error:
          AppConsoleLogger.error('Batch log #$i — error level', tag: 'batch');
      }
    }
    _showSnackBar('Wrote 20 console logs');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Network log examples (auto-recorded via Dio interceptor)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _requestGetSuccess() async {
    _showSnackBar('Requesting GET /posts/1 ...');
    try {
      final response = await _dio.get('/posts/1');
      AppConsoleLogger.info(
        'GET /posts/1 success: statusCode=${response.statusCode}',
        tag: 'network',
      );
    } on DioException catch (e) {
      AppConsoleLogger.error('GET /posts/1 failed: ${e.message}', tag: 'network');
    }
  }

  Future<void> _requestPostSuccess() async {
    _showSnackBar('Requesting POST /posts ...');
    try {
      final response = await _dio.post(
        '/posts',
        data: {
          'title': 'flutter_app_logs test',
          'body': 'A POST request sent via Dio to demo request body logging.',
          'userId': 1,
        },
      );
      AppConsoleLogger.info(
        'POST /posts success: statusCode=${response.statusCode}',
        tag: 'network',
      );
    } on DioException catch (e) {
      AppConsoleLogger.error('POST /posts failed: ${e.message}', tag: 'network');
    }
  }

  Future<void> _requestGetError() async {
    _showSnackBar('Requesting GET /not-found ...');
    try {
      await _dio.get('/not-found-endpoint-12345');
    } on DioException catch (e) {
      AppConsoleLogger.error(
        'GET /not-found failed: ${e.response?.statusCode ?? e.type.name}',
        tag: 'network',
      );
    }
  }

  Future<void> _requestTimeout() async {
    _showSnackBar('Requesting timeout test (10.255.255.1)...');
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
        'Timeout test result: ${e.type.name} — ${e.message}',
        tag: 'network',
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Direct AppLogStore access (advanced usage)
  // ══════════════════════════════════════════════════════════════════════════

  void _writeNetworkLogManually() {
    final id = 'manual-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

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
          'data': {'success': true, 'message': 'Manually written network log'},
        },
        durationMs: 200,
      );
    });

    _showSnackBar('Manually wrote network log (PUT request)');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // UI helpers
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

> You can also run the example directly: `cd example && flutter run`

## API Reference

### AppLogsConfig

Global configuration, initialized once via `AppLogsConfig.init()`.

| Property | Type | Default | Description |
|---|---|---|---|
| `enabled` | `bool` | `false` | Master switch — gates all writes and UI rendering |
| `consoleMinLevel` | `AppLogLevel` | `.debug` | Minimum console log level |
| `maskHeaders` | `bool` | `false` | Mask sensitive headers (Authorization, etc.) |
| `maxConsoleEntries` | `int` | `500` | Maximum Console entries; 0 retains none |
| `maxNetworkEntries` | `int` | `200` | Maximum Network entries; 0 retains none |
| `maxErrorEntries` | `int` | `200` | Maximum Error cards; 0 retains none |
| `maxNetworkBodyCharacters` | `int` | `100000` | Maximum characters per request / response body; 0 captures none |
| `errorCaptureRules` | `AppErrorCaptureRules` | capture all | Automatic Error sources, additional patterns, and ignored patterns |
| `mergeRepeatedErrors` | `bool` | `true` | Merge repeated Error entries |
| `errorMergeWindow` | `Duration` | `30s` | Duplicate Error merge window |
| `onCopySuccess` | `void Function(String)?` | `null` | Called after clipboard copy |
| `theme` | `AppLogsTheme` | `defaultTheme` | Custom color palette |

### AppLogLevel

Log level enum, ordered by severity:

```
debug < info < warn < error
```

Logs below `consoleMinLevel` are not recorded.

### AppConsoleLogger

Static methods, callable from anywhere:

```dart
AppConsoleLogger.debug('Debug details', tag: 'module');
AppConsoleLogger.info('Normal info', tag: 'module');
AppConsoleLogger.warn('Warning', tag: 'module');
AppConsoleLogger.error('Error', tag: 'module', extra: {'key': 'value'});
```

| Parameter | Type | Description |
|---|---|---|
| `message` | `String` | Log text (required) |
| `tag` | `String?` | Tag for categorization and search |
| `extra` | `Map<String, dynamic>?` | Additional data, displayed expanded in panel |

### AppLogStore

Singleton (`AppLogStore.instance`), backed by `ChangeNotifier`.

```dart
final store = AppLogStore.instance;

// Write
store.logConsole(level: AppLogLevel.info, message: '...', tag: 'tag');
store.logError(source: AppErrorLogSource.console, message: '...', stackTrace: stackTrace);
store.logNetworkRequest(id: '1', at: DateTime.now(), path: '/api', method: 'GET', request: {...});
store.logNetworkResponse(id: '1', at: DateTime.now(), request: {...}, response: {...}, durationMs: 120);
store.logNetworkError(id: '1', at: DateTime.now(), request: {...}, error: {...});

// Read (read-only)
List<AppConsoleLogEntry> logs = store.console;
List<AppErrorLogEntry> errors = store.errors;
List<AppNetworkLogEntry> reqs = store.network;
int unreadErrors = store.unreadErrorCount;

// Clear
store.clearConsole();
store.markErrorsRead();
store.clearErrors();
store.clearNetwork();
```

Default capacities are Console 500, Network 200, and Error 200 entries. Configure them through `AppLogsConfig`.

### AppLogsDioInterceptor

Standard Dio `Interceptor` subclass:

```dart
dio.interceptors.add(AppLogsDioInterceptor());
```

Automatically records the full request → response / error lifecycle including timing, headers, request body, and response body.

Recommended to place **first** in the interceptor chain (before business interceptors) to capture complete request information.

Requests start as `AppNetworkLogState.pending`, then update to `success`, `error`, or `cancelled`. `AppNetworkLogEntry.toCurl()` generates the same cURL text as the terminal button in Network details:

```dart
final entry = AppLogStore.instance.network.first;
final curl = entry.toCurl();
```

### AppLogPanelHost

Widget that wraps your app root. Shows a draggable floating button; tapping opens a bottom sheet with Network, Console, and Error tabs. Automatic error capture remains active while the host is mounted.

```dart
AppLogPanelHost(child: yourApp)
```

When `enabled` is `false`, returns `child` directly (zero overhead).

## Custom Theme

```dart
AppLogsConfig.init(
  enabled: true,
  theme: const AppLogsTheme(
    primary: Color(0xFF6366F1),   // Primary — FAB, active tab
    info: Color(0xFF0EA5E9),      // Info — info level, GET method
    success: Color(0xFF22C55E),   // Success — POST method, <500ms timing
    debug: Color(0xFF9CA3AF),     // Debug — debug level
    error: Color(0xFFEF4444),     // Error — error level, DELETE method
    patch: Color(0xFFA855F7),     // Patch — PATCH method
  ),
);
```

## Non-Dio HTTP Libraries

For `http`, `graphql_flutter`, or other networking packages, call `AppLogStore` directly:

```dart
final id = 'req-${DateTime.now().millisecondsSinceEpoch}';

// When request is sent
AppLogStore.instance.logNetworkRequest(
  id: id,
  at: DateTime.now(),
  path: '/api/users',
  method: 'GET',
  request: {'method': 'GET', 'url': 'https://example.com/api/users'},
);

// When response is received
AppLogStore.instance.logNetworkResponse(
  id: id,
  at: DateTime.now(),
  request: {'method': 'GET', 'url': 'https://example.com/api/users'},
  response: {'statusCode': 200, 'data': {...}},
  durationMs: 150,
);
```

## Production Safety

```dart
AppLogsConfig.init(
  enabled: kDebugMode, // automatically false in release builds
);
```

When `enabled: false`:
- `AppLogPanelHost` returns `child` directly — no extra UI rendered
- `AppLogStore` write methods return immediately (short-circuit)
- `AppConsoleLogger` static methods are no-ops
- `AppLogsDioInterceptor` only calls `handler.next()` — no data recorded

**Zero runtime overhead. No conditional compilation or tree-shaking required.**

## FAQ

### Q: Why no built-in toast?

The plugin avoids toast/snackbar dependencies to prevent conflicts with your app's existing notification system. Use the `onCopySuccess` callback to integrate your own (e.g., `fluttertoast`, `SnackBar`, or custom overlay).

### Q: Will the floating button block my UI?

The button can be freely dragged anywhere on screen. For production builds, set `enabled: false` to remove it entirely.

### Q: Is there a log entry limit?

Defaults are Console 500, Network 200, and Error 200 entries. Configure them through `AppLogsConfig`; oldest entries are evicted first.

### Q: Does it conflict with existing Dio interceptors?

No. `AppLogsDioInterceptor` is a standard Dio `Interceptor` that only reads request/response data without modifying anything. It always calls `handler.next()` to pass through to the next interceptor.

### Q: What Flutter versions are supported?

Flutter >= 3.29.0, Dart SDK >= 3.7.0.

## License

MIT — see [LICENSE](LICENSE)
