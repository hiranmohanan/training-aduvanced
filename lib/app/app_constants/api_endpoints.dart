abstract final class ApiEndpoints {
  static const otpRequest = '/v1/auth/otp/request';
  static const otpVerify = '/v1/auth/otp/verify';
  static const logout = '/v1/auth/logout';
  static const me = '/v1/me';
  static const dashboard = '/v1/dashboard';
  static const tasks = '/v1/tasks';
  static String task(String id) => '$tasks/$id';
  static String assignment(String id) => '$tasks/$id/assignment';
  static String updates(String id) => '$tasks/$id/updates';
  static String review(String id) => '$tasks/$id/review';
  static String activity(String id) => '$tasks/$id/activity';
  static const employees = '/v1/employees';
  static String employee(String id) => '$employees/$id';
  static const users = '/v1/users';
  static String access(String id) => '$users/$id/access';
  static const teams = '/v1/teams';
  static const workEntries = '/v1/work-entries';
  static const startWork = '$workEntries/start';
  static String stopWork(String id) => '$workEntries/$id/stop';
  static const statusReport = '/v1/reports/task-status';
  static const hoursReport = '/v1/reports/work-hours';
  static const announcements = '/v1/announcements';
  static const company = '/v1/company';
}
