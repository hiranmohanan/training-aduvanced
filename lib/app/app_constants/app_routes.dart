abstract final class AppRoutes {
  static const login = '/login';
  static const verify = '/verify';
  static const home = '/home';
  static const tasks = '/tasks';
  static const assign = '/tasks/new';
  static const employees = '/employees';
  static const reports = '/reports';
  static const profile = '/profile';
  static const users = '/admin/users';
  static const company = '/company';
  static const settings = '/settings';
  static const forbidden = '/forbidden';
  static String task(String id) => '$tasks/${Uri.encodeComponent(id)}';
  static String update(String id) => '${task(id)}/update';
  static String employee(String id) => '$employees/${Uri.encodeComponent(id)}';
}
