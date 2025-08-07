import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'providers/detection_provider.dart';
import 'providers/camera_provider.dart';
import 'providers/logs_provider.dart';
import 'services/database_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Request permissions
  await _requestPermissions();
  
  // Initialize database
  await DatabaseService.instance.database;
  
  runApp(const MyApp());
}

Future<void> _requestPermissions() async {
  // Skip permission requests on web or request only supported permissions
  if (kIsWeb) {
    // Web doesn't support the same permissions as mobile
    // You can request web-specific permissions here if needed
    print('Running on web - skipping unsupported permissions');
    return;
  }
  
  // Request permissions only on mobile platforms
  await [
    Permission.camera,
    Permission.microphone,
    Permission.storage,
  ].request();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CameraProvider()),
        ChangeNotifierProvider(create: (_) => DetectionProvider()),
        ChangeNotifierProvider(create: (_) => LogsProvider()),
      ],
      child: MaterialApp(
        title: 'Driver Safety Monitor',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}