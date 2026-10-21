import 'package:go_router/go_router.dart';
import '../../app_constants/app_routes.dart';

class NavigationService {
  NavigationService(this.router);
  final GoRouter router;
  void go(String path) => router.go(path);
  void push(String path) => router.push<void>(path);
  void back() {
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(AppRoutes.home);
    }
  }

  void openTask(String id) => push(AppRoutes.task(id));
  void openEmployee(String id) => push(AppRoutes.employee(id));
  void openAssignment() => push(AppRoutes.assign);
}
