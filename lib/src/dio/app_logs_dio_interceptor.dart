import 'dart:convert';

import 'package:dio/dio.dart';

import '../app_logs_config.dart';
import '../app_logs.dart' show AppLogStore, AppNetworkLogState;

/// Dio 拦截器，自动将请求/响应/错误记录到 [AppLogStore]。
///
/// 使用方式：
/// ```dart
/// final dio = Dio();
/// dio.interceptors.add(AppLogsDioInterceptor());
/// ```
///
/// 如果 [AppLogsConfig.enabled] 为 `false`，拦截器会短路返回，零开销。
class AppLogsDioInterceptor extends Interceptor {
  /// 递增序列号，用于生成唯一日志 ID。
  static int _seq = 0;

  /// 存放在 [RequestOptions.extra] 中的内部 key。
  static const String _idKey = '__app_logs_network_id__';
  static const String _startAtKey = '__app_logs_network_start_at__';
  static const String _requestKey = '__app_logs_network_request__';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (AppLogsConfig.enabled) {
      final id = _ensureId(options);
      final request = _buildRequestLog(options);
      options.extra[_requestKey] = request;

      AppLogStore.instance.logNetworkRequest(
        id: id,
        at: DateTime.now(),
        path: options.path,
        method: options.method,
        request: request,
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (AppLogsConfig.enabled) {
      final options = response.requestOptions;
      final id = _ensureId(options);
      final request =
          _readExtraMap(options.extra[_requestKey]) ??
          _buildRequestLog(options);
      final durationMs = _computeDurationMs(options);

      AppLogStore.instance.logNetworkResponse(
        id: id,
        at: DateTime.now(),
        request: request,
        response: _buildResponseLog(response),
        durationMs: durationMs,
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (AppLogsConfig.enabled) {
      final options = err.requestOptions;
      final id = _ensureId(options);
      final request =
          _readExtraMap(options.extra[_requestKey]) ??
          _buildRequestLog(options);
      final durationMs = _computeDurationMs(options);

      AppLogStore.instance.logNetworkError(
        id: id,
        at: DateTime.now(),
        request: request,
        error: <String, Object?>{
          'type': err.type.name,
          'message': err.message?.toString(),
          'statusCode': err.response?.statusCode,
          if (err.error != null) 'error': err.error.toString(),
        },
        response:
            err.response == null ? null : _buildResponseLog(err.response!),
        durationMs: durationMs,
        state:
            err.type == DioExceptionType.cancel
                ? AppNetworkLogState.cancelled
                : AppNetworkLogState.error,
      );
    }
    handler.next(err);
  }

  // ── ID & 计时 ───────────────────────────────────────────────────────────

  String _ensureId(RequestOptions options) {
    final existing = options.extra[_idKey]?.toString();
    if (existing != null && existing.isNotEmpty) return existing;
    final next = '${DateTime.now().millisecondsSinceEpoch}-${_seq++}';
    options.extra[_idKey] = next;
    options.extra[_startAtKey] = DateTime.now().millisecondsSinceEpoch;
    return next;
  }

  int? _computeDurationMs(RequestOptions options) {
    final startAt = options.extra[_startAtKey];
    if (startAt is int) {
      return DateTime.now().millisecondsSinceEpoch - startAt;
    }
    return null;
  }

  // ── 日志构建 ────────────────────────────────────────────────────────────

  Map<String, Object?> _buildRequestLog(RequestOptions options) {
    final uri = options.uri;
    return <String, Object?>{
      'method': options.method,
      'baseUrl': options.baseUrl,
      'path': options.path,
      'url': uri.toString(),
      'headers': _sanitizeHeaders(options.headers),
      'query': _safeJsonLike(options.queryParameters),
      if (options.data != null && AppLogsConfig.maxNetworkBodyCharacters > 0)
        'data': _safeNetworkBody(options.data),
    };
  }

  Map<String, Object?> _buildResponseLog(Response response) {
    return <String, Object?>{
      'statusCode': response.statusCode,
      'headers': _safeJsonLike(response.headers.map),
      if (response.data != null && AppLogsConfig.maxNetworkBodyCharacters > 0)
        'data': _safeNetworkBody(response.data),
    };
  }

  Map<String, Object?> _sanitizeHeaders(Map<String, dynamic> headers) {
    final out = <String, Object?>{};
    for (final entry in headers.entries) {
      final key = entry.key;
      final lower = key.toLowerCase();
      final value = entry.value?.toString() ?? '';
      if (!AppLogsConfig.maskHeaders) {
        out[key] = value;
        continue;
      }
      final masked =
          lower.contains('authorization') ||
                  lower.contains('token') ||
                  lower.contains('cookie') ||
                  lower.contains('device-id') ||
                  lower.contains('appcheck')
              ? _maskSecret(value)
              : value;
      out[key] = masked;
    }
    return out;
  }

  String _maskSecret(String value, {int keepTail = 6}) {
    if (value.isEmpty) return value;
    if (value.length <= keepTail) return '***';
    return '***${value.substring(value.length - keepTail)}';
  }

  Map<String, Object?>? _readExtraMap(Object? raw) {
    if (raw is Map<String, Object?>) return raw;
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), _safeJsonLike(v)));
    }
    return null;
  }

  /// 将任意 Dart 对象转为 JSON 安全结构。
  ///
  /// 这里优先保留 Map / List 的类型和层级，避免深层对象被提前串成
  /// `"[...]"` 或 `"{...}"`。长度控制只针对超长字符串和超长列表；
  /// 对极端情况下的循环引用，使用 [identityHashCode] 做保护。
  Object? _safeJsonLike(
    Object? value, {
    Set<int>? activeRefs,
    int? maxStringCharacters = 2000,
  }) {
    activeRefs ??= <int>{};
    if (value == null) return null;
    if (value is num || value is bool) return value;
    if (value is String) {
      if (maxStringCharacters == null || value.length <= maxStringCharacters) {
        return value;
      }
      return '${value.substring(0, maxStringCharacters)}...(truncated)';
    }

    if (value is Map) {
      final refId = identityHashCode(value);
      if (!activeRefs.add(refId)) return '(circular reference)';

      final out = <String, Object?>{};
      try {
        for (final entry in value.entries) {
          out[entry.key.toString()] = _safeJsonLike(
            entry.value,
            activeRefs: activeRefs,
            maxStringCharacters: maxStringCharacters,
          );
        }
      } finally {
        activeRefs.remove(refId);
      }
      return out;
    }

    if (value is Iterable) {
      final refId = identityHashCode(value);
      if (!activeRefs.add(refId)) return '(circular reference)';

      final out = <Object?>[];
      var i = 0;
      var truncated = false;
      try {
        for (final item in value) {
          if (i >= 50) {
            truncated = true;
            break;
          }
          out.add(
            _safeJsonLike(
              item,
              activeRefs: activeRefs,
              maxStringCharacters: maxStringCharacters,
            ),
          );
          i++;
        }
      } finally {
        activeRefs.remove(refId);
      }
      if (truncated) {
        out.add('...(truncated)');
      }
      return out;
    }

    if (value is FormData) {
      return <String, Object?>{
        'type': 'FormData',
        'fields':
            value.fields
                .map((e) => <String, Object?>{'key': e.key, 'value': e.value})
                .toList(),
        'files':
            value.files
                .map(
                  (e) => <String, Object?>{
                    'key': e.key,
                    'filename': e.value.filename,
                    'length': e.value.length,
                    'contentType': e.value.contentType?.toString(),
                  },
                )
                .toList(),
      };
    }

    try {
      final normalized = jsonDecode(jsonEncode(value));
      return _safeJsonLike(
        normalized,
        activeRefs: activeRefs,
        maxStringCharacters: maxStringCharacters,
      );
    } catch (_) {
      return value.toString();
    }
  }

  Object? _safeNetworkBody(Object value) {
    final normalized = _safeJsonLike(value, maxStringCharacters: null);
    final serialized = switch (normalized) {
      String text => text,
      _ => _encodeJsonOrString(normalized),
    };
    final maxCharacters = AppLogsConfig.maxNetworkBodyCharacters;
    if (serialized.length <= maxCharacters) return normalized;
    return '${serialized.substring(0, maxCharacters)}...(truncated)';
  }

  String _encodeJsonOrString(Object? value) {
    try {
      return jsonEncode(value);
    } catch (_) {
      return value.toString();
    }
  }
}
