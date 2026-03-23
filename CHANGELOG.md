## 0.1.2

- **docs**: Added full example (`example/lib/main.dart`) to README — visible preview snippet + collapsible `<details>` block with complete 510-line code.
- **docs**: Moved `# flutter_app_logs` heading to first line to satisfy MD041 lint rule.
- **docs**: Added GitHub repository badge alongside pub version and license badges.
- **docs**: Updated installation snippet to reference `^0.1.1`.
- **meta**: Replaced `debug`/`vconsole` topics with `debugging`/`monitoring` for better pub.dev discoverability.

## 0.1.1

- **fix**: Clipboard `setData` now awaited before calling `onCopySuccess` — prevents false-positive callback on write failure.
- **perf**: Panel no longer subscribes to `AppLogStore` when closed — eliminates unnecessary rebuilds from log writes.
- **fix**: Tightened `dio` lower bound to `>=5.9.2` to pass pub.dev downgrade analysis.
- **docs**: Added real app screenshots to README (Network list, Network detail, Console).
- **meta**: Added `issue_tracker` field to `pubspec.yaml`.

## 0.1.0

- Initial public release.
- **Console Log Panel** — debug / info / warn / error with level filtering and keyword search.
- **Network Log Panel** — HTTP request / response / error with timing, headers, and body.
- **Draggable floating button** — reposition anywhere on screen.
- **Built-in Dio interceptor** (`AppLogsDioInterceptor`) — automatic network logging.
- **Customizable theme** via `AppLogsTheme`.
- **Sensitive header masking** (`maskHeaders`).
- **Copy callback** (`onCopySuccess`) — no built-in toast dependency.
- **Zero production overhead** — all writes short-circuit when `enabled: false`.
