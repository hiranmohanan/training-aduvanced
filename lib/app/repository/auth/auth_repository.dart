import '../../models/app_user.dart';
import '../../models/enums.dart';

class DemoAccount {
  const DemoAccount(this.name, this.phone, this.role);
  final String name, phone;
  final UserRole role;
}

class OtpChallenge {
  const OtpChallenge(this.id, this.phone, this.issuedAt);
  final String id, phone;
  final DateTime issuedAt;
}

abstract class AuthRepository {
  List<DemoAccount> get demoAccounts;
  Future<OtpChallenge> requestCode(String phone);
  Future<AppUser> verify(OtpChallenge challenge, String code);
  Future<void> logout();
}
