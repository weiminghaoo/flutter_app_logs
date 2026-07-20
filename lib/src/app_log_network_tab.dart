// ============================================================================
// app_log_network_tab.dart — Network 标签页
// ============================================================================

part of 'app_logs.dart';

enum _NetworkStatusFilter {
  pending('Pending'),
  http2xx('2xx'),
  http3xx('3xx'),
  http4xx('4xx'),
  http5xx('5xx'),
  error('Error'),
  cancelled('Cancelled');

  const _NetworkStatusFilter(this.label);

  final String label;
}

enum _NetworkDurationFilter {
  fast('<500ms'),
  medium('500ms–1s'),
  slow('≥1s');

  const _NetworkDurationFilter(this.label);

  final String label;
}

String _networkStatusLabel(AppNetworkLogEntry entry) {
  final statusCode = entry.statusCode;
  if (statusCode != null) return '$statusCode';
  return switch (entry.state) {
    AppNetworkLogState.pending => 'Pending',
    AppNetworkLogState.success => 'Success',
    AppNetworkLogState.error => 'Error',
    AppNetworkLogState.cancelled => 'Cancelled',
  };
}

Color _networkStatusColor(AppNetworkLogEntry entry) {
  final theme = AppLogsConfig.theme;
  final statusCode = entry.statusCode;
  if (statusCode != null) {
    if (statusCode >= 400) return theme.error;
    if (statusCode >= 300) return theme.primary;
    return theme.success;
  }
  return switch (entry.state) {
    AppNetworkLogState.pending => theme.primary,
    AppNetworkLogState.success => theme.success,
    AppNetworkLogState.error => theme.error,
    AppNetworkLogState.cancelled => theme.debug,
  };
}

IconData _networkStatusIcon(AppNetworkLogEntry entry) {
  return switch (entry.state) {
    AppNetworkLogState.pending => Icons.pending_outlined,
    AppNetworkLogState.success => Icons.check_circle_outline,
    AppNetworkLogState.error => Icons.error_outline,
    AppNetworkLogState.cancelled => Icons.cancel_outlined,
  };
}

class _NetworkTab extends StatefulWidget {
  final List<AppNetworkLogEntry> entries;
  final String? selectedId;
  final AppNetworkLogEntry? selected;
  final ValueChanged<String?> onSelect;
  final bool showToolbar;

  const _NetworkTab({
    required this.entries,
    required this.selectedId,
    required this.selected,
    required this.onSelect,
    required this.showToolbar,
  });

  @override
  State<_NetworkTab> createState() => _NetworkTabState();
}

