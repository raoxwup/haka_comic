import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/widgets/button.dart';
import 'package:haka_comic/widgets/error_page.dart';
import 'package:haka_comic/widgets/toast.dart';

class Logs extends StatefulWidget {
  const Logs({super.key});

  @override
  State<Logs> createState() => _LogsState();
}

class _LogsState extends State<Logs> with RequestMixin {
  late final _handler = Log.getLogs.useRequest(
    onSuccess: (data) {
      Log.i('Successfully fetched logs', '${data.length} logs');
    },
    onError: (error) {
      Log.e('Failed to fetch logs', error: error);
    },
  );

  late final _clearHandler = Log.clearLogs.useRequest(
    manual: true,
    onSuccess: (data) {
      Log.i('Successfully cleared logs', 'clear logs');
      _handler.mutate([]);
    },
    onError: (error) {
      Log.e('Failed to clear logs', error: error);
      Toast.show(message: '清理日志失败');
    },
  );

  ({Color textColor, Color bgColor, IconData icon}) _levelStyle(
    BuildContext context,
    String level,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return switch (level.toLowerCase()) {
      'error' || 'fatal' => (
        textColor: scheme.error,
        bgColor: scheme.errorContainer.withValues(alpha: 0.4),
        icon: Icons.error_rounded,
      ),
      'warning' || 'warn' => (
        textColor: isDark ? const Color(0xFFFFCB75) : const Color(0xFF8B5200),
        bgColor: isDark ? const Color(0xFF4A340B) : const Color(0xFFFFEBC9),
        icon: Icons.warning_amber_rounded,
      ),
      'info' => (
        textColor: isDark ? const Color(0xFF8AC7FF) : const Color(0xFF0A6FD0),
        bgColor: isDark ? const Color(0xFF133B5D) : const Color(0xFFDCEEFF),
        icon: Icons.info_rounded,
      ),
      'debug' || 'trace' => (
        textColor: scheme.tertiary,
        bgColor: scheme.tertiaryContainer.withValues(alpha: 0.45),
        icon: Icons.code_rounded,
      ),
      _ => (
        textColor: scheme.primary,
        bgColor: scheme.primaryContainer.withValues(alpha: 0.45),
        icon: Icons.circle,
      ),
    };
  }

  String _levelLabel(String level) {
    return switch (level.toLowerCase()) {
      'warning' => 'WARN',
      _ => level.toUpperCase(),
    };
  }

  Future<void> _copyLog(HaKaLog log) async {
    await Clipboard.setData(ClipboardData(text: log.toString()));
    if (!mounted) return;
    Toast.show(message: '已复制');
  }

  Widget _buildBody() {
    return switch (_handler.state) {
      Success(:final data) => _buildSuccessState(data),
      Error(:final error) => ErrorPage(
        errorMessage: error.toString(),
        onRetry: _handler.refresh,
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  Widget _buildSuccessState(List<HaKaLog> data) {
    if (data.isEmpty) {
      return const Center(child: Text('暂无日志'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      itemCount: data.length,
      reverse: true,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final log = data[data.length - 1 - index];
        return _buildLogItem(log);
      },
    );
  }

  Widget _buildLogItem(HaKaLog log) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final levelStyle = _levelStyle(context, log.level);
    final hasError = log.error?.trim().isNotEmpty ?? false;
    final hasStackTrace = log.stackTrace?.trim().isNotEmpty ?? false;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: levelStyle.textColor, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLogHeader(log, levelStyle, theme, scheme),
            const SizedBox(height: 10),
            SelectableText(
              log.message,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            if (hasError) ...[
              const SizedBox(height: 10),
              _LogDetailBlock(
                title: 'Error',
                text: log.error!,
                backgroundColor: scheme.errorContainer.withValues(alpha: 0.28),
                titleColor: scheme.error,
                textColor: scheme.onErrorContainer,
              ),
            ],
            if (hasStackTrace) ...[
              const SizedBox(height: 10),
              _LogDetailBlock(
                title: 'Stack Trace',
                text: log.stackTrace!,
                backgroundColor: scheme.surfaceContainerHighest,
                titleColor: scheme.onSurfaceVariant,
                textColor: scheme.onSurface,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogHeader(
    HaKaLog log,
    ({Color textColor, Color bgColor, IconData icon}) levelStyle,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    return Row(
      spacing: 8,
      children: [
        _buildLevelBadge(log, levelStyle, theme),
        Expanded(
          child: Text(
            log.time,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        IconButton(
          onPressed: () => _copyLog(log),
          tooltip: '复制日志',
          icon: Icon(
            Icons.copy_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildLevelBadge(
    HaKaLog log,
    ({Color textColor, Color bgColor, IconData icon}) levelStyle,
    ThemeData theme,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: levelStyle.bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Icon(levelStyle.icon, size: 14, color: levelStyle.textColor),
            Text(
              _levelLabel(log.level),
              style: theme.textTheme.labelMedium?.copyWith(
                color: levelStyle.textColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日志'),
        actions: [
          Button.text(
            isLoading: _clearHandler.state.loading,
            onPressed: _clearHandler.run,
            child: const Text('清空'),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  @override
  List<RequestHandler> registerHandler() => [_handler, _clearHandler];
}

class _LogDetailBlock extends StatelessWidget {
  const _LogDetailBlock({
    required this.title,
    required this.text,
    required this.backgroundColor,
    required this.titleColor,
    required this.textColor,
  });

  final String title;
  final String text;
  final Color backgroundColor;
  final Color titleColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          SelectableText(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
