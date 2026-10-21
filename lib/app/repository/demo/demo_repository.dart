import '../../services/api/mock_api_provider.dart';

abstract class DemoRepository {
  bool get offline;
  void setOffline(bool value);
  void reset();
}

class DemoRepositoryImpl implements DemoRepository {
  DemoRepositoryImpl(this.provider);
  final MockApiProvider provider;
  @override
  bool get offline => provider.offline;
  @override
  void setOffline(bool value) => provider.setOffline(value);
  @override
  void reset() => provider.reset();
}
