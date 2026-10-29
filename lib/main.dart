import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/reports_provider.dart';
import 'services/network_service.dart';
import 'services/offline_queue_service.dart';
import 'theme/app_theme.dart';
import 'views/root_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize network listener
  NetworkService.instance.init();

  runApp(const SmartLineApp());
}

class SmartLineApp extends StatelessWidget {
  const SmartLineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final reportsProvider = ReportsProvider();
            OfflineQueueService.instance.init(reportsProvider);
            return reportsProvider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'SmartLine',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const RootView(),
      ),
    );
  }
}
