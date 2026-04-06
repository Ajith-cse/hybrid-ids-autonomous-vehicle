class VehicleData {
  final double speed;
  final double rpm;
  final double throttle;
  final double brake;
  final double steering;
  final double lat;
  final double lon;
  final double canFreq;
  final double payloadSize;
  final String vehicleId;

  VehicleData({
    required this.speed,
    required this.rpm,
    required this.throttle,
    required this.brake,
    required this.steering,
    required this.lat,
    required this.lon,
    required this.canFreq,
    required this.payloadSize,
    this.vehicleId = 'AV-001',
  });

  factory VehicleData.fromJson(Map<String, dynamic> json) => VehicleData(
        speed:       (json['speed'] as num).toDouble(),
        rpm:         (json['rpm'] as num).toDouble(),
        throttle:    (json['throttle'] as num).toDouble(),
        brake:       (json['brake'] as num).toDouble(),
        steering:    (json['steering'] as num).toDouble(),
        lat:         (json['lat'] as num).toDouble(),
        lon:         (json['lon'] as num).toDouble(),
        canFreq:     (json['can_freq'] as num).toDouble(),
        payloadSize: (json['payload_size'] as num).toDouble(),
        vehicleId:   json['vehicle_id'] ?? 'AV-001',
      );

  Map<String, dynamic> toJson() => {
        'speed':        speed,
        'rpm':          rpm,
        'throttle':     throttle,
        'brake':        brake,
        'steering':     steering,
        'lat':          lat,
        'lon':          lon,
        'can_freq':     canFreq,
        'payload_size': payloadSize,
        'vehicle_id':   vehicleId,
      };
}
