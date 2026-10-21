import '../../app_constants/app_routes.dart';

/// Flutter and go_router receive platform links. This service validates paths;
/// it does not install a competing platform event listener.
class DeepLinkService {
  String? _pending;
  String? normalize(Uri uri) {
    if (uri.hasScheme && !(uri.scheme == 'teamflow' && uri.host == 'app')) {
      return null;
    }
    if (!uri.hasScheme && uri.hasAuthority) return null;
    final path = uri.path.isEmpty || uri.path == '/'
        ? AppRoutes.home
        : uri.path;
    const fixed = {
      AppRoutes.login,
      AppRoutes.verify,
      AppRoutes.home,
      AppRoutes.tasks,
      AppRoutes.assign,
      AppRoutes.employees,
      AppRoutes.reports,
      AppRoutes.profile,
      AppRoutes.users,
      AppRoutes.company,
      AppRoutes.settings,
      AppRoutes.forbidden,
      '/not-found',
    };
    if (!fixed.contains(path) &&
        !RegExp(r'^/tasks/[A-Za-z0-9_-]+(/update)?$').hasMatch(path) &&
        !RegExp(r'^/employees/[A-Za-z0-9_-]+$').hasMatch(path)) {
      return null;
    }
    final team = uri.queryParameters['team'];
    return Uri(
      path: path,
      queryParameters: team == null ? null : {'team': team},
    ).toString();
  }

  void remember(String path) {
    final normalized = normalize(Uri.parse(path));
    if (normalized != null &&
        ![
          AppRoutes.login,
          AppRoutes.verify,
          AppRoutes.forbidden,
          '/not-found',
        ].contains(Uri.parse(normalized).path)) {
      _pending = normalized;
    }
  }

  String? take() {
    final value = _pending;
    _pending = null;
    return value;
  }

  void clear() => _pending = null;
}
