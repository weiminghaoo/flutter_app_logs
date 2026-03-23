// ============================================================================
// app_log_bottom_panel.dart — 底部弹出面板
// ============================================================================

part of 'app_logs.dart';

class _BottomPanel extends StatefulWidget {
  final bool open;
  final String? selectedNetworkId;
  final ValueChanged<String?> onSelectNetwork;
  final VoidCallback onClose;

  const _BottomPanel({
    required this.open,
    required this.selectedNetworkId,
    required this.onSelectNetwork,
    required this.onClose,
  });

  @override
  State<_BottomPanel> createState() => _BottomPanelState();
}

class _BottomPanelState extends State<_BottomPanel> {
  double _dragOffset = 0;
  bool _isDragging = false;

  @override
  void didUpdateWidget(_BottomPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.open && widget.open) {
      _dragOffset = 0;
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final dy = details.delta.dy;
    if (dy > 0 || _dragOffset > 0) {
      setState(() {
        _isDragging = true;
        _dragOffset = (_dragOffset + dy).clamp(0.0, double.infinity);
      });
    }
  }

  void _onDragEnd(DragEndDetails details) {
    final height = MediaQuery.sizeOf(context).height * 0.85;
    final velocity = details.primaryVelocity ?? 0;
    final shouldClose = _dragOffset > height * 0.2 || velocity > 400;

    if (shouldClose) {
      setState(() => _isDragging = false);
      widget.onClose();
    } else {
      setState(() {
        _isDragging = false;
        _dragOffset = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final height = size.height * 0.85;
    final theme = AppLogsConfig.theme;

    return AnimatedPositioned(
      duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300),
      curve: Curves.fastOutSlowIn,
      left: 0,
      right: 0,
      bottom: widget.open ? -_dragOffset : -height,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: const BoxDecoration(
            color: _LP.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // 拖拽手柄
              GestureDetector(
                onVerticalDragUpdate: _onDragUpdate,
                onVerticalDragEnd: _onDragEnd,
                onVerticalDragCancel:
                    () => setState(() {
                      _isDragging = false;
                      _dragOffset = 0;
                    }),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _LP.handle,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),

              // 标题栏
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: _LP.border)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.bug_report_rounded,
                      color: theme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'App Logs',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _LP.textPri,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            AppLogStore.instance.clearConsole();
                            AppLogStore.instance.clearNetwork();
                          },
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: _LP.textSec,
                          ),
                        ),
                        IconButton(
                          onPressed: widget.onClose,
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: _LP.textSec,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // TabBar + TabBarView
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  initialIndex: 0,
                  child: Column(
                    children: [
                      Material(
                        color: _LP.bg,
                        child: TabBar(
                          labelColor: theme.primary,
                          unselectedLabelColor: _LP.textSec,
                          indicatorColor: theme.primary,
                          dividerColor: _LP.border,
                          indicatorWeight: 3,
                          unselectedLabelStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          tabs: const [
                            Tab(text: 'Network'),
                            Tab(text: 'Console'),
                          ],
                        ),
                      ),
                      Expanded(
                        // 面板关闭时不订阅 AppLogStore，避免日志写入触发不必要的 rebuild
                        child:
                            widget.open
                                ? AnimatedBuilder(
                                  animation: AppLogStore.instance,
                                  builder: (context, _) {
                                    final console =
                                        AppLogStore.instance.console;
                                    final network =
                                        AppLogStore.instance.network;

                                    final resolvedSelectedId =
                                        widget.selectedNetworkId;
                                    final selected =
                                        resolvedSelectedId == null
                                            ? null
                                            : network
                                                .where(
                                                  (e) =>
                                                      e.id ==
                                                      resolvedSelectedId,
                                                )
                                                .firstOrNull;

                                    return TabBarView(
                                      children: [
                                        _NetworkTab(
                                          entries: network,
                                          selectedId: resolvedSelectedId,
                                          selected: selected,
                                          onSelect: widget.onSelectNetwork,
                                        ),
                                        _ConsoleTab(entries: console),
                                      ],
                                    );
                                  },
                                )
                                : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
