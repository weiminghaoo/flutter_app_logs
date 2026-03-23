// ============================================================================
// app_log_panel_host.dart — 调试面板宿主层
// ============================================================================

part of 'app_logs.dart';

/// 调试日志面板的宿主 Widget。
///
/// 将整个应用内容（[child]）包裹在 Stack 里，并在其上叠加：
/// 1. 可拖拽的浮动调试按钮
/// 2. 半透明遮罩（面板打开时显示，点击关闭面板）
/// 3. [_BottomPanel] 底部滑入面板
///
/// [AppLogsConfig.enabled] == false 时直接返回 [child]，零开销。
class AppLogPanelHost extends StatefulWidget {
  final Widget child;

  const AppLogPanelHost({super.key, required this.child});

  @override
  State<AppLogPanelHost> createState() => _AppLogPanelHostState();
}

class _AppLogPanelHostState extends State<AppLogPanelHost> {
  bool _open = false;
  String? _selectedNetworkId;
  Offset? _btnPos;
  bool _isDragging = false;

  static const double _btnSize = 44.0;
  static const double _btnEdge = 16.0;

  @override
  void didUpdateWidget(covariant AppLogPanelHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.child, widget.child)) {
      _open = false;
      _selectedNetworkId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AppLogsConfig.enabled) return widget.child;

    final size = MediaQuery.of(context).size;
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final topSafe = MediaQuery.of(context).padding.top;

    _btnPos ??= Offset(
      size.width - _btnSize - _btnEdge,
      size.height - _btnSize - _btnEdge - bottomSafe,
    );

    final clampedPos = Offset(
      _btnPos!.dx.clamp(
        _btnEdge,
        math.max(_btnEdge, size.width - _btnSize - _btnEdge),
      ),
      _btnPos!.dy.clamp(
        topSafe + _btnEdge,
        math.max(
          topSafe + _btnEdge,
          size.height - _btnSize - _btnEdge - bottomSafe,
        ),
      ),
    );

    return Stack(
      children: [
        KeyedSubtree(child: widget.child),

        // 浮动调试按钮
        Positioned(
          left: clampedPos.dx,
          top: clampedPos.dy,
          child: GestureDetector(
            onPanStart: (_) {
              _isDragging = false;
            },
            onPanUpdate: (d) {
              if (!_isDragging && d.delta.distance > 1) _isDragging = true;
              setState(() {
                _btnPos = Offset(
                  (_btnPos!.dx + d.delta.dx).clamp(
                    _btnEdge,
                    size.width - _btnSize - _btnEdge,
                  ),
                  (_btnPos!.dy + d.delta.dy).clamp(
                    topSafe + _btnEdge,
                    size.height - _btnSize - _btnEdge - bottomSafe,
                  ),
                );
              });
            },
            onPanEnd: (_) {
              if (!_isDragging) {
                setState(() {
                  _open = !_open;
                  _selectedNetworkId = null;
                });
              }
              _isDragging = false;
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: _btnSize,
                height: _btnSize,
                decoration: BoxDecoration(
                  color: AppLogsConfig.theme.primary,
                  borderRadius: BorderRadius.circular(_btnSize / 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.bug_report_rounded,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),

        // 半透明遮罩
        if (_open)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() {
                _open = false;
                _selectedNetworkId = null;
              }),
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black.withValues(alpha: 0.4)),
            ),
          ),

        // 底部调试面板
        _BottomPanel(
          open: _open,
          selectedNetworkId: _selectedNetworkId,
          onSelectNetwork: (id) => setState(() => _selectedNetworkId = id),
          onClose: () => setState(() {
            _open = false;
            _selectedNetworkId = null;
          }),
        ),
      ],
    );
  }
}
