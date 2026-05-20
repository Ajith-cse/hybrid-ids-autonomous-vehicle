import 'package:dio/dio.dart';
import '../models/prediction_model.dart';
import '../models/log_model.dart';
import '../models/vehicle_data_model.dart';

class ApiService {
  // Android emulator uses 10.0.2.2 to reach your PC localhost
  // Real device: change to your PC LAN IP e.g. http://192.168.1.10:8000
  static const String baseUrl = 'http://10.35.234.253:8000';
  // static const String baseUrl = 'https://av-ids-api.onrender.com';

  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  /// Fetch simulated vehicle data from /simulate
  Future<VehicleData> fetchSimulatedData() async {
    final response = await _dio.get('/simulate');
    return VehicleData.fromJson(response.data);
  }

  /// POST /predict — send vehicle data, get ML prediction
  Future<PredictionResult> predict(VehicleData data) async {
    final response = await _dio.post('/predict', data: data.toJson());
    return PredictionResult.fromJson(response.data);
  }

  /// GET /logs — fetch detection history
  Future<List<LogEntry>> getLogs({int limit = 50}) async {
    final response = await _dio.get('/logs', queryParameters: {'limit': limit});
    return (response.data as List)
        .map((e) => LogEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /health
  Future<Map<String, dynamic>> getHealth() async {
    final response = await _dio.get('/health');
    return Map<String, dynamic>.from(response.data);
  }
}
