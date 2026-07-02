import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_logs/flutter_app_logs.dart';

/// 简易 RequestInterceptorHandler，记录 next/reject/resolve 调用
class _TestRequestHandler extends RequestInterceptorHandler {
  bool nextCalled = false;
  @override
  void next(RequestOptions requestOptions) {
    nextCalled = true;
    // 不调 super，避免触发真实链路
  }
}

class _TestResponseHandler extends ResponseInterceptorHandler {
  bool nextCalled = false;
  @override
  void next(Response response) {
    nextCalled = true;
  }
}

class _TestErrorHandler extends ErrorInterceptorHandler {
  bool nextCalled = false;
  @override
  void next(DioException err) {
    nextCalled = true;
  }
}

class _FakeCheckoutCart {
  const _FakeCheckoutCart({required this.cartId, required this.userId});

  final int cartId;
  final int userId;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'cartId': cartId,
    'userId': userId,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLogsDioInterceptor interceptor;
  late AppLogStore store;

  setUp(() {
    interceptor = AppLogsDioInterceptor();
    store = AppLogStore.instance;
    store.clearConsole();
    store.clearNetwork();
    AppLogsConfig.init(
      enabled: true,
      consoleMinLevel: AppLogLevel.debug,
      maskHeaders: false,
    );
  });

  tearDown(() {
    AppLogsConfig.init(enabled: false);
  });

