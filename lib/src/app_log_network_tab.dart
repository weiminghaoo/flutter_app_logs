// ============================================================================
// app_log_network_tab.dart — Network 标签页
// ============================================================================

part of 'app_logs.dart';

class _NetworkTab extends StatefulWidget {
  final List<AppNetworkLogEntry> entries;
  final String? selectedId;
  final AppNetworkLogEntry? selected;
  final ValueChanged<String?> onSelect;

  const _NetworkTab({
    required this.entries,
    required this.selectedId,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<_NetworkTab> createState() => _NetworkTabState();
}

class _NetworkTabState extends State<_NetworkTab> {
  String _searchQuery = '';
  String? _selectedMethod;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = AppLogsConfig.theme;
    final filteredEntries =
        widget.entries.where((e) {
          if (_selectedMethod != null &&
              e.method.toUpperCase() != _selectedMethod) {
            return false;
          }
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            return e.path.toLowerCase().contains(query) ||
                e.method.toLowerCase().contains(query);
          }
          return true;
        }).toList();

    final isWideScreen = MediaQuery.sizeOf(context).width > 600;

    return Column(
      children: [
        // 搜索栏 + 方法过滤芯片
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: const BoxDecoration(
            color: _LP.paper,
            border: Border(bottom: BorderSide(color: _LP.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
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
                onChanged: (value) => setState(() => _searchQuery = value),
                onSubmitted: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _selectedMethod == null,
                      onSelected: (v) => setState(() => _selectedMethod = null),
                    ),
                    const SizedBox(width: 8),
                    ...['GET', 'POST', 'PUT', 'DELETE', 'PATCH'].map(
                      (method) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: method,
                          selected: _selectedMethod == method,
                          color: _methodColor(method),
                          onSelected:
                              (v) => setState(
                                () => _selectedMethod = v ? method : null,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
                            child: Column(
                              children: [
                                Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: _LP.paper,
                                    border: Border(
                                      bottom: BorderSide(color: _LP.border),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => widget.onSelect(null),
                                        child: Icon(
                                          Icons.arrow_back_ios_new,
                                          size: 18,
                                          color: theme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Request Details',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: _NetworkDetail(
                                    entry: widget.selected!,
                                  ),
                                ),
                              ],
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

        final hasError = e.error != null;
        final isSuccess = !hasError && e.response != null;

        final methodBadgeColor =
            hasError ? theme.error : _methodColor(e.method);
        final statusColor =
            hasError ? theme.error : (isSuccess ? theme.success : theme.debug);

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
                    Icon(
                      hasError
                          ? Icons.error_outline
                          : (isSuccess
                              ? Icons.check_circle_outline
                              : Icons.pending_outlined),
                      size: 13,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _LP.textSec,
                        fontFamily: 'SF Mono',
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

  const _NetworkDetail({required this.entry});

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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            color: _LP.paper,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          entry.path,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _LP.textPri,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
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
                Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: const Icon(Icons.copy, size: 16, color: _LP.textSec),
                    onPressed: () async {
                      try {
                        await _copyAppLogText(entry.path);
                      } catch (_) {
                        // 剪贴板写入失败时静默处理，不触发成功回调
                      }
                    },
                    visualDensity: VisualDensity.compact,
                  ),
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