class _NetworkTabState extends State<_NetworkTab> {
  String _searchQuery = '';
  String? _selectedMethod;
  _NetworkStatusFilter? _selectedStatus;
  String? _selectedHost;
  _NetworkDurationFilter? _selectedDuration;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _NetworkTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.showToolbar && widget.showToolbar) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocusNode.requestFocus();
      });
    }
    if (oldWidget.showToolbar && !widget.showToolbar) {
      _searchFocusNode.unfocus();
      if (_hasActiveFilters) {
        _searchController.clear();
        _searchQuery = '';
        _selectedMethod = null;
        _selectedStatus = null;
        _selectedHost = null;
        _selectedDuration = null;
      }
    }
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedMethod != null ||
      _selectedStatus != null ||
      _selectedHost != null ||
      _selectedDuration != null;

  Color _methodColor(String method) {
    final theme = AppLogsConfig.theme;
    switch (method.toUpperCase()) {
      case 'GET':
        return theme.info;
      case 'POST':
        return theme.success;
      case 'PUT':
        return theme.primary;
      case 'DELETE':
        return theme.error;
      case 'PATCH':
        return theme.patch;
      default:
        return _LP.textSec;
    }
  }

  Color _durationColor(int ms) {
    final theme = AppLogsConfig.theme;
    if (ms < 500) return theme.success;
    if (ms < 1000) return theme.primary;
    return theme.error;
  }

  bool _matchesStatus(AppNetworkLogEntry entry, _NetworkStatusFilter filter) {
    final statusCode = entry.statusCode;
    return switch (filter) {
      _NetworkStatusFilter.pending => entry.state == AppNetworkLogState.pending,
      _NetworkStatusFilter.http2xx =>
        statusCode != null && statusCode >= 200 && statusCode < 300,
      _NetworkStatusFilter.http3xx =>
        statusCode != null && statusCode >= 300 && statusCode < 400,
      _NetworkStatusFilter.http4xx =>
        statusCode != null && statusCode >= 400 && statusCode < 500,
      _NetworkStatusFilter.http5xx =>
        statusCode != null && statusCode >= 500 && statusCode < 600,
      _NetworkStatusFilter.error =>
        entry.state == AppNetworkLogState.error && statusCode == null,
      _NetworkStatusFilter.cancelled =>
        entry.state == AppNetworkLogState.cancelled,
    };
  }

  bool _matchesDuration(
    AppNetworkLogEntry entry,
    _NetworkDurationFilter filter,
  ) {
    final durationMs = entry.durationMs;
    if (durationMs == null) return false;
    return switch (filter) {
      _NetworkDurationFilter.fast => durationMs < 500,
      _NetworkDurationFilter.medium => durationMs >= 500 && durationMs < 1000,
      _NetworkDurationFilter.slow => durationMs >= 1000,
    };
  }

  bool _matchesFilters(AppNetworkLogEntry entry) {
    if (_selectedMethod != null &&
        entry.method.toUpperCase() != _selectedMethod) {
      return false;
    }
    if (_selectedStatus != null && !_matchesStatus(entry, _selectedStatus!)) {
      return false;
    }
    if (_selectedHost != null && entry.host != _selectedHost) {
      return false;
    }
    if (_selectedDuration != null &&
        !_matchesDuration(entry, _selectedDuration!)) {
      return false;
    }
    if (_searchQuery.isEmpty) return true;

    final query = _searchQuery.toLowerCase();
    return entry.path.toLowerCase().contains(query) ||
        entry.url.toLowerCase().contains(query) ||
        entry.host.toLowerCase().contains(query) ||
        entry.method.toLowerCase().contains(query) ||
        entry.statusCode?.toString().contains(query) == true;
  }

  List<String> _availableMethods() {
    const preferredOrder = <String>['GET', 'POST', 'PUT', 'DELETE', 'PATCH'];
    final methods =
        widget.entries
            .map((entry) => entry.method.toUpperCase())
            .where((method) => method.isNotEmpty)
            .toSet()
            .toList();
    methods.sort((a, b) {
      final aIndex = preferredOrder.indexOf(a);
      final bIndex = preferredOrder.indexOf(b);
      if (aIndex == -1 && bIndex == -1) return a.compareTo(b);
      if (aIndex == -1) return 1;
      if (bIndex == -1) return -1;
      return aIndex.compareTo(bIndex);
    });
    return methods;
  }

  List<String> _availableHosts() =>
      widget.entries
          .map((entry) => entry.host)
          .where((host) => host.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

  Color _statusFilterColor(_NetworkStatusFilter filter) {
    final theme = AppLogsConfig.theme;
    return switch (filter) {
      _NetworkStatusFilter.pending ||
      _NetworkStatusFilter.http3xx => theme.primary,
      _NetworkStatusFilter.http2xx => theme.success,
      _NetworkStatusFilter.http4xx ||
      _NetworkStatusFilter.http5xx ||
      _NetworkStatusFilter.error => theme.error,
      _NetworkStatusFilter.cancelled => theme.debug,
    };
  }

  Color _durationFilterColor(_NetworkDurationFilter filter) {
    return switch (filter) {
      _NetworkDurationFilter.fast => _durationColor(0),
      _NetworkDurationFilter.medium => _durationColor(500),
      _NetworkDurationFilter.slow => _durationColor(1000),
    };
  }

  Widget _buildFilterRow({required String label, required List<Widget> chips}) {
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: _LP.textSec),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < chips.length; index++) ...[
                    if (index > 0) const SizedBox(width: 8),
                    chips[index],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppLogsConfig.theme;
    final filteredEntries = widget.entries.where(_matchesFilters).toList();
    final methods = _availableMethods();
    final hosts = _availableHosts();

    final isWideScreen = MediaQuery.sizeOf(context).width > 600;

    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child:
              widget.showToolbar
                  ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: _LP.paper,
                      border: Border(bottom: BorderSide(color: _LP.border)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          decoration: InputDecoration(
                            hintText: 'Search network requests...',
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 20,
                              color: _LP.textSec,
                            ),
                            suffixIcon:
                                _searchQuery.isNotEmpty
                                    ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                    : null,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: _LP.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: _LP.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: theme.primary),
                            ),
                          ),
                          textInputAction: TextInputAction.search,
                          onChanged:
                              (value) => setState(() => _searchQuery = value),
                          onSubmitted:
                              (value) => setState(() => _searchQuery = value),
                        ),
                        const SizedBox(height: 6),
                        _buildFilterRow(
                          label: 'Method',
                          chips: [
                            _FilterChip(
                              key: const Key(
                                'app_logs_network_filter_method_all',
                              ),
                              label: 'All',
                              selected: _selectedMethod == null,
                              onSelected:
                                  (_) => setState(() => _selectedMethod = null),
                            ),
                            for (final method in methods)
                              _FilterChip(
                                key: ValueKey(
                                  'app_logs_network_filter_method_$method',
                                ),
                                label: method,
                                selected: _selectedMethod == method,
                                color: _methodColor(method),
                                onSelected:
                                    (selected) => setState(
                                      () =>
                                          _selectedMethod =
                                              selected ? method : null,
                                    ),
                              ),
                          ],
                        ),
                        _buildFilterRow(
                          label: 'Status',
                          chips: [
                            _FilterChip(
                              key: const Key(
                                'app_logs_network_filter_status_all',
                              ),
                              label: 'All',
                              selected: _selectedStatus == null,
                              onSelected:
                                  (_) => setState(() => _selectedStatus = null),
                            ),
                            for (final status in _NetworkStatusFilter.values)
                              _FilterChip(
                                key: ValueKey(
                                  'app_logs_network_filter_status_${status.name}',
                                ),
                                label: status.label,
                                selected: _selectedStatus == status,
                                color: _statusFilterColor(status),
                                onSelected:
                                    (selected) => setState(
                                      () =>
                                          _selectedStatus =
                                              selected ? status : null,
                                    ),
                              ),
                          ],
                        ),
                        _buildFilterRow(
                          label: 'Host',
                          chips: [
                            _FilterChip(
                              key: const Key(
                                'app_logs_network_filter_host_all',
                              ),
                              label: 'All',
                              selected: _selectedHost == null,
                              onSelected:
                                  (_) => setState(() => _selectedHost = null),
                            ),
                            for (final host in hosts)
                              _FilterChip(
                                key: ValueKey(
                                  'app_logs_network_filter_host_$host',
                                ),
                                label: host,
                                selected: _selectedHost == host,
                                onSelected:
                                    (selected) => setState(
                                      () =>
                                          _selectedHost =
                                              selected ? host : null,
                                    ),
                              ),
                          ],
                        ),
                        _buildFilterRow(
                          label: 'Duration',
                          chips: [
                            _FilterChip(
                              key: const Key(
                                'app_logs_network_filter_duration_all',
                              ),
                              label: 'All',
                              selected: _selectedDuration == null,
                              onSelected:
                                  (_) =>
                                      setState(() => _selectedDuration = null),
                            ),
                            for (final duration
                                in _NetworkDurationFilter.values)
                              _FilterChip(
                                key: ValueKey(
                                  'app_logs_network_filter_duration_${duration.name}',
                                ),
                                label: duration.label,
                                selected: _selectedDuration == duration,
                                color: _durationFilterColor(duration),
                                onSelected:
                                    (selected) => setState(
                                      () =>
                                          _selectedDuration =
                                              selected ? duration : null,
                                    ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  )
                  : const SizedBox.shrink(),
        ),

        // 内容区
        Expanded(
          child:
              filteredEntries.isEmpty
                  ? const Center(
                    child: Text(
                      'No requests found',
                      style: TextStyle(color: _LP.textSec),
                    ),
                  )
                  : isWideScreen
                  ? Row(
                    children: [
                      SizedBox(
                        width: 300,
                        child: _buildList(filteredEntries, true),
                      ),
                      const VerticalDivider(width: 1, color: _LP.border),
                      Expanded(
                        child:
                            widget.selected == null
                                ? const Center(
                                  child: Text(
                                    'Select a request to view details',
                                    style: TextStyle(color: _LP.textSec),
                                  ),
                                )
                                : _NetworkDetail(entry: widget.selected!),
                      ),
                    ],
                  )
                  : Stack(
                    children: [
                      _buildList(filteredEntries, false),
                      if (widget.selected != null)
                        Positioned.fill(
                          child: Container(
                            color: _LP.bg,
                            child: _NetworkDetail(
                              entry: widget.selected!,
                              onBack: () => widget.onSelect(null),
                            ),
                          ),
                        ),
                    ],
                  ),
        ),
      ],
    );
  }

  Widget _buildList(List<AppNetworkLogEntry> entries, bool isWideScreen) {
    final theme = AppLogsConfig.theme;
    return ListView.builder(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final e = entries[index];
        final isSelected = e.id == widget.selectedId;

        final time =
            '${e.at.hour.toString().padLeft(2, '0')}:${e.at.minute.toString().padLeft(2, '0')}:${e.at.second.toString().padLeft(2, '0')}';

        final statusColor = _networkStatusColor(e);
        final methodBadgeColor =
            e.state == AppNetworkLogState.error
                ? theme.error
                : _methodColor(e.method);

        return InkWell(
          onTap: () => widget.onSelect(e.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? theme.primary.withValues(alpha: 0.04)
                      : Colors.transparent,
              border: Border(
                left:
                    isSelected
                        ? BorderSide(color: theme.primary, width: 2.5)
                        : BorderSide.none,
                bottom: const BorderSide(color: _LP.border),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: methodBadgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        e.method.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: methodBadgeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.path,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _LP.textPri,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(_networkStatusIcon(e), size: 13, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _LP.textSec,
                        fontFamily: 'SF Mono',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _networkStatusLabel(e),
                      key: ValueKey('app_logs_network_status_${e.id}'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                    const Spacer(),
                    if (e.durationMs != null)
                      Text(
                        '${e.durationMs}ms',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _durationColor(e.durationMs!),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// _NetworkDetail — 单条请求详情面板
// ============================================================================

class _NetworkDetail extends StatelessWidget {
  final AppNetworkLogEntry entry;
  final VoidCallback? onBack;

  const _NetworkDetail({required this.entry, this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = AppLogsConfig.theme;
    final request = entry.request;
    final response = entry.response;
    final error = entry.error;

    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部 URL 信息栏
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            color: _LP.paper,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (onBack != null) ...[
                            _NetworkBackChevron(
                              actionKey: const Key(
                                'app_logs_network_detail_back_button',
                              ),
                              onPressed: onBack,
                              color: theme.primary,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              entry.path,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _LP.textPri,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _LP.badgeBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              entry.method.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _LP.badgeText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _networkStatusLabel(entry),
                            key: const Key('app_logs_network_detail_status'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _networkStatusColor(entry),
                            ),
                          ),
                          if (entry.durationMs != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${entry.durationMs}ms',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _LP.textSec,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      button: true,
                      label: 'Copy URL',
                      child: IconButton(
                        key: const Key('app_logs_network_copy_url_button'),
                        icon: const Icon(
                          Icons.copy,
                          size: 16,
                          color: _LP.textSec,
                        ),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _copyNetworkText(entry.url),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Copy as cURL',
                      child: IconButton(
                        key: const Key('app_logs_network_copy_curl_button'),
                        icon: const Icon(
                          Icons.terminal_rounded,
                          size: 17,
                          color: _LP.textSec,
                        ),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _copyNetworkText(entry.toCurl()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 子 TabBar
          TabBar(
            labelColor: theme.primary,
            unselectedLabelColor: _LP.textSec,
            indicatorColor: theme.primary,
            indicatorWeight: 2,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            tabs: const [
              Tab(text: 'Request'),
              Tab(text: 'Response'),
              Tab(text: 'Error'),
            ],
          ),

          // 子 TabBarView
          Expanded(
            child: TabBarView(
              children: [
                _JsonBlock(value: request),
                response == null
                    ? const Center(
                      child: Text(
                        'No response yet',
                        style: TextStyle(color: _LP.textSec),
                      ),
                    )
                    : _JsonBlock(value: response['data'] ?? response),
                error == null
                    ? const Center(
                      child: Text(
                        'No error',
                        style: TextStyle(color: _LP.textSec),
                      ),
                    )
                    : _JsonBlock(value: error),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _copyNetworkText(String text) async {
  try {
    await _copyAppLogText(text);
  } catch (_) {
    // 剪贴板写入失败时静默处理，不触发成功回调
  }
}

class _NetworkBackChevron extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color color;
  final Key? actionKey;

  const _NetworkBackChevron({
    required this.onPressed,
    required this.color,
    this.actionKey,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: actionKey,
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Icon(Icons.arrow_back_ios_new, size: 18, color: color),
      ),
    );
  }
}
