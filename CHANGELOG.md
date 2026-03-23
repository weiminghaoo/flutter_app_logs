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
