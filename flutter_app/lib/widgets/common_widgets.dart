import 'package:flutter/material.dart';
import '../services/app_theme.dart';

class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color? color;

  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.accent;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 0.8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: c, size: 16),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textSec, fontSize: 11, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: TextStyle(
                      color: c,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(unit,
                    style: const TextStyle(
                        color: AppTheme.textSec, fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final bool isAttack;
  const StatusBadge({super.key, required this.isAttack});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isAttack
            ? AppTheme.danger.withAlpha(25)
            : AppTheme.safe.withAlpha(20),
        border: Border.all(
          color: isAttack ? AppTheme.danger : AppTheme.safe,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isAttack ? Icons.warning_amber_rounded : Icons.verified_user_rounded,
            color: isAttack ? AppTheme.danger : AppTheme.safe,
            size: 40,
          ),
          const SizedBox(height: 10),
          Text(
            isAttack ? '⚠  ATTACK DETECTED' : '✓  NORMAL TRAFFIC',
            style: TextStyle(
              color: isAttack ? AppTheme.danger : AppTheme.safe,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          if (isAttack)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Anomalous CAN bus activity identified',
                style: TextStyle(color: AppTheme.textSec, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class ConfidenceBar extends StatelessWidget {
  final double confidence;
  final double anomalyScore;

  const ConfidenceBar({
    super.key,
    required this.confidence,
    required this.anomalyScore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Model Confidence',
              style: TextStyle(color: AppTheme.textSec, fontSize: 12)),
          const SizedBox(height: 10),
          _bar('RandomForest', confidence / 100, AppTheme.accent),
          const SizedBox(height: 8),
          _bar('IsolationForest', anomalyScore.clamp(0.0, 1.0), AppTheme.dangerSoft),
        ],
      ),
    );
  }

  Widget _bar(String label, double value, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(color: AppTheme.textSec, fontSize: 11)),
              Text('${(value * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                      color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      );
}

class PulseDot extends StatefulWidget {
  final Color color;
  const PulseDot({super.key, required this.color});

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _anim,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        ),
      );
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
              color: AppTheme.textSec,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4),
        ),
      );
}
