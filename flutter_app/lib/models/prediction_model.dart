class PredictionResult {
  final String vehicleId;
  final String prediction;
  final double confidence;
  final double anomalyScore;
  final String hybridLabel;
  final String timestamp;
  final Map<String, dynamic> features;

  PredictionResult({
    required this.vehicleId,
    required this.prediction,
    required this.confidence,
    required this.anomalyScore,
    required this.hybridLabel,
    required this.timestamp,
    required this.features,
  });

  bool get isAttack => hybridLabel == 'Attack';

  factory PredictionResult.fromJson(Map<String, dynamic> json) => PredictionResult(
        vehicleId:    json['vehicle_id'] ?? '',
        prediction:   json['prediction'] ?? '',
        confidence:   (json['confidence'] as num?)?.toDouble() ?? 0.0,
        anomalyScore: (json['anomaly_score'] as num?)?.toDouble() ?? 0.0,
        hybridLabel:  json['hybrid_label'] ?? json['prediction'] ?? '',
        timestamp:    json['timestamp'] ?? '',
        features:     Map<String, dynamic>.from(json['features'] ?? {}),
      );
}
