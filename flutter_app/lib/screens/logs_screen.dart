import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ids_provider.dart';
import '../services/app_theme.dart';
import '../models/log_model.dart';
import '../widgets/common_widgets.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  String _filter = 'All'; // All | Normal | Attack

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IdsProvider>().fetchLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<IdsProvider>(
      builder: (context, ids, _) {
        final filtered = ids.logs.where((l) {
          if (_filter == 'All') return true;
          return l.hybridLabel == _filter;
        }).toList();

        final attackCount = ids.logs.where((l) => l.isAttack).length;
        final normalCount = ids.logs.where((l) => !l.isAttack).length;

        return Scaffold(
          backgroundColor: AppTheme.bg,
          appBar: AppBar(
            backgroundColor: AppTheme.surface,
            title: const Text('Detection Logs'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                color: AppTheme.accent,
                onPressed: ids.fetchLogs,
              ),
            ],
          ),
          body: Column(
            children: [
              // ── Summary bar ───────────────────────
              _SummaryBar(
                  total: ids.logs.length,
                  attacks: attackCount,
                  normal: normalCount),

              // ── Filter chips ──────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    const SectionHeader(title: 'Filter'),
                    const SizedBox(width: 12),
                    ..._filterOptions.map((f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChip(
                            label: f,
                            selected: _filter == f,
                            onTap: () => setState(() => _filter = f),
                          ),
                        )),
                  ],
                ),
              ),

              // ── Log list ──────────────────────────
              Expanded(
                child: ids.logsStatus == AppStatus.loading && ids.logs.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(color: AppTheme.accent))
                    : filtered.isEmpty
                        ? _EmptyState()
                        : RefreshIndicator(
                            color: AppTheme.accent,
                            backgroundColor: AppTheme.card,
                            onRefresh: ids.fetchLogs,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, i) =>
                                  _LogCard(entry: filtered[i]),
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  static const _filterOptions = ['All', 'Normal', 'Attack'];
}

// ── Sub-widgets ────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final int total, attacks, normal;
  const _SummaryBar(
      {required this.total, required this.attacks, required this.normal});

  @override
  Widget build(BuildContext context) => Container(
        color: AppTheme.surface,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            _stat(total.toString(), 'Total', AppTheme.accent),
            _divider(),
            _stat(normal.toString(), 'Normal', AppTheme.safe),
            _divider(),
            _stat(attacks.toString(), 'Attacks', AppTheme.danger),
          ],
        ),
      );

  Widget _stat(String v, String l, Color c) => Expanded(
        child: Column(
          children: [
            Text(v,
                style: TextStyle(
                    color: c, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(l,
                style: const TextStyle(color: AppTheme.textSec, fontSize: 11)),
          ],
        ),
      );

  Widget _divider() => Container(
      width: 0.8, height: 36, color: AppTheme.border,
      margin: const EdgeInsets.symmetric(horizontal: 8));
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  Color get _color {
    if (!selected) return AppTheme.border;
    if (label == 'Attack') return AppTheme.danger;
    if (label == 'Normal') return AppTheme.safe;
    return AppTheme.accent;
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? _color.withAlpha(30) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _color, width: selected ? 1.5 : 0.8),
          ),
          child: Text(label,
              style: TextStyle(
                  color: selected ? _color : AppTheme.textSec,
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal)),
        ),
      );
}

class _LogCard extends StatelessWidget {
  final LogEntry entry;
  const _LogCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isAtk  = entry.isAttack;
    final color  = isAtk ? AppTheme.danger : AppTheme.safe;
    final icon   = isAtk
        ? Icons.warning_amber_rounded
        : Icons.check_circle_rounded;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAtk ? AppTheme.danger.withAlpha(80) : AppTheme.border,
          width: isAtk ? 1 : 0.8,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Row(
          children: [
            Text(entry.vehicleId,
                style: const TextStyle(
                    color: AppTheme.textPri,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(entry.hybridLabel,
                  style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _chip('RF ${entry.confidence.toStringAsFixed(1)}%',
                      AppTheme.accent),
                  const SizedBox(width: 6),
                  _chip(
                      'Anom ${(entry.anomalyScore * 100).toStringAsFixed(1)}%',
                      AppTheme.dangerSoft),
                ],
              ),
              const SizedBox(height: 4),
              Text(entry.formattedTime,
                  style: const TextStyle(
                      color: AppTheme.textSec, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(text,
            style:
                TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500)),
      );
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded,
                color: AppTheme.textSec.withAlpha(80), size: 48),
            const SizedBox(height: 12),
            const Text('No logs yet',
                style: TextStyle(color: AppTheme.textSec, fontSize: 14)),
            const SizedBox(height: 6),
            const Text('Predictions will appear here',
                style: TextStyle(color: AppTheme.textSec, fontSize: 12)),
          ],
        ),
      );
}
