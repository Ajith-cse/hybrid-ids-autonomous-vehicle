import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/vehicle_data_model.dart';
import '../models/prediction_model.dart';
import '../models/log_model.dart';
import '../services/api_service.dart';

enum AppStatus { idle, loading, success, error }

class IdsProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  VehicleData? vehicleData;
  PredictionResult? prediction;
  List<LogEntry> logs = [];

  AppStatus dashboardStatus = AppStatus.idle;
  AppStatus logsStatus      = AppStatus.idle;
  String errorMessage = '';

  Timer? _refreshTimer;
  bool _isRefreshing = false;

  void startAutoRefresh({int intervalSeconds = 4}) {
    _refreshTimer?.cancel();
    _refreshAndPredict();
    _refreshTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) => _refreshAndPredict(),
    );
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _refreshAndPredict() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    dashboardStatus = AppStatus.loading;
    notifyListeners();

    try {
      final data   = await _api.fetchSimulatedData();
      final result = await _api.predict(data);

      vehicleData     = data;
      prediction      = result;
      dashboardStatus = AppStatus.success;
      errorMessage    = '';

      logs.insert(0, LogEntry(
        vehicleId:    result.vehicleId,
        prediction:   result.prediction,
        confidence:   result.confidence,
        anomalyScore: result.anomalyScore,
        hybridLabel:  result.hybridLabel,
        timestamp:    result.timestamp,
      ));
      if (logs.length > 100) logs = logs.sublist(0, 100);
    } catch (e) {
      dashboardStatus = AppStatus.error;
      errorMessage    = e.toString();
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> fetchLogs() async {
    logsStatus = AppStatus.loading;
    notifyListeners();
    try {
      logs       = await _api.getLogs(limit: 60);
      logsStatus = AppStatus.success;
    } catch (e) {
      logsStatus   = AppStatus.error;
      errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> manualRefresh() => _refreshAndPredict();

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
