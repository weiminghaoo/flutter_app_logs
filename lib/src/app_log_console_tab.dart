// ============================================================================
// app_log_console_tab.dart — Console 标签页
// ============================================================================

part of 'app_logs.dart';

class _ConsoleTab extends StatefulWidget {
  final List<AppConsoleLogEntry> entries;

  const _ConsoleTab({required this.entries});

  @override
  State<_ConsoleTab> createState() => _ConsoleTabState();
}

class _ConsoleTabState extends State<_ConsoleTab> {
  String _searchQuery = '';
  late final TextEditingController _searchController;
  AppLogLevel? _selectedLevel;

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

  Color _levelColor(AppLogLevel level) {
    final theme = AppLogsConfig.theme;
    return switch (level) {
      AppLogLevel.debug => theme.debug,
      AppLogLevel.info => theme.info,
      AppLogLevel.warn => theme.primary,
      AppLogLevel.error => theme.error,
    };
  }

  String _levelLabel(AppLogLevel level) {
    return switch (level) {
      AppLogLevel.debug => 'DEBUG',
      AppLogLevel.info => 'INFO',
      AppLogLevel.warn => 'WARN',
      AppLogLevel.error => 'ERROR',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppLogsConfig.theme;
    final filteredEntries =
        widget.entries.where((e) {
          if (_selectedLevel != null && e.level != _selectedLevel) return false;
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            return e.message.toLowerCase().contains(query) ||
                (e.tag?.toLowerCase().contains(query) ?? false);
          }
          return true;
        }).toList();

    return Column(
      children: [
        // 搜索栏 + 过滤芯片
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
                  hintText: 'Search console logs...',
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
                      selected: _selectedLevel == null,
                      onSelected: (v) => setState(() => _selectedLevel = null),
                    ),
                    const SizedBox(width: 8),
                    ...AppLogLevel.values.map(
                      (level) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: _levelLabel(level),
                          selected: _selectedLevel == level,
                          color: _levelColor(level),
                          onSelected:
                              (v) => setState(
                                () => _selectedLevel = v ? level : null,
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

        // 日志列表
        Expanded(
          child:
              filteredEntries.isEmpty
                  ? const Center(
                    child: Text(
                      'No logs found',
                      style: TextStyle(color: _LP.textSec),
                    ),
                  )
                  : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                    itemCount: filteredEntries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final e = filteredEntries[index];
                      final hasExtra = e.extra != null && e.extra!.isNotEmpty;
                      final time =
                          '${e.at.hour.toString().padLeft(2, '0')}:${e.at.minute.toString().padLeft(2, '0')}:${e.at.second.toString().padLeft(2, '0')}';

                      return GestureDetector(
                        onLongPress: () async {
                          final baseText =
                              e.tag != null && e.tag!.isNotEmpty
                                  ? '[${e.tag}] ${e.message}'
                                  : e.message;
                          final copyText =
                              hasExtra
                                  ? '$baseText\n\nextra:\n${_prettyJson(e.extra)}'
                                  : baseText;
                          try {
                            await _copyAppLogText(copyText);
                          } catch (_) {
                            // 剪贴板写入失败时静默处理，不触发成功回调
                          }
                        },
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
                                border: Border(
                                  left: BorderSide(
                                    color: _levelColor(e.level),
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: Theme(
                                data: Theme.of(
                                  context,
                                ).copyWith(dividerColor: Colors.transparent),
                                child:
                                    hasExtra
                                        ? ExpansionTile(
                                          tilePadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 4,
                                              ),
                                          childrenPadding:
                                              const EdgeInsets.only(
                                                left: 12,
                                                right: 12,
                                                bottom: 12,
                                              ),
                                          title: _buildLogHeader(e, time),
                                          subtitle: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 6,
                                            ),
                                            child: Text(
                                              e.message,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: _LP.textPri,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                          trailing: const Icon(
                                            Icons.expand_more,
                                            size: 20,
                                            color: _LP.textSec,
                                          ),
                                          children: [
                                            const Divider(
                                              height: 16,
                                              color: _LP.border,
                                            ),
                                            _JsonBlock(value: e.extra),
                                          ],
                                        )
                                        : Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _buildLogHeader(e, time),
                                              const SizedBox(height: 6),
                                              Text(
                                                e.message,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: _LP.textPri,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  /// 构建日志条目的头部信息行（级别 Badge + 时间 + Tag）
  Widget _buildLogHeader(AppConsoleLogEntry e, String time) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _levelColor(e.level).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _levelLabel(e.level),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _levelColor(e.level),
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
        if (e.tag != null && e.tag!.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxWidth: 180),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _LP.badgeBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              e.tag!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: _LP.badgeText),
            ),
          ),
      ],
    );
  }
}
