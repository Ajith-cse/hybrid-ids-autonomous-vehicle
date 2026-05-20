import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ids_provider.dart';
import '../services/app_theme.dart';
import '../widgets/common_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IdsProvider>().startAutoRefresh(intervalSeconds: 4);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<IdsProvider>(
      builder: (context, ids, _) {
        final data   = ids.vehicleData;
        final pred   = ids.prediction;
        final isAtk  = pred?.isAttack ?? false;
        final status = ids.dashboardStatus;

        return Scaffold(
          backgroundColor: AppTheme.bg,
          body: RefreshIndicator(
            color: AppTheme.accent,
            backgroundColor: AppTheme.card,
            onRefresh: ids.manualRefresh,
            child: CustomScrollView(
              slivers: [
                // ── App Bar ───────────────────────────
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 100,
                  backgroundColor: AppTheme.surface,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PulseDot(
                            color: status == AppStatus.loading
                                ? AppTheme.accent
                                : isAtk
                                    ? AppTheme.danger
                                    : AppTheme.safe),
                        const SizedBox(width: 8),
                        const Text('Live Monitor',
                            style: TextStyle(
                                color: AppTheme.textPri,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      color: AppTheme.accent,
                      onPressed: ids.manualRefresh,
                    ),
                    const SizedBox(width: 4),
                  ],
                ),

                // ── Body ──────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Vehicle info row
                      _VehicleHeader(
                          vehicleId: data?.vehicleId ?? 'AV-001',
                          status: status),
                      const SizedBox(height: 16),

                      // Status badge
                      if (pred != null) ...[
                        StatusBadge(isAttack: isAtk),
                        const SizedBox(height: 16),
                      ],

                      // Attack alert banner
                      if (isAtk) ...[
                        _AlertBanner(),
                        const SizedBox(height: 16),
                      ],

                      // Metrics grid
                      const SectionHeader(title: 'Vehicle Telemetry'),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.4,
                        children: [
                          MetricTile(
                            label: 'SPEED',
                            value: data?.speed.toStringAsFixed(1) ?? '--',
                            unit: 'km/h',
                            icon: Icons.speed_rounded,
                            color: AppTheme.accent,
                          ),
                          MetricTile(
                            label: 'ENGINE RPM',
                            value: data?.rpm.toStringAsFixed(0) ?? '--',
                            unit: 'rpm',
                            icon: Icons.settings_rounded,
                            color: AppTheme.accentSoft,
                          ),
                          MetricTile(
                            label: 'THROTTLE',
                            value: data?.throttle.toStringAsFixed(1) ?? '--',
                            unit: '%',
                            icon: Icons.flash_on_rounded,
                            color: Colors.orangeAccent,
                          ),
                          MetricTile(
                            label: 'BRAKE',
                            value: data?.brake.toStringAsFixed(1) ?? '--',
                            unit: '%',
                            icon: Icons.pause_circle_rounded,
                            color: Colors.redAccent,
                          ),
                          MetricTile(
                            label: 'STEERING',
                            value: data?.steering.toStringAsFixed(1) ?? '--',
                            unit: '°',
                            icon: Icons.rotate_left_rounded,
                            color: Colors.purpleAccent,
                          ),
                          MetricTile(
                            label: 'CAN FREQ',
                            value: data?.canFreq.toStringAsFixed(0) ?? '--',
                            unit: 'msg/s',
                            icon: Icons.cable_rounded,
                            color: isAtk ? AppTheme.danger : AppTheme.accent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // GPS
                      const SectionHeader(title: 'GPS Position'),
                      _GpsTile(
                        lat: data?.lat,
                        lon: data?.lon,
                      ),
                      const SizedBox(height: 16),

                      // ML confidence
                      const SectionHeader(title: 'ML Model Output'),
                      if (pred != null)
                        ConfidenceBar(
                          confidence:   pred.confidence,
                          anomalyScore: pred.anomalyScore,
                        ),
                      const SizedBox(height: 80),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Sub-widgets ────────────────────────────────

class _VehicleHeader extends StatelessWidget {
  final String vehicleId;
  final AppStatus status;

  const _VehicleHeader({required this.vehicleId, required this.status});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accent.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.directions_car_filled_rounded,
                color: AppTheme.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(vehicleId,
                  style: const TextStyle(
                      color: AppTheme.textPri,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              Text(
                status == AppStatus.loading ? 'Fetching data...' : 'Live telemetry',
                style: const TextStyle(color: AppTheme.textSec, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          if (status == AppStatus.loading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.accent,
              ),
            ),
        ],
      );
}

class _AlertBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.danger.withAlpha(30),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.danger, width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppTheme.danger, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Security Alert',
                      style: TextStyle(
                          color: AppTheme.danger,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  const SizedBox(height: 2),
                  Text('Possible CAN bus intrusion detected. Manual review required.',
                      style: TextStyle(
                          color: AppTheme.danger.withAlpha(200), fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _GpsTile extends StatelessWidget {
  final double? lat;
  final double? lon;

  const _GpsTile({this.lat, this.lon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border, width: 0.8),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_rounded,
                color: AppTheme.accent, size: 28),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${lat?.toStringAsFixed(5) ?? '--'}° N',
                    style: const TextStyle(
                        color: AppTheme.textPri, fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${lon?.toStringAsFixed(5) ?? '--'}° E',
                    style: const TextStyle(
                        color: AppTheme.textSec, fontSize: 13)),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentSoft.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('GPS OK',
                  style: TextStyle(
                      color: AppTheme.accentSoft,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}






//sample


  
  