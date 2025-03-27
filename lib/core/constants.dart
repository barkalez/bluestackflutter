/// Constantes generales de la aplicación
class AppConstants {
  // Constantes generales
  static const String appName = 'Bluestack';
  static const String appVersion = '1.0.0';
  
  // Configuración Bluetooth
  static const int btScanTimeout = 15; // Tiempo de escaneo en segundos
  
  // Rutas de navegación
  static const String homeRoute = '/';
  static const String settingsRoute = '/settings';
  static const String newProfileRoute = '/new-profile';
  static const String listProfilesRoute = '/list-profiles';
  static const String connectRoute = '/connect';
  static const String profileDetailRoute = '/profile-detail';
  static const String controlRoute = '/control';
  static const String manualControlRoute = '/manual-control';
  static const String stackConfigRoute = '/stack-config';
  
  // Claves de almacenamiento
  static const String prefLastDevice = 'last_connected_device';
  static const String prefProfileKey = 'profile';
  static const String prefProfilesList = 'profiles_list';
} 