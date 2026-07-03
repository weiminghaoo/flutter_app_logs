import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_logs/flutter_app_logs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AppLogsConfig.init(enabled: true, consoleMinLevel: AppLogLevel.debug);
    AppLogStore.instance.clearConsole();
    AppLogStore.instance.clearNetwork();
  });

  tearDown(() {
    AppLogsConfig.init(enabled: false);
    AppLogStore.instance.clearConsole();
    AppLogStore.instance.clearNetwork();
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
