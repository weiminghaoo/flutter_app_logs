// ============================================================================
// app_log_widgets.dart — 通用小组件库
// ============================================================================

part of 'app_logs.dart';

// ============================================================================
// _FilterChip — 过滤标签按钮
// ============================================================================

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Color? color;

  const _FilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppLogsConfig.theme.primary;
    return InkWell(
      onTap: () => onSelected(!selected),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? activeColor.withValues(alpha: 0.1) : _LP.paper,
          border: Border.all(color: selected ? activeColor : _LP.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? activeColor : _LP.textSec,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// _JsonBlock — 可折叠 JSON 树展示组件
// ============================================================================

class _JsonBlock extends StatefulWidget {
  final Object? value;

  const _JsonBlock({required this.value});

  @override
  State<_JsonBlock> createState() => _JsonBlockState();
}

class _JsonBlockState extends State<_JsonBlock> {
  final Set<String> _collapsed = {};
  final Map<String, int> _visibleChildren = {};

  static const int _initialVisibleChildren = 24;
  static const int _visibleChildrenStep = 24;

  static const _monoBase = TextStyle(
    fontSize: 13,
    height: 1.6,
    fontWeight: FontWeight.w500,
    fontFamily: 'SF Mono',
    color: _JC.base,
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.hasBoundedHeight;
        final panelHeight = hasBoundedHeight ? constraints.maxHeight : 260.0;
        final bottomPad =
            hasBoundedHeight
                ? MediaQuery.of(context).padding.bottom + 32
                : 24.0;

        return SizedBox(
          width: double.infinity,
          height: panelHeight,
          child: Container(
            decoration: const BoxDecoration(
              color: _JC.bg,
              border: Border(top: BorderSide(color: _JC.border)),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      top: 44,
                      bottom: bottomPad,
                      left: 12,
                      right: 16,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildNode(widget.value, '#', 0),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 12,
                  child: Material(
                    color: _JC.border,
                    borderRadius: BorderRadius.circular(6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () async {
                        try {
                          await _copyAppLogText(
                            await _prettyJsonAsync(widget.value),
                          );
                        } catch (_) {
                          // 剪贴板写入失败时静默处理，不触发成功回调
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.copy_outlined,
                          size: 14,
                          color: _JC.label,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNode(
    Object? value,
    String path,
    int depth, {
    String? keyName,
    bool comma = false,
  }) {
    if (value is Map) {
      return _buildMap(value, path, depth, keyName: keyName, comma: comma);
    }
    if (value is List) {
      return _buildListNode(value, path, depth, keyName: keyName, comma: comma);
    }
    return _leaf(value, depth, keyName: keyName, comma: comma);
  }

  int _visibleCountFor(String path, int total) {
    if (total <= _initialVisibleChildren) {
      return total;
    }
    final current = _visibleChildren[path] ?? _initialVisibleChildren;
    return current.clamp(_initialVisibleChildren, total);
  }

  void _showMoreChildren(String path, int total) {
    setState(() {
      _visibleChildren[path] =
          (_visibleChildren[path] ?? _initialVisibleChildren) +
          _visibleChildrenStep;
    });
  }

  // 全部展开时按批次推进，让每一帧只多渲染一批新行，
  // 避免几千项的数组一次性塞进同一帧导致卡顿。
  Future<void> _expandAll(String path, int total) async {
    while (mounted) {
      final current = _visibleChildren[path] ?? _initialVisibleChildren;
      if (current >= total) break;
      setState(() {
        _visibleChildren[path] = math.min(
          current + _visibleChildrenStep,
          total,
        );
      });
      await SchedulerBinding.instance.endOfFrame;
    }
  }

  Widget _buildMap(
    Map<dynamic, dynamic> map,
    String path,
    int depth, {
    String? keyName,
    bool comma = false,
  }) {
    final collapsed = _collapsed.contains(path);
    final header = _keySpans(keyName);

    if (map.isEmpty) {
      return _line(depth, [
        ...header,
        const TextSpan(text: '{}', style: TextStyle(color: _JC.punct)),
        if (comma)
          const TextSpan(text: ',', style: TextStyle(color: _JC.punct)),
      ]);
    }

    if (collapsed) {
      return _toggleableLine(
        depth: depth,
        path: path,
        collapsed: true,
        spans: [
          ...header,
          const TextSpan(text: '{ ', style: TextStyle(color: _JC.punct)),
          TextSpan(
            text: '…${map.length} keys',
            style: const TextStyle(
              color: _JC.label,
              fontStyle: FontStyle.italic,
            ),
          ),
          const TextSpan(text: ' }', style: TextStyle(color: _JC.punct)),
          if (comma)
            const TextSpan(text: ',', style: TextStyle(color: _JC.punct)),
        ],
      );
    }

    final entries = map.entries.toList();
    final visibleCount = _visibleCountFor(path, entries.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _toggleableLine(
          depth: depth,
          path: path,
          collapsed: false,
          spans: [
            ...header,
            const TextSpan(text: '{', style: TextStyle(color: _JC.punct)),
          ],
        ),
        for (int i = 0; i < visibleCount; i++)
          _buildNode(
            entries[i].value,
            '$path.${entries[i].key}',
            depth + 1,
            keyName: entries[i].key.toString(),
            comma: i < entries.length - 1,
          ),
        if (visibleCount < entries.length)
          _buildLoadMoreLine(
            path: path,
            depth: depth + 1,
            shownCount: visibleCount,
            totalCount: entries.length,
          ),
        _line(depth, [
          const TextSpan(text: '}', style: TextStyle(color: _JC.punct)),
          if (comma)
            const TextSpan(text: ',', style: TextStyle(color: _JC.punct)),
        ]),
      ],
    );
  }

  Widget _buildListNode(
    List<dynamic> list,
    String path,
    int depth, {
    String? keyName,
    bool comma = false,
  }) {
    final collapsed = _collapsed.contains(path);
    final header = _keySpans(keyName);

    if (list.isEmpty) {
      return _line(depth, [
        ...header,
        const TextSpan(text: '[]', style: TextStyle(color: _JC.punct)),
        if (comma)
          const TextSpan(text: ',', style: TextStyle(color: _JC.punct)),
      ]);
    }

    if (collapsed) {
      return _toggleableLine(
        depth: depth,
        path: path,
        collapsed: true,
        spans: [
          ...header,
          const TextSpan(text: '[ ', style: TextStyle(color: _JC.punct)),
          TextSpan(
            text: '…${list.length} items',
            style: const TextStyle(
              color: _JC.label,
              fontStyle: FontStyle.italic,
            ),
          ),
          const TextSpan(text: ' ]', style: TextStyle(color: _JC.punct)),
          if (comma)
            const TextSpan(text: ',', style: TextStyle(color: _JC.punct)),
        ],
      );
    }

    final visibleCount = _visibleCountFor(path, list.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _toggleableLine(
          depth: depth,
          path: path,
          collapsed: false,
          spans: [
            ...header,
            const TextSpan(text: '[', style: TextStyle(color: _JC.punct)),
          ],
        ),
        for (int i = 0; i < visibleCount; i++)
          _buildNode(
            list[i],
            '$path[$i]',
            depth + 1,
            comma: i < list.length - 1,
          ),
        if (visibleCount < list.length)
          _buildLoadMoreLine(
            path: path,
            depth: depth + 1,
            shownCount: visibleCount,
            totalCount: list.length,
          ),
        _line(depth, [
          const TextSpan(text: ']', style: TextStyle(color: _JC.punct)),
          if (comma)
            const TextSpan(text: ',', style: TextStyle(color: _JC.punct)),
        ]),
      ],
    );
  }

  Widget _leaf(
    Object? value,
    int depth, {
    String? keyName,
    bool comma = false,
  }) {
    final TextSpan valueSpan;
    if (value == null) {
      valueSpan = const TextSpan(
        text: 'null',
        style: TextStyle(color: _JC.bool_),
      );
    } else if (value is bool) {
      valueSpan = TextSpan(
        text: value.toString(),
        style: const TextStyle(color: _JC.bool_),
      );
    } else if (value is num) {
      valueSpan = TextSpan(
        text: value.toString(),
        style: const TextStyle(color: _JC.number),
      );
    } else {
      final escaped = value
          .toString()
          .replaceAll(r'\', r'\\')
          .replaceAll('"', r'\"');
      valueSpan = TextSpan(
        text: '"$escaped"',
        style: const TextStyle(color: _JC.string_),
      );
    }
    return _line(depth, [
      ..._keySpans(keyName),
      valueSpan,
      if (comma) const TextSpan(text: ',', style: TextStyle(color: _JC.punct)),
    ]);
  }

  Widget _line(int depth, List<TextSpan> spans) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: depth * 16.0),
          const SizedBox(width: 16),
          Text.rich(TextSpan(children: spans), style: _monoBase),
        ],
      ),
    );
  }

  Widget _buildLoadMoreLine({
    required String path,
    required int depth,
    required int shownCount,
    required int totalCount,
  }) {
    final remainingCount = totalCount - shownCount;
    final nextCount = math.min(remainingCount, _visibleChildrenStep);
    // 剩余项数不超过一个步长时，"显示下一批" 和 "全部展开" 结果完全一样，
    // 只保留一个按钮，避免两个按钮做同一件事。
    final showSingleButton = remainingCount <= _visibleChildrenStep;

    final outlinedStyle = OutlinedButton.styleFrom(
      visualDensity: VisualDensity.compact,
      minimumSize: const Size(0, 28),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      side: const BorderSide(color: _JC.border),
      foregroundColor: _JC.label,
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    );
    final textStyle = TextButton.styleFrom(
      visualDensity: VisualDensity.compact,
      minimumSize: const Size(0, 28),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      foregroundColor: _JC.label,
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: depth * 16.0),
          const SizedBox(width: 16),
          if (showSingleButton)
            OutlinedButton(
              onPressed: () => _expandAll(path, totalCount),
              style: outlinedStyle,
              child: Text('展开剩余 $remainingCount 项'),
            )
          else ...[
            OutlinedButton(
              onPressed: () => _showMoreChildren(path, totalCount),
              style: outlinedStyle,
              child: Text('显示后 $nextCount 项（共 $totalCount 项）'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => _expandAll(path, totalCount),
              style: textStyle,
              child: Text('全部展开（剩余 $remainingCount 项）'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _toggleableLine({
    required int depth,
    required String path,
    required bool collapsed,
    required List<TextSpan> spans,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap:
          () => setState(() {
            if (collapsed) {
              _collapsed.remove(path);
            } else {
              _collapsed.add(path);
            }
          }),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: depth * 16.0),
            SizedBox(
              width: 16,
              child: Icon(
                collapsed ? Icons.chevron_right : Icons.expand_more,
                size: 14,
                color: _JC.label,
              ),
            ),
            Text.rich(TextSpan(children: spans), style: _monoBase),
          ],
        ),
      ),
    );
  }

  static List<TextSpan> _keySpans(String? key) {
    if (key == null) return const [];
    return [
      TextSpan(
        text: '"$key"',
        style: const TextStyle(color: _JC.key, fontWeight: FontWeight.w700),
      ),
      const TextSpan(text: ': ', style: TextStyle(color: _JC.punct)),
    ];
  }
}

// ============================================================================
// 工具函数
// ============================================================================

String _prettyJson(Object? value) {
  if (value == null) return '';
  try {
    return const JsonEncoder.withIndent('  ').convert(value);
  } catch (_) {
    return value.toString();
  }
}

Future<String> _prettyJsonAsync(Object? value) async {
  if (value == null) {
    return '';
  }

  try {
    return await compute(_prettyJsonInBackground, value);
  } catch (_) {
    return _prettyJson(value);
  }
}

String _prettyJsonInBackground(Object? value) => _prettyJson(value);
