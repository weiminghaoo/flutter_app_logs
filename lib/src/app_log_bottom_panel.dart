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

class _BottomPanelState extends State<_BottomPanel>
    with SingleTickerProviderStateMixin {
  static const double _collapsedHeightFactor = 0.85;

  double _dragOffset = 0;
  double _panelHeight = 0;
  bool _isDragging = false;
  late final TabController _tabController;
  int _selectedTabIndex = 0;
  bool _showNetworkFilters = false;
  bool _showConsoleFilters = false;
  bool _showErrorFilters = false;
  bool _markErrorsReadScheduled = false;

  bool get _isToolbarVisible => switch (_selectedTabIndex) {
    0 => _showNetworkFilters,
    1 => _showConsoleFilters,
    _ => _showErrorFilters,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChanged);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_handleTabChanged)
      ..dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (_selectedTabIndex == _tabController.index) return;
    setState(() => _selectedTabIndex = _tabController.index);
    _scheduleMarkErrorsReadIfVisible();
  }

  @override
  void didUpdateWidget(_BottomPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.open && widget.open) {
      _dragOffset = 0;
      _panelHeight = 0;
      _showNetworkFilters = false;
      _showConsoleFilters = false;
      _showErrorFilters = false;
      _scheduleMarkErrorsReadIfVisible();
    }
  }

  double _collapsedHeight(double screenHeight) =>
      screenHeight * _collapsedHeightFactor;

  double _resolvedPanelHeight(double screenHeight, double topSafe) {
    final collapsedHeight = _collapsedHeight(screenHeight);
    final expandedHeight = math.max(collapsedHeight, screenHeight - topSafe);
    if (_panelHeight == 0) return collapsedHeight;
    return _panelHeight.clamp(collapsedHeight, expandedHeight);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final topSafe = MediaQuery.paddingOf(context).top;
    final collapsedHeight = _collapsedHeight(screenHeight);
    final expandedHeight = math.max(collapsedHeight, screenHeight - topSafe);
    final currentHeight = _resolvedPanelHeight(screenHeight, topSafe);
    final dy = details.delta.dy;

    setState(() {
      _isDragging = true;

      if (dy < 0) {
        _panelHeight = (currentHeight - dy).clamp(
          collapsedHeight,
          expandedHeight,
        );
        _dragOffset = 0;
        return;
      }

      var remainingDy = dy;
      if (currentHeight > collapsedHeight) {
        final shrinkable = currentHeight - collapsedHeight;
        final heightDelta = remainingDy.clamp(0.0, shrinkable);
        _panelHeight = (currentHeight - heightDelta).clamp(
          collapsedHeight,
          expandedHeight,
        );
        remainingDy -= heightDelta;
      }

      _dragOffset = (_dragOffset + remainingDy).clamp(0.0, double.infinity);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final topSafe = MediaQuery.paddingOf(context).top;
    final collapsedHeight = _collapsedHeight(screenHeight);
    final expandedHeight = math.max(collapsedHeight, screenHeight - topSafe);
    final currentHeight = _resolvedPanelHeight(screenHeight, topSafe);
    final expandThreshold =
        collapsedHeight + (expandedHeight - collapsedHeight) / 2;
    final velocity = details.primaryVelocity ?? 0;
    final shouldClose = _dragOffset > collapsedHeight * 0.2 || velocity > 400;
    final shouldExpand = currentHeight > expandThreshold || velocity < -400;

    if (shouldClose) {
      setState(() {
        _isDragging = false;
        _dragOffset = 0;
        _panelHeight = 0;
      });
      widget.onClose();
    } else {
      setState(() {
        _isDragging = false;
        _dragOffset = 0;
        _panelHeight = shouldExpand ? expandedHeight : collapsedHeight;
      });
    }
  }

  void _toggleToolbar() {
    setState(() {
      if (_selectedTabIndex == 0) {
        _showNetworkFilters = !_showNetworkFilters;
      } else if (_selectedTabIndex == 1) {
        _showConsoleFilters = !_showConsoleFilters;
      } else {
        _showErrorFilters = !_showErrorFilters;
      }
    });
  }

  void _scheduleMarkErrorsReadIfVisible() {
    if (_markErrorsReadScheduled ||
        !widget.open ||
        _selectedTabIndex != 2 ||
        AppLogStore.instance.unreadErrorCount == 0) {
      return;
    }
    _markErrorsReadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markErrorsReadScheduled = false;
      if (!mounted || !widget.open || _selectedTabIndex != 2) return;
      AppLogStore.instance.markErrorsRead();
    });
  }

  Widget _buildTabBar(AppLogsTheme theme, int unreadErrorCount) {
    return TabBar(
      controller: _tabController,
      labelColor: theme.primary,
      unselectedLabelColor: _LP.textSec,
      indicatorColor: theme.primary,
      dividerColor: _LP.border,
      indicatorWeight: 3,
      labelPadding: EdgeInsets.zero,
      unselectedLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      tabs: [
        const Tab(text: 'Network'),
        const Tab(text: 'Console'),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Error'),
              if (unreadErrorCount > 0) ...[
                const SizedBox(width: 5),
                Container(
                  key: const Key('app_logs_error_unread_badge'),
                  height: 18,
                  constraints: const BoxConstraints(minWidth: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.error,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    unreadErrorCount > 99 ? '99+' : '$unreadErrorCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final topSafe = MediaQuery.paddingOf(context).top;
    final height = _resolvedPanelHeight(size.height, topSafe);
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
          key: const Key('app_logs_bottom_panel'),
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
                key: const Key('app_logs_drag_handle'),
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
                          key: const Key('app_logs_toggle_toolbar_button'),
                          onPressed: _toggleToolbar,
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color:
                                _isToolbarVisible ? theme.primary : _LP.textSec,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            AppLogStore.instance.clearConsole();
                            AppLogStore.instance.clearNetwork();
                            AppLogStore.instance.clearErrors();
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
                  length: 3,
                  initialIndex: 0,
                  child: Column(
                    children: [
                      Material(
                        color: _LP.bg,
                        child:
                            widget.open
                                ? AnimatedBuilder(
                                  animation: AppLogStore.instance,
                                  builder:
                                      (context, _) => _buildTabBar(
                                        theme,
                                        AppLogStore.instance.unreadErrorCount,
                                      ),
                                )
                                : _buildTabBar(theme, 0),
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
                                    final errors = AppLogStore.instance.errors;
                                    _scheduleMarkErrorsReadIfVisible();

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
                                      controller: _tabController,
                                      children: [
                                        _NetworkTab(
                                          entries: network,
                                          selectedId: resolvedSelectedId,
                                          selected: selected,
                                          onSelect: widget.onSelectNetwork,
                                          showToolbar: _showNetworkFilters,
                                        ),
                                        _ConsoleTab(
                                          entries: console,
                                          showToolbar: _showConsoleFilters,
                                        ),
                                        _ErrorTab(
                                          entries: errors,
                                          showToolbar: _showErrorFilters,
                                        ),
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
