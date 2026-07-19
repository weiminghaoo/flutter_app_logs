// ============================================================================
// app_log_error_tab.dart — Error 标签页
// ============================================================================

part of 'app_logs.dart';

class _ErrorTab extends StatefulWidget {
  final List<AppErrorLogEntry> entries;
  final bool showToolbar;

  const _ErrorTab({required this.entries, required this.showToolbar});

  @override
  State<_ErrorTab> createState() => _ErrorTabState();
}

class _ErrorTabState extends State<_ErrorTab> {
  String _searchQuery = '';
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
  void didUpdateWidget(covariant _ErrorTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.showToolbar && widget.showToolbar) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocusNode.requestFocus();
      });
    }
    if (oldWidget.showToolbar && !widget.showToolbar) {
      _searchFocusNode.unfocus();
      if (_searchQuery.isNotEmpty) {
        _searchController.clear();
        _searchQuery = '';
      }
    }
  }

  String _sourceLabel(AppErrorLogEntry entry) => switch (entry.source) {
    AppErrorLogSource.flutter => 'FLUTTER',
    AppErrorLogSource.unhandled => 'UNHANDLED',
    AppErrorLogSource.console when entry.message.contains('[Network Error]') =>
      'NETWORK',
    AppErrorLogSource.console when entry.message.contains('[App Error') =>
      'APP',
    AppErrorLogSource.console => 'CONSOLE',
  };

  @override
  Widget build(BuildContext context) {
    final theme = AppLogsConfig.theme;
    final query = _searchQuery.toLowerCase();
    final filteredEntries =
        widget.entries.where((entry) {
          if (query.isEmpty) return true;
          return entry.message.toLowerCase().contains(query) ||
              (entry.stackTrace?.toLowerCase().contains(query) ?? false) ||
              _sourceLabel(entry).toLowerCase().contains(query);
        }).toList();

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
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Search errors...',
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
                    ),
                  )
                  : const SizedBox.shrink(),
        ),
        Expanded(
          child:
              filteredEntries.isEmpty
                  ? const Center(
                    child: Text(
                      'No errors found',
                      style: TextStyle(color: _LP.textSec),
                    ),
                  )
                  : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                    itemCount: filteredEntries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = filteredEntries[index];
                      return _ErrorLogCard(
                        key: ObjectKey(entry),
                        entry: entry,
                        sourceLabel: _sourceLabel(entry),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}

class _ErrorLogCard extends StatefulWidget {
  final AppErrorLogEntry entry;
  final String sourceLabel;

  const _ErrorLogCard({
    super.key,
    required this.entry,
    required this.sourceLabel,
  });

  @override
  State<_ErrorLogCard> createState() => _ErrorLogCardState();
}

class _ErrorLogCardState extends State<_ErrorLogCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final errorColor = AppLogsConfig.theme.error;
    final time =
        '${widget.entry.at.hour.toString().padLeft(2, '0')}:'
        '${widget.entry.at.minute.toString().padLeft(2, '0')}:'
        '${widget.entry.at.second.toString().padLeft(2, '0')}';
    final stackTrace = widget.entry.stackTrace;
    final hasStackTrace = stackTrace != null && stackTrace.isNotEmpty;

    return GestureDetector(
      onLongPress: _copyError,
      child: Container(
        decoration: BoxDecoration(
          color: _LP.paper,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _LP.border),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: errorColor, width: 4)),
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: Material(
                type: MaterialType.transparency,
                child: ExpansionTile(
                  key: const Key('app_logs_error_expansion_tile'),
                  maintainState: true,
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  childrenPadding: const EdgeInsets.only(
                    left: 12,
                    right: 12,
                    bottom: 12,
                  ),
                  onExpansionChanged: (value) {
                    setState(() => _isExpanded = value);
                  },
                  title: _buildHeader(errorColor, time),
                  subtitle:
                      _isExpanded
                          ? null
                          : Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              widget.entry.message,
                              key: const Key('app_logs_error_message_preview'),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: _LP.textPri,
                                height: 1.4,
                              ),
                            ),
                          ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCopyButton(),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: const Icon(
                          Icons.expand_more,
                          key: Key('app_logs_error_expand_icon'),
                          size: 20,
                          color: _LP.textSec,
                        ),
                      ),
                    ],
                  ),
                  children: [
                    const Divider(height: 16, color: _LP.border),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SelectableText(
                        widget.entry.message,
                        key: const Key('app_logs_error_message_full'),
                        style: const TextStyle(
                          fontSize: 13,
                          color: _LP.textPri,
                          height: 1.45,
                        ),
                      ),
                    ),
                    if (hasStackTrace) ...[
                      const Divider(height: 24, color: _LP.border),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Stack trace',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _LP.textSec,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SelectableText(
                          stackTrace,
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.45,
                            color: _LP.textPri,
                            fontFamily: 'SF Mono',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _copyError() async {
    final stackTrace = widget.entry.stackTrace;
    final copyText =
        stackTrace != null && stackTrace.isNotEmpty
            ? '${widget.entry.message}\n\n$stackTrace'
            : widget.entry.message;
    try {
      await _copyAppLogText(copyText);
    } catch (_) {
      // 剪贴板写入失败时静默处理，不触发成功回调。
    }
  }

  Widget _buildCopyButton() {
    return Semantics(
      button: true,
      label: 'Copy error',
      child: IconButton(
        key: const Key('app_logs_error_copy_button'),
        onPressed: _copyError,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.copy_outlined, size: 17, color: _LP.textSec),
      ),
    );
  }

  Widget _buildHeader(Color errorColor, String time) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: errorColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            widget.sourceLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: errorColor,
            ),
          ),
        ),
        Text(
          time,
          style: const TextStyle(
            fontSize: 12,
            color: _LP.textSec,
            fontFamily: 'SF Mono',
          ),
        ),
      ],
    );
  }
}
