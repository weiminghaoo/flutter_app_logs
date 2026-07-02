## 0.1.5

- **feat**: Network detail mobile header now uses a denser action layout. The old standalone `Request Details` row is removed, back/copy actions are merged into the detail header, and the request path/method/duration are rendered in a more compact card.
- **feat**: The bottom sheet now supports dragging upward from the gray handle to expand beyond the default 85% height.
- **fix**: When expanded, the sheet now stops below the system status bar instead of covering it, so the handle remains reachable for dragging downward to close.
- **test**: Added widget coverage for the mobile detail-header layout and the drag-to-expand interaction with top safe-area constraints.
- **docs**: Updated installation snippets to reference `^0.1.5`.

## 0.1.4

- **feat**: Added a header-level search toggle button. Network and Console filter bars are now collapsed by default and expand on demand, leaving more vertical space for request/response details and log content.
- **fix**: Network response serialization now preserves deep `Map` / `List` structure for nested object arrays instead of degrading them into strings like `"[...]"`.
- **fix**: Added circular-reference protection in response normalization so extreme nested payloads do not recurse indefinitely during log rendering.
- **test**: Added widget coverage for the new search toggle interaction and regression tests for deep nested object-array serialization.
- **docs**: Updated installation snippets to reference `^0.1.4`.

## 0.1.3

- **fix**: Copy success feedback is now rendered by `AppLogPanelHost` itself, so the "Copied" message appears above the log panel instead of being hidden behind it by the host app's overlay/toast layer.
- **debug**: Every successful copy now prints the copied text to the Flutter/Xcode console with a `[flutter_app_logs copied text]` header and footer. This makes copied request/response payloads retrievable even when iOS Simulator pasteboard sync does not forward app-written clipboard content to macOS.
- **refactor**: Centralized all copy actions (JSON blocks, network request paths, and console log entries) through one internal helper so clipboard writes, callbacks, debug output, and in-panel feedback stay consistent.
- **docs**: Updated installation snippets to reference `^0.1.3`.

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
