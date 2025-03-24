import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';

import 'core/logger_config.dart';
import 'core/constants.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/new_profile_screen.dart';
import 'presentation/screens/list_profile_screen.dart';
import 'presentation/screens/profile_detail_screen.dart';
import 'presentation/screens/bluetooth_scan_screen.dart';
import 'presentation/screens/control_home_screen.dart';
import 'state/app_state.dart';
import 'state/bluetooth_provider.dart';

final Logger logger = LoggerConfig.logger;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  logger.i('Aplicación iniciada');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => BluetoothProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          textTheme: GoogleFonts.robotoTextTheme(
            Theme.of(context).textTheme,
          ),
        ),
        initialRoute: AppConstants.homeRoute,
        routes: {
          AppConstants.homeRoute: (context) => const HomeScreen(),
          AppConstants.newProfileRoute: (context) => const NewProfileScreen(),
          AppConstants.listProfilesRoute: (context) => const ListProfileScreen(),
          ProfileDetailScreen.routeName: (context) => const ProfileDetailScreen(),
          BluetoothScanScreen.routeName: (context) => const BluetoothScanScreen(),
          AppConstants.controlRoute: (context) => const ControlHomeScreen(),
        },
      ),
    );
  }
}
