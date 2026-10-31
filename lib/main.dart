import 'package:flutter/material.dart';
import 'package:bus_driver/api/api.dart';
import 'package:bus_driver/auth/presentation/screen/login_screen.dart';
import 'package:bus_driver/conductor/presentation/screens/main_nav/conductor_main_navigation_screen.dart';
import 'package:bus_driver/driver/core/theme/driver_theme.dart';
import 'package:bus_driver/driver/data/repository/driver_repository.dart';
import 'package:bus_driver/driver/presentation/screens/main_nav/driver_main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if session exists and restore profile
  final bool isLoggedIn = await AuthStorage.isLoggedIn();
  String? role;
  if (isLoggedIn) {
    await DriverRepository().restoreSavedSession();
    role = await AuthStorage.getRole();
    if (role != null) {
      DriverRepository().setActiveRole(role);
    }
  }

  runApp(MyApp(isLoggedIn: isLoggedIn, role: role));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? role;

  const MyApp({super.key, this.isLoggedIn = false, this.role});

  @override
  Widget build(BuildContext context) {
    final isConductorRole = role == 'conductor' || DriverRepository().isConductor;

    return MaterialApp(
      title: 'SPINGO Crew Portal',
      debugShowCheckedModeBanner: false,
      theme: DriverTheme.lightTheme,
      home: isLoggedIn
          ? (isConductorRole ? const ConductorMainNavigationScreen() : const DriverMainNavigationScreen())
          : const LoginScreen(),
    );
  }
}
