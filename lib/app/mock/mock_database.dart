import 'dart:convert';
import '../services/api/api_provider_service.dart';

/// One database per app process; account switching never reseeds it.
class MockDatabase {
  MockDatabase(Json seed) : _seed = jsonEncode(seed) {
    reset();
  }
  final String _seed;
  late Json data;
  int _sequence = 100;
  void reset() {
    data = jsonDecode(_seed) as Json;
    _sequence = 100;
  }

  List<Json> records(String name) => (data[name] as List).cast<Json>();
  String newId(String prefix) => '$prefix${++_sequence}';
}
