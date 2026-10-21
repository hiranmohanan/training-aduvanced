import '../../app_constants/api_endpoints.dart';
import '../../models/app_user.dart';
import '../../services/api/api_provider_service.dart';
import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this.api, this.demoAccounts);
  final ApiProviderService api;
  @override
  final List<DemoAccount> demoAccounts;
  @override
  Future<OtpChallenge> requestCode(String phone) async {
    final j =
        (await api.request(
              'POST',
              ApiEndpoints.otpRequest,
              body: {'phoneE164': phone},
            ))['data']
            as Json;
    return OtpChallenge(
      j['challengeId'] as String,
      j['phone'] as String,
      DateTime.parse(j['issuedAt'] as String),
    );
  }

  @override
  Future<AppUser> verify(OtpChallenge challenge, String code) async {
    final j =
        (await api.request(
              'POST',
              ApiEndpoints.otpVerify,
              body: {'challengeId': challenge.id, 'code': code},
            ))['data']
            as Json;
    return AppUser.fromJson(j['user'] as Json);
  }

  @override
  Future<void> logout() async {
    await api.request('POST', ApiEndpoints.logout);
  }
}
