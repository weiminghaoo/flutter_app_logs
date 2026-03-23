# flutter_app_logs

An in-app debug panel for Flutter — inspect network requests and console logs
with a draggable floating button and a bottom sheet UI, similar to
[vConsole](https://github.com/niconi/vConsole).

## Features

- **Console Log Panel** — view debug / info / warn / error logs with level filtering and search
- **Network Log Panel** — inspect HTTP requests, responses, and errors with timing
- **Draggable FAB** — floating button that can be repositioned anywhere on screen
- **Dio Interceptor** — built-in `AppLogsDioInterceptor` for automatic network logging
- **Zero-overhead in production** — when `enabled: false`, all writes short-circuit and the UI returns `child` directly
- **Customizable theme** — override all panel colors via `AppLogsTheme`
- **Copy callback** — no built-in toast; you provide `onCopySuccess` to show your own

## Quick Start

```dart
import 'package:flutter_app_logs/flutter_app_logs.dart';

// 1. Initialize (usually in main() or App.initState)
AppLogsConfig.init(
  enabled: true, // typically: kDebugMode or your own env flag
  consoleMinLevel: AppLogLevel.debug,
  onCopySuccess: (text) => showToast('Copied!'),
);

// 2. Wrap your app root
MaterialApp(
  builder: (context, child) {
    return AppLogPanelHost(child: child ?? const SizedBox.shrink());
  },
  home: MyHomePage(),
);

// 3. Write console logs anywhere
AppConsoleLogger.info('User logged in', tag: 'auth');
AppConsoleLogger.error('Payment failed', tag: 'wallet', extra: {'code': 500});

// 4. Add Dio interceptor for automatic network logging
final dio = Dio();
dio.interceptors.add(AppLogsDioInterceptor());
```

## API Reference

### AppLogsConfig

| Property | Type | Default | Description |
|---|---|---|---|
| `enabled` | `bool` | `false` | Master switch — gates all writes and UI rendering |
| `consoleMinLevel` | `AppLogLevel` | `.debug` | Minimum log level for console entries |
| `maskHeaders` | `bool` | `false` | Mask sensitive headers (Authorization, Token, etc.) |
| `onCopySuccess` | `void Function(String)?` | `null` | Called after clipboard copy; plug in your own toast |
| `theme` | `AppLogsTheme` | `defaultTheme` | Custom color palette for the panel UI |

### AppConsoleLogger

Static methods: `debug()`, `info()`, `warn()`, `error()` — each accepts `message`, optional `tag`, and optional `extra` (Map).

### AppLogStore

Singleton (`AppLogStore.instance`) backed by `ChangeNotifier`. Provides:
- `logConsole()` / `logNetworkRequest()` / `logNetworkResponse()` / `logNetworkError()`
- `console` / `network` — read-only lists
- `clearConsole()` / `clearNetwork()`

### AppLogsDioInterceptor

Drop-in `Interceptor` subclass. Add to any `Dio` instance:

```dart
dio.interceptors.add(AppLogsDioInterceptor());
```

Automatically records request → response/error lifecycle with timing.

### AppLogPanelHost

Widget that wraps your app's root. Shows a draggable floating button; tapping opens a bottom sheet with Console and Network tabs.

```dart
AppLogPanelHost(child: yourApp)
```

When `AppLogsConfig.enabled` is `false`, returns `child` directly (zero overhead).

## Custom Theme

```dart
AppLogsConfig.init(
  enabled: true,
  theme: AppLogsTheme(
    primary: Color(0xFF6366F1),
    info: Color(0xFF0EA5E9),
    success: Color(0xFF22C55E),
    debug: Color(0xFF9CA3AF),
    error: Color(0xFFEF4444),
    patch: Color(0xFFA855F7),
  ),
);
```

## License

MIT
