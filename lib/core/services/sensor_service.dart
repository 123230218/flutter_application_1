import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  Stream<AccelerometerEvent> accelerometerStream() => accelerometerEventStream();
  Stream<GyroscopeEvent> gyroscopeStream() => gyroscopeEventStream();
}
