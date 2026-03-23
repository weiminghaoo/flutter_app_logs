[简体中文](README.md) | English

# flutter_app_logs

[![pub package](https://img.shields.io/pub/v/flutter_app_logs.svg)](https://pub.dev/packages/flutter_app_logs)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

An in-app debug panel for Flutter — inspect **Console logs** and **Network requests** via a draggable floating button + bottom sheet UI, similar to [vConsole](https://github.com/niconi/vConsole) for web.

<p align="center">
  <img src="https://raw.githubusercontent.com/wildcatDownstairs/flutter_app_logs/main/doc/screenshot_network_list.png" width="260" alt="Network request list" />
  &nbsp;
  <img src="https://raw.githubusercontent.com/wildcatDownstairs/flutter_app_logs/main/doc/screenshot_network_detail.png" width="260" alt="Network request detail" />
  &nbsp;
  <img src="https://raw.githubusercontent.com/wildcatDownstairs/flutter_app_logs/main/doc/screenshot_console.png" width="260" alt="Console logs" />
</p>

---

## Features

- **Console Log Panel** — view debug / info / warn / error logs with level filtering and keyword search
- **Network Log Panel** — inspect HTTP requests, responses, and errors with timing, headers, and body
- **Draggable FAB** — freely drag the floating button anywhere on screen
- **Built-in Dio Interceptor** — `AppLogsDioInterceptor`, one line to integrate
- **Zero overhead in production** — when `enabled: false`, all writes short-circuit and UI returns `child` directly
- **Customizable theme** — override all panel colors via `AppLogsTheme`
- **Sensitive header masking** — `maskHeaders: true` masks Authorization / Token / Cookie headers
- **Copy callback** — no built-in toast; provide `onCopySuccess` to use your own notification

## Installation

```yaml
dependencies:
  flutter_app_logs: ^0.1.0
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

## API Reference

### AppLogsConfig

Global configuration, initialized once via `AppLogsConfig.init()`.

| Property | Type | Default | Description |
|---|---|---|---|
| `enabled` | `bool` | `false` | Master switch — gates all writes and UI rendering |
| `consoleMinLevel` | `AppLogLevel` | `.debug` | Minimum console log level |
| `maskHeaders` | `bool` | `false` | Mask sensitive headers (Authorization, etc.) |
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
store.logNetworkRequest(id: '1', at: DateTime.now(), path: '/api', method: 'GET', request: {...});
store.logNetworkResponse(id: '1', at: DateTime.now(), request: {...}, response: {...}, durationMs: 120);
store.logNetworkError(id: '1', at: DateTime.now(), request: {...}, error: {...});

// Read (read-only)
List<AppConsoleLogEntry> logs = store.console;
List<AppNetworkLogEntry> reqs = store.network;

// Clear
store.clearConsole();
store.clearNetwork();
```

Capacity limits: Console 500 entries, Network 200 entries. Oldest entries are automatically evicted (FIFO).

### AppLogsDioInterceptor

Standard Dio `Interceptor` subclass:

```dart
dio.interceptors.add(AppLogsDioInterceptor());
```

Automatically records the full request → response / error lifecycle including timing, headers, request body, and response body.

Recommended to place **first** in the interceptor chain (before business interceptors) to capture complete request information.

### AppLogPanelHost

Widget that wraps your app root. Shows a draggable floating button; tapping opens a bottom sheet with Console and Network tabs.

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

Console: 500 entries max. Network: 200 entries max. Oldest entries are automatically evicted (FIFO).

### Q: Does it conflict with existing Dio interceptors?

No. `AppLogsDioInterceptor` is a standard Dio `Interceptor` that only reads request/response data without modifying anything. It always calls `handler.next()` to pass through to the next interceptor.

### Q: What Flutter versions are supported?

Flutter >= 3.29.0, Dart SDK >= 3.7.0.

## License

MIT — see [LICENSE](LICENSE)
