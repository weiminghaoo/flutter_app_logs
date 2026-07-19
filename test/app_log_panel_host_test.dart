import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_logs/flutter_app_logs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AppLogsConfig.init(enabled: true, consoleMinLevel: AppLogLevel.debug);
    AppLogStore.instance.clearConsole();
    AppLogStore.instance.clearNetwork();
    AppLogStore.instance.clearErrors();
  });

  tearDown(() {
    AppLogsConfig.init(enabled: false);
    AppLogStore.instance.clearConsole();
    AppLogStore.instance.clearNetwork();
    AppLogStore.instance.clearErrors();
  });

  Future<void> openPanel(WidgetTester tester) async {
    final bugIcon = find.byIcon(Icons.bug_report_rounded).first;
    final gesture = await tester.startGesture(tester.getCenter(bugIcon));
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('Network 搜索区默认收起，点击按钮后展开', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppLogPanelHost(child: SizedBox.expand())),
      ),
    );

    await openPanel(tester);

    expect(find.text('App Logs'), findsOneWidget);
    expect(find.text('Search network requests...'), findsNothing);

    await tester.tap(find.byKey(const Key('app_logs_toggle_toolbar_button')));
    await tester.pumpAndSettle();

    expect(find.text('Search network requests...'), findsOneWidget);

    await tester.tap(find.byKey(const Key('app_logs_toggle_toolbar_button')));
    await tester.pumpAndSettle();

    expect(find.text('Search network requests...'), findsNothing);
  });

  testWidgets('Error 面板归并 debugPrint 的 Network Error 错误块', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppLogPanelHost(child: SizedBox.expand())),
      ),
    );

    debugPrint(
      '🚨 [Network Error] POST '
      'https://jp.api.tatamijp.cn/im/conversation/message/set_read',
    );
    debugPrint('   Status: 500');
    debugPrint('   Payload: {"conversation_id": 130}');
    debugPrint('   Response: {"code": 500, "message": "请求错误"}');
    await tester.pump(const Duration(milliseconds: 120));

    expect(AppLogStore.instance.console, isEmpty);
    expect(AppLogStore.instance.errors, hasLength(1));
    expect(AppLogStore.instance.errors.single.message, contains('Status: 500'));
    expect(
      AppLogStore.instance.errors.single.message,
      contains('conversation_id'),
    );

    await openPanel(tester);
    await tester.tap(find.text('Error'));
    await tester.pumpAndSettle();

    expect(find.text('NETWORK'), findsOneWidget);
    expect(find.textContaining('[Network Error] POST'), findsOneWidget);
    expect(find.textContaining('Status: 500'), findsOneWidget);

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (_) async => null,
    );
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    String? copiedText;
    AppLogsConfig.onCopySuccess = (text) => copiedText = text;
    await tester.tap(find.byKey(const Key('app_logs_error_copy_button')));
    await tester.pump();

    expect(copiedText, contains('[Network Error] POST'));
    expect(copiedText, contains('conversation_id'));
    expect(find.text('Copied'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    expect(AppLogStore.instance.errors, hasLength(1));
  });

  testWidgets('Error 搜索区只在 Error 标签打开时显示', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppLogPanelHost(child: SizedBox.expand())),
      ),
    );
    await openPanel(tester);
    await tester.tap(find.text('Error'));
    await tester.pumpAndSettle();

    expect(find.text('Search errors...'), findsNothing);
    await tester.tap(find.byKey(const Key('app_logs_toggle_toolbar_button')));
    await tester.pumpAndSettle();
    expect(find.text('Search errors...'), findsOneWidget);
  });

  testWidgets('带堆栈的 Error 卡片不会触发 ListTile Material 层级断言', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppLogPanelHost(child: SizedBox.expand())),
      ),
    );
    AppLogStore.instance.logError(
      source: AppErrorLogSource.flutter,
      message: 'ListTile regression',
      stackTrace: StackTrace.fromString('#0 build (widget.dart:10:3)'),
    );
    await tester.pump();

    await openPanel(tester);
    await tester.tap(find.text('Error'));
    await tester.pumpAndSettle();

    expect(find.text('ListTile regression'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('长 Error 默认三行折叠，展开后显示完整错误与堆栈', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppLogPanelHost(child: SizedBox.expand())),
      ),
    );
    final longMessage = List<String>.generate(
      30,
      (index) => 'Render diagnostic line $index with a long explanation',
    ).join('\n');
    AppLogStore.instance.logError(
      source: AppErrorLogSource.flutter,
      message: longMessage,
      stackTrace: StackTrace.fromString('#0 build (widget.dart:10:3)'),
    );
    await tester.pump();

    await openPanel(tester);
    await tester.tap(find.text('Error'));
    await tester.pumpAndSettle();

    final previewFinder = find.byKey(
      const Key('app_logs_error_message_preview'),
    );
    final preview = tester.widget<Text>(previewFinder);
    expect(preview.maxLines, 3);
    expect(preview.overflow, TextOverflow.ellipsis);
    expect(
      find.byKey(const Key('app_logs_error_message_full')),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('app_logs_error_copy_button')),
        matching: find.byType(Tooltip),
      ),
      findsNothing,
    );

    await tester.tap(find.text('FLUTTER'));
    await tester.pumpAndSettle();

    expect(previewFinder, findsNothing);
    expect(
      find.byKey(const Key('app_logs_error_message_full')),
      findsOneWidget,
    );
    expect(find.text('Stack trace'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('FLUTTER'));
    await tester.pumpAndSettle();
    expect(previewFinder, findsOneWidget);
  });

  testWidgets('Error 捕获 FlutterError 与未处理异步异常并转发原 handler', (tester) async {
    final originalFlutterError = FlutterError.onError;
    final originalPlatformError = ui.PlatformDispatcher.instance.onError;
    var flutterForwarded = false;
    var platformForwarded = false;
    FlutterError.onError = (_) => flutterForwarded = true;
    ui.PlatformDispatcher.instance.onError = (_, __) {
      platformForwarded = true;
      return true;
    };
    addTearDown(() {
      FlutterError.onError = originalFlutterError;
      ui.PlatformDispatcher.instance.onError = originalPlatformError;
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppLogPanelHost(child: SizedBox.expand())),
      ),
    );

    FlutterError.onError!(
      FlutterErrorDetails(
        exception: StateError('framework failed'),
        stack: StackTrace.fromString('#0 build (widget.dart:10:3)'),
      ),
    );
    final handled = ui.PlatformDispatcher.instance.onError!(
      StateError('async failed'),
      StackTrace.fromString('#0 fetch (service.dart:20:5)'),
    );
    await tester.pump();

    expect(flutterForwarded, isTrue);
    expect(platformForwarded, isTrue);
    expect(handled, isTrue);
    expect(AppLogStore.instance.errors, hasLength(2));
    expect(
      AppLogStore.instance.errors.first.source,
      AppErrorLogSource.unhandled,
    );
    expect(AppLogStore.instance.errors.last.source, AppErrorLogSource.flutter);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Network 详情返回按钮并入详情头部，不再单独占一行', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    AppLogStore.instance.logNetworkRequest(
      id: 'network-1',
      at: DateTime.now(),
      path: '/product/product/list',
      method: 'GET',
      request: const <String, Object?>{'path': '/product/product/list'},
    );
    AppLogStore.instance.logNetworkResponse(
      id: 'network-1',
      at: DateTime.now(),
      request: const <String, Object?>{'path': '/product/product/list'},
      response: const <String, Object?>{
        'statusCode': 200,
        'data': <String, Object?>{'ok': true},
      },
      durationMs: 135,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppLogPanelHost(child: SizedBox.expand())),
      ),
    );

    await openPanel(tester);
    await tester.tap(find.text('/product/product/list').first);
    await tester.pumpAndSettle();

    expect(find.text('Request Details'), findsNothing);
    expect(
      find.byKey(const Key('app_logs_network_detail_back_button')),
      findsOneWidget,
    );
  });

  testWidgets('大 Response JSON 默认分批渲染，避免一次性展开全部节点', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final records = List.generate(60, (index) {
      return <String, Object?>{'id': index, 'title': 'item-$index'};
    });

    AppLogStore.instance.logNetworkRequest(
      id: 'network-large-response',
      at: DateTime.now(),
      path: '/shop/shop/list',
      method: 'GET',
      request: const <String, Object?>{'path': '/shop/shop/list'},
    );
    AppLogStore.instance.logNetworkResponse(
      id: 'network-large-response',
      at: DateTime.now(),
      request: const <String, Object?>{'path': '/shop/shop/list'},
      response: <String, Object?>{
        'statusCode': 200,
        'data': <String, Object?>{'records': records},
      },
      durationMs: 464,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppLogPanelHost(child: SizedBox.expand())),
      ),
    );

    await openPanel(tester);
    await tester.tap(find.text('/shop/shop/list').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Response'));
    await tester.pumpAndSettle();

    expect(find.textContaining('"item-23"'), findsOneWidget);
    expect(find.textContaining('"item-24"'), findsNothing);
    final showMoreFinder = find.text('显示后 24 项（共 60 项）');
    expect(showMoreFinder, findsOneWidget);

    await tester.ensureVisible(showMoreFinder);
    await tester.tap(showMoreFinder);
    await tester.pumpAndSettle();

    expect(find.textContaining('"item-24"'), findsOneWidget);
  });

  testWidgets('上拉灰色手柄后 bottom sheet 顶到状态栏下方', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          final data = MediaQuery.of(
            context,
          ).copyWith(padding: const EdgeInsets.only(top: 44));
          return MediaQuery(data: data, child: child!);
        },
        home: const Scaffold(body: AppLogPanelHost(child: SizedBox.expand())),
      ),
    );

    await openPanel(tester);

    final panelFinder = find.byKey(const Key('app_logs_bottom_panel'));
    final handleFinder = find.byKey(const Key('app_logs_drag_handle'));

    expect(panelFinder, findsOneWidget);
    expect(handleFinder, findsOneWidget);

    final initialTop = tester.getTopLeft(panelFinder).dy;
    expect(initialTop, greaterThan(0));

    await tester.drag(handleFinder, const Offset(0, -180));
    await tester.pumpAndSettle();

    final expandedTop = tester.getTopLeft(panelFinder).dy;
    expect(expandedTop, greaterThanOrEqualTo(43));
    expect(expandedTop, lessThanOrEqualTo(45));
  });
}
