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

/// 为通过 `MaterialApp.builder` 注入的调试面板提供独立的 Overlay。
///
/// 此时应用 Navigator 的 Overlay 位于 [AppLogPanelHost.child] 内部，和面板
/// 是兄弟节点，面板中的 TextField 无法使用它来显示文字选择层。
class _AppLogLocalOverlay extends StatefulWidget {
  final Widget child;

  const _AppLogLocalOverlay({required this.child});

  @override
  State<_AppLogLocalOverlay> createState() => _AppLogLocalOverlayState();
}

class _AppLogLocalOverlayState extends State<_AppLogLocalOverlay> {
  late final OverlayEntry _entry;

  @override
  void initState() {
    super.initState();
    _entry = OverlayEntry(builder: (_) => widget.child);
  }

  @override
  void didUpdateWidget(covariant _AppLogLocalOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _entry.markNeedsBuild();
  }

  @override
  void dispose() {
    _entry.remove();
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Overlay(clipBehavior: Clip.none, initialEntries: [_entry]);
  }
}

class _AppLogPanelHostState extends State<AppLogPanelHost> {
  bool _open = false;
  String? _selectedNetworkId;
  Offset? _btnPos;
  bool _isDragging = false;
  bool _isErrorCaptureAttached = false;
  bool _searchFocused = false;

  static const double _btnSize = 44.0;
  static const double _btnEdge = 16.0;

  @override
  void initState() {
    super.initState();
    if (AppLogsConfig.enabled) {
      _AppErrorCapture.instance.attach();
      _isErrorCaptureAttached = true;
    }
  }

  @override
  void dispose() {
    if (_isErrorCaptureAttached) {
      _AppErrorCapture.instance.detach();
    }
    super.dispose();
  }

  // 注：不根据 child 的 identity 变化自动关闭面板。
  // Flutter 中 widget 是一次性对象，任何上层 rebuild（键盘 viewInsets 变化、
  // MediaQuery、主题、locale 等）都会让 child 重新实例化，!identical 恒为 true。
  // 若据此关闭面板，会导致搜索框拉起键盘时面板被误关。关闭面板统一交给：
  // 遮罩点击 / 浮动按钮 toggle / 关闭按钮 三条显式路径。

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
              onTap: () {
                // 搜索框已获焦或键盘可见时，只收起键盘不关闭面板；
                // 避免键盘弹出/收起时布局变化导致遮罩层误触 tap 关闭面板
                final keyboardHeight =
                    MediaQuery.of(context).viewInsets.bottom;
                if (keyboardHeight > 0 || _searchFocused) {
                  FocusScope.of(context).unfocus();
                  return;
                }
                setState(() {
                  _open = false;
                  _selectedNetworkId = null;
                });
              },
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black.withValues(alpha: 0.4)),
            ),
          ),

        // 底部调试面板
        _AppLogLocalOverlay(
          child: _BottomPanel(
            open: _open,
            selectedNetworkId: _selectedNetworkId,
            onSelectNetwork: (id) => setState(() => _selectedNetworkId = id),
            onSearchFocusChange: (focused) =>
                setState(() => _searchFocused = focused),
            onClose:
                () => setState(() {
                  _open = false;
                  _selectedNetworkId = null;
                  _searchFocused = false;
                }),
          ),
        ),

        // 复制成功提示放在宿主 Stack 的最后一层，确保盖在日志面板之上。
        const _CopyFeedbackToast(),
      ],
    );
  }
}
