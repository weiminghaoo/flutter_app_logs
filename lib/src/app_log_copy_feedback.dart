// ============================================================================
// app_log_copy_feedback.dart — 复制辅助与面板内提示层
// ============================================================================

part of 'app_logs.dart';

class _CopyFeedbackState {
  const _CopyFeedbackState({required this.message, required this.token});

  final String message;
  final int token;
}

class _CopyFeedbackController {
  _CopyFeedbackController._();

  static final ValueNotifier<_CopyFeedbackState?> notifier =
      ValueNotifier<_CopyFeedbackState?>(null);

  static Timer? _timer;
  static int _tokenSeed = 0;

  static void show({String message = 'Copied'}) {
    final token = ++_tokenSeed;
    notifier.value = _CopyFeedbackState(message: message, token: token);

    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (notifier.value?.token != token) return;
      notifier.value = null;
    });
  }
}

/// 统一处理日志面板内所有复制动作。
///
/// 这样复制行为只维护一份：
/// - 写入 Flutter / iOS 剪贴板；
/// - 输出到 Xcode/IDE console，方便 Simulator 无法同步到 macOS 剪贴板时手动复制；
/// - 保留原有的接入方成功回调；
/// - 触发面板内部提示层，避免被 App 外层 Overlay 遮挡。
Future<void> _copyAppLogText(String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  _debugPrintCopiedText(text);
  AppLogsConfig.onCopySuccess?.call(text);
  _CopyFeedbackController.show();
}

void _debugPrintCopiedText(String text) {
  _AppErrorCapture.instance.withoutDebugPrintCapture(() {
    const chunkSize = 800;
    debugPrint('📋 [flutter_app_logs copied text] length=${text.length}');

    if (text.isEmpty) {
      debugPrint('<empty>');
      return;
    }

    for (var start = 0; start < text.length; start += chunkSize) {
      final end = math.min(start + chunkSize, text.length);
      debugPrint(text.substring(start, end));
    }

    debugPrint('📋 [flutter_app_logs copied text end]');
  });
}

class _CopyFeedbackToast extends StatelessWidget {
  const _CopyFeedbackToast();

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return IgnorePointer(
      child: ValueListenableBuilder<_CopyFeedbackState?>(
        valueListenable: _CopyFeedbackController.notifier,
        builder: (context, state, _) {
          final visible = state != null;

          return AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: const Duration(milliseconds: 160),
            child: AnimatedScale(
              scale: visible ? 1 : 0.96,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 32 + bottomSafe),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      child: Text(
                        state?.message ?? 'Copied',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
