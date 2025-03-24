import 'package:permission_handler/permission_handler.dart';
import '../../core/logger_config.dart';

/// Servicio que maneja los permisos de la aplicación
class PermissionService {
  static const _className = 'PermissionService';
  final _logger = LoggerConfig.logger;
  
  /// Solicita los permisos necesarios para el funcionamiento de Bluetooth
  Future<bool> requestBluetoothPermissions() async {
    _logger.d('$_className: Solicitando permisos necesarios para Bluetooth');
    
    try {
      // Para Android 12+ (API 31+): BLUETOOTH_SCAN, BLUETOOTH_CONNECT
      // Para Android <12: BLUETOOTH, BLUETOOTH_ADMIN, ACCESS_FINE_LOCATION
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location, // Todavía necesario para algunos dispositivos
      ].request();
      
      // Verificar si todos los permisos fueron concedidos
      bool allPermissionsGranted = true;
      statuses.forEach((permission, status) {
        if (!status.isGranted) {
          allPermissionsGranted = false;
          _logger.w('$_className: Permiso $permission no concedido. Estado: $status');
        }
      });
      
      return allPermissionsGranted;
    } catch (e) {
      _logger.e('$_className: Error al solicitar permisos: $e');
      return false;
    }
  }
} 