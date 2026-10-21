typedef Json = Map<String, dynamic>;

abstract class ApiProviderService {
  Stream<void> get changes;
  Future<Json> request(
    String method,
    String path, {
    Json body = const {},
    Json query = const {},
  });
  Future<void> dispose();
}
