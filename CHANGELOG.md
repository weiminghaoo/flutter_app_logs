## 0.2.2

- **fix**: The debug panel now stays open when `AppLogPanelHost.child` is rebuilt by keyboard `viewInsets`, `MediaQuery`, theme, locale, or other ancestor updates. Panel closing is limited to explicit user actions, and search focus is tracked to avoid mask-layer closes during keyboard transitions.
- **test**: Added a widget regression test that rebuilds a `MediaQuery`-dependent child while simulating the soft keyboard.
- **thanks**: Thanks to [@weiminghaoo](https://github.com/weiminghaoo) for the detailed root-cause analysis and the fix contributed in [#2](https://github.com/wildcatDownstairs/flutter_app_logs/pull/2).

## 0.2.1

- **fix**: Wrapped structured Console log `ExpansionTile` cards in their own transparent `Material`, preventing Flutter 3.44+ from repeatedly reporting hidden `ListTile` backgrounds and ink splashes.
- **test**: Added widget regression coverage for Console entries containing `extra` data inside decorated cards.

## 0.2.0

- **feat**: Added configurable automatic Error capture rules for Flutter, unhandled, and `debugPrint` sources, plus additional and ignored message patterns.
- **feat**: Repeated identical errors can now merge within a configurable time window and display their occurrence count.
- **feat**: Added Error source filters and an unread Error Tab badge with explicit read-state APIs.
- **feat**: Console, Network, and Error retention capacities are now configurable, including support for zero retention.
- **feat**: Added a configurable Network body character limit with explicit truncation markers and body capture disabling.
- **fix**: Search fields now use a local Overlay when `AppLogPanelHost` is injected through `MaterialApp.builder`, preventing focus-time `No Overlay widget found` assertions.
- **docs**: Documented all 0.2.0 Error management and runtime limit settings in Chinese and English.
- **test**: Added configuration, deduplication, unread state, capture-rule, source-filter, capacity, body-limit, and narrow-viewport coverage.

## 0.1.8

- **feat**: Added combined Network filters for method, HTTP status, host, and duration.
- **feat**: Added explicit pending and cancelled request states across the Dio interceptor, store, list, detail header, and filters.
- **feat**: Added Copy as cURL from Network details, including captured headers, JSON bodies, form fields, and safe placeholders for FormData files.
- **docs**: Added Network filter and cURL screenshots, integration guidance, sensitive-header notes, and updated installation snippets to `^0.1.8`.
- **test**: Added model, lifecycle, Dio interceptor, clipboard, filtering, and narrow-viewport widget coverage.

## 0.1.7

- **feat**: Added a dedicated Error panel that automatically captures Flutter framework errors, unhandled root-isolate exceptions, and multiline Network Error / App Error blocks emitted through `debugPrint`.
- **feat**: Added a copy action to each Error card header while retaining long-press copy support.
- **feat**: Error cards now use a Console-style collapsible layout with a three-line summary and expandable full error / stack trace content.
- **fix**: Removed the Error copy button tooltip dependency on an ancestor `Overlay`, preventing `No Overlay widget found` from recursively rendering inside the Error panel.
- **refactor**: Kept `AppConsoleLogger` as an explicit lifecycle and flow logging API; captured errors now use independent storage, search, and clearing behavior.
- **test**: Added store, capture forwarding, multiline grouping, search-toolbar, and Error tab widget coverage.
- **docs**: Documented automatic Error capture, manual error injection, data access, and updated installation snippets to `^0.1.7`.

## 0.1.6

- **perf**: Large JSON responses in the log panel now render in batches (24 nodes at a time) instead of building the entire tree at once, fixing severe jank when opening big payloads.
- **perf**: Copying the raw JSON text now formats it on a background isolate via `compute`, keeping the UI thread free for large payloads.
- **fix**: "Show next batch" and "Expand all" are merged into a single button when the remaining item count is small, since both used to produce the identical result.
- **fix**: "Expand all" now advances in batches across frames instead of inflating the whole subtree in one frame, so it no longer reintroduces jank on very large arrays/objects.
- **docs**: Updated installation snippets to reference `^0.1.6`.

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
