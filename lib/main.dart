import 'package:flutter/material.dart';
import 'app/app.dart';
import 'app/app_constants/app_text.dart';
import 'app/bootstrap/app_bootstrap.dart';
import 'app/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _Startup());
}

class _Startup extends StatefulWidget {
  const _Startup();
  @override
  State<_Startup> createState() => _StartupState();
}

class _StartupState extends State<_Startup> {
  late Future<AppBootstrap> _services = AppBootstrap.load();
  @override
  Widget build(BuildContext context) => FutureBuilder<AppBootstrap>(
    future: _services,
    builder: (context, snapshot) {
      if (snapshot.hasData) return TeamFlowApp(services: snapshot.data!);
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: snapshot.hasError
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(AppText.unexpectedFailure),
                      TextButton(
                        onPressed: () =>
                            setState(() => _services = AppBootstrap.load()),
                        child: const Text(AppText.retry),
                      ),
                    ],
                  )
                : const CircularProgressIndicator(),
          ),
        ),
      );
    },
  );
}
