import 'package:intl/intl.dart';

class LogEntry {
  final String? id;
  final String vehicleId;
  final String prediction;
  final double confidence;
  final double anomalyScore;
  final String hybridLabel;
  final String timestamp;

  LogEntry({
    this.id,
    required this.vehicleId,
    required this.prediction,
    required this.confidence,
    required this.anomalyScore,
    required this.hybridLabel,
    required this.timestamp,
  });

  bool get isAttack => hybridLabel == 'Attack';

  String get formattedTime {
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      return DateFormat('MMM d, HH:mm:ss').format(dt);
    } catch (_) {
      return timestamp;
    }
  }

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
        id:           json['id']?.toString(),
        vehicleId:    json['vehicle_id'] ?? '',
        prediction:   json['prediction'] ?? '',
        confidence:   (json['confidence'] as num?)?.toDouble() ?? 0.0,
        anomalyScore: (json['anomaly_score'] as num?)?.toDouble() ?? 0.0,
        hybridLabel:  json['hybrid_label'] ?? json['prediction'] ?? '',
        timestamp:    json['timestamp'] ?? '',
      );
}