  RequestOptions makeOptions({
    String path = '/api/test',
    String method = 'GET',
    Map<String, dynamic>? headers,
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) {
    return RequestOptions(
      path: path,
      method: method,
      headers: headers ?? {'Content-Type': 'application/json'},
      data: data,
      queryParameters: queryParameters ?? {},
    );
  }

  group('AppLogsDioInterceptor — onRequest', () {
    test('记录网络请求到 AppLogStore', () {
      final options = makeOptions();
      final handler = _TestRequestHandler();
      interceptor.onRequest(options, handler);

      expect(store.network.length, 1);
      expect(store.network.first.path, '/api/test');
      expect(store.network.first.method, 'GET');
      expect(store.network.first.response, isNull);
      expect(handler.nextCalled, isTrue);
    });

    test('分配唯一 ID 到 extra', () {
      final options = makeOptions();
      final handler = _TestRequestHandler();
      interceptor.onRequest(options, handler);

      expect(options.extra['__app_logs_network_id__'], isNotNull);
      expect(options.extra['__app_logs_network_start_at__'], isA<int>());
    });

    test('enabled=false 时不记录但仍调用 next', () {
      AppLogsConfig.enabled = false;
      final options = makeOptions();
      final handler = _TestRequestHandler();
      interceptor.onRequest(options, handler);

      expect(store.network, isEmpty);
      expect(handler.nextCalled, isTrue);
    });

    test('记录 query parameters', () {
      final options = makeOptions(queryParameters: {'page': '1', 'size': '20'});
      final handler = _TestRequestHandler();
      interceptor.onRequest(options, handler);

      final request = store.network.first.request;
      expect(request['query'], {'page': '1', 'size': '20'});
    });

    test('记录 request body (data)', () {
      final options = makeOptions(
        method: 'POST',
        data: {'name': 'test', 'age': 25},
      );
      final handler = _TestRequestHandler();
      interceptor.onRequest(options, handler);

      final request = store.network.first.request;
      expect(request['data'], {'name': 'test', 'age': 25});
    });
  });

  group('AppLogsDioInterceptor — onResponse', () {
    test('记录响应并关联到请求', () {
      final options = makeOptions(path: '/api/users');
      final requestHandler = _TestRequestHandler();
      interceptor.onRequest(options, requestHandler);

      final response = Response(
        requestOptions: options,
        statusCode: 200,
        data: {'users': []},
      );
      final responseHandler = _TestResponseHandler();
      interceptor.onResponse(response, responseHandler);

      expect(store.network.length, 1);
      expect(store.network.first.response, isNotNull);
      expect(store.network.first.response!['statusCode'], 200);
      expect(store.network.first.durationMs, isNotNull);
      expect(responseHandler.nextCalled, isTrue);
    });

    test('保留嵌套对象数组的 JSON 结构', () {
      final options = makeOptions(path: '/api/checkout');
      interceptor.onRequest(options, _TestRequestHandler());

      final response = Response(
        requestOptions: options,
        statusCode: 200,
        data: <String, Object?>{
          'cartList': <Object?>[
            <String, Object?>{
              'shopId': 430,
              'carts': <Object?>[
                const _FakeCheckoutCart(cartId: 5168, userId: 205),
              ],
            },
          ],
        },
      );
      interceptor.onResponse(response, _TestResponseHandler());

      final responseData =
          store.network.first.response!['data'] as Map<String, Object?>;
      final cartList = responseData['cartList'] as List<Object?>;
      final firstGroup = cartList.first as Map<String, Object?>;
      final carts = firstGroup['carts'] as List<Object?>;
      final firstCart = carts.first as Map<String, Object?>;

      expect(firstCart['cartId'], 5168);
      expect(firstCart['userId'], 205);
    });

    test('深层嵌套数据仍保留类型和层级', () {
      final options = makeOptions(path: '/api/deep-checkout');
      interceptor.onRequest(options, _TestRequestHandler());

      final response = Response(
        requestOptions: options,
        statusCode: 200,
        data: <String, Object?>{
          'payload': <String, Object?>{
            'stores': <Object?>[
              <String, Object?>{
                'sections': <Object?>[
                  <String, Object?>{
                    'groups': <Object?>[
                      <String, Object?>{
                        'carts': <Object?>[
                          const _FakeCheckoutCart(cartId: 9001, userId: 301),
                        ],
                      },
                    ],
                  },
                ],
              },
            ],
          },
        },
      );
      interceptor.onResponse(response, _TestResponseHandler());

      final responseData =
          store.network.first.response!['data'] as Map<String, Object?>;
      final payload = responseData['payload'] as Map<String, Object?>;
      final stores = payload['stores'] as List<Object?>;
      final firstStore = stores.first as Map<String, Object?>;
      final sections = firstStore['sections'] as List<Object?>;
      final firstSection = sections.first as Map<String, Object?>;
      final groups = firstSection['groups'] as List<Object?>;
      final firstGroup = groups.first as Map<String, Object?>;
      final carts = firstGroup['carts'] as List<Object?>;
      final firstCart = carts.first as Map<String, Object?>;

      expect(firstCart['cartId'], 9001);
      expect(firstCart['userId'], 301);
    });

    test('enabled=false 时不记录但仍调用 next', () {
      final options = makeOptions();
      // 先正常记录请求
      interceptor.onRequest(options, _TestRequestHandler());

      AppLogsConfig.enabled = false;
      final response = Response(requestOptions: options, statusCode: 200);
      final handler = _TestResponseHandler();
      interceptor.onResponse(response, handler);

      // 请求仍在（之前 enabled 时记录的），但 response 未更新
      expect(store.network.first.response, isNull);
      expect(handler.nextCalled, isTrue);
    });
  });

  group('AppLogsDioInterceptor — onError', () {
    test('记录错误并关联到请求', () {
      final options = makeOptions(path: '/api/fail');
      interceptor.onRequest(options, _TestRequestHandler());

      final err = DioException(
        requestOptions: options,
        type: DioExceptionType.connectionTimeout,
        message: 'Connection timed out',
      );
      final handler = _TestErrorHandler();
      interceptor.onError(err, handler);

      expect(store.network.length, 1);
      final entry = store.network.first;
      expect(entry.error, isNotNull);
      expect(entry.error!['type'], 'connectionTimeout');
      expect(entry.error!['message'], 'Connection timed out');
      expect(handler.nextCalled, isTrue);
    });

    test('错误包含响应时也记录 response', () {
      final options = makeOptions(path: '/api/500');
      interceptor.onRequest(options, _TestRequestHandler());

      final errorResponse = Response(
        requestOptions: options,
        statusCode: 500,
        data: {'error': 'Internal Server Error'},
      );
      final err = DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: errorResponse,
      );
      final handler = _TestErrorHandler();
      interceptor.onError(err, handler);

      final entry = store.network.first;
      expect(entry.error!['statusCode'], 500);
      expect(entry.response, isNotNull);
      expect(entry.response!['statusCode'], 500);
    });

    test('enabled=false 时不记录但仍调用 next', () {
      AppLogsConfig.enabled = false;
      final options = makeOptions();
      final err = DioException(
        requestOptions: options,
        type: DioExceptionType.cancel,
      );
      final handler = _TestErrorHandler();
      interceptor.onError(err, handler);

      expect(store.network, isEmpty);
      expect(handler.nextCalled, isTrue);
    });
  });

  group('AppLogsDioInterceptor — maskHeaders', () {
    test('maskHeaders=false 时保留完整 header', () {
      AppLogsConfig.maskHeaders = false;
      final options = makeOptions(
        headers: {
          'Authorization': 'Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9',
          'Content-Type': 'application/json',
        },
      );
      interceptor.onRequest(options, _TestRequestHandler());

      final headers =
          store.network.first.request['headers'] as Map<String, Object?>;
      expect(
        headers['Authorization'],
        'Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9',
      );
    });

    test('maskHeaders=true 时遮盖 Authorization', () {
      AppLogsConfig.maskHeaders = true;
      final options = makeOptions(
        headers: {
          'Authorization': 'Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9',
          'Content-Type': 'application/json',
        },
      );
      interceptor.onRequest(options, _TestRequestHandler());

      final headers =
          store.network.first.request['headers'] as Map<String, Object?>;
      final authValue = headers['Authorization'] as String;
      expect(authValue, startsWith('***'));
      expect(authValue, isNot(contains('Bearer')));
      // Content-Type 不被遮盖
      expect(headers['Content-Type'], 'application/json');
    });

    test('maskHeaders=true 时遮盖 token 和 cookie', () {
      AppLogsConfig.maskHeaders = true;
      final options = makeOptions(
        headers: {
          'X-Token': 'secret-token-value-12345',
          'Cookie': 'session=abc123def456',
          'Accept': 'application/json',
        },
      );
      interceptor.onRequest(options, _TestRequestHandler());

      final headers =
          store.network.first.request['headers'] as Map<String, Object?>;
      expect((headers['X-Token'] as String).startsWith('***'), isTrue);
      expect((headers['Cookie'] as String).startsWith('***'), isTrue);
      expect(headers['Accept'], 'application/json');
    });

    test('maskHeaders=true 保留尾部 6 字符', () {
      AppLogsConfig.maskHeaders = true;
      final options = makeOptions(
        headers: {'Authorization': 'Bearer abcdefghijk'},
      );
      interceptor.onRequest(options, _TestRequestHandler());

      final headers =
          store.network.first.request['headers'] as Map<String, Object?>;
      final masked = headers['Authorization'] as String;
      // 原值 "Bearer abcdefghijk"，尾部 6 字符是 "fghijk"
      expect(masked, '***fghijk');
    });

    test('短于 keepTail 的敏感 header 完全遮盖为 ***', () {
      AppLogsConfig.maskHeaders = true;
      final options = makeOptions(headers: {'Authorization': 'abc'});
      interceptor.onRequest(options, _TestRequestHandler());

      final headers =
          store.network.first.request['headers'] as Map<String, Object?>;
      expect(headers['Authorization'], '***');
    });
  });

  group('AppLogsDioInterceptor — _safeJsonLike', () {
    test('截断超长字符串', () {
      final longString = 'x' * 3000;
      final options = makeOptions(method: 'POST', data: {'big': longString});
      interceptor.onRequest(options, _TestRequestHandler());

      final data = store.network.first.request['data'] as Map<String, Object?>;
      final value = data['big'] as String;
      expect(value.length, lessThan(3000));
      expect(value, endsWith('...(truncated)'));
    });

    test('截断超长列表（>50 元素）', () {
      final bigList = List.generate(60, (i) => i);
      final options = makeOptions(method: 'POST', data: {'items': bigList});
      interceptor.onRequest(options, _TestRequestHandler());

      final data = store.network.first.request['data'] as Map<String, Object?>;
      final items = data['items'] as List;
      // 50 个元素 + 1 个 truncated 标记
      expect(items.length, 51);
      expect(items.last, '...(truncated)');
    });

    test('FormData 被序列化为描述对象', () {
      final formData = FormData.fromMap({
        'name': 'test',
        'file': MultipartFile.fromString('content', filename: 'test.txt'),
      });
      final options = makeOptions(method: 'POST', data: formData);
      interceptor.onRequest(options, _TestRequestHandler());

      final data = store.network.first.request['data'] as Map<String, Object?>;
      expect(data['type'], 'FormData');
      expect(data['fields'], isA<List>());
      expect(data['files'], isA<List>());
    });

    test('循环引用不会导致递归卡死', () {
      final cyclic = <String, Object?>{};
      cyclic['self'] = cyclic;

      final options = makeOptions(method: 'POST', data: cyclic);
      interceptor.onRequest(options, _TestRequestHandler());

      final data = store.network.first.request['data'] as Map<String, Object?>;
      expect(data['self'], '(circular reference)');
    });
  });

  group('AppLogsDioInterceptor — 完整请求生命周期', () {
    test('request → response 完整链路', () {
      final options = makeOptions(path: '/api/lifecycle');

      // 1. Request
      interceptor.onRequest(options, _TestRequestHandler());
      expect(store.network.length, 1);
      expect(store.network.first.response, isNull);
      expect(store.network.first.durationMs, isNull);

      // 2. Response
      final response = Response(
        requestOptions: options,
        statusCode: 200,
        data: {'success': true},
      );
      interceptor.onResponse(response, _TestResponseHandler());
      expect(store.network.length, 1);
      expect(store.network.first.response!['statusCode'], 200);
      expect(store.network.first.durationMs, isNotNull);
    });

    test('request → error 完整链路', () {
      final options = makeOptions(path: '/api/lifecycle-err');

      // 1. Request
      interceptor.onRequest(options, _TestRequestHandler());

      // 2. Error
      final err = DioException(
        requestOptions: options,
        type: DioExceptionType.receiveTimeout,
        message: 'Receive timeout',
      );
      interceptor.onError(err, _TestErrorHandler());

      expect(store.network.length, 1);
      expect(store.network.first.error!['type'], 'receiveTimeout');
      expect(store.network.first.durationMs, isNotNull);
    });
  });
}
