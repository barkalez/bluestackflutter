import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../core/logger_config.dart';
import '../data/models/profile_model.dart';
import '../data/services/profile_service.dart';

/// Clase para manejar el estado global de la aplicación
class AppState extends ChangeNotifier {
  final Logger _logger = LoggerConfig.logger;
  final ProfileService _profileService = ProfileService();
  
  // Clave para almacenar dispositivos recientes en SharedPreferences
  static const String _recentDevicesKey = 'recent_bluetooth_devices';
  
  bool _isLoading = false;
  String _statusMessage = '';
  List<String> _profileNames = [];
  ProfileModel? _activeProfile;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _connectedDeviceName;
  String? _connectedDeviceAddress;
  List<String> _recentDevices = []; // Mantener lista de dispositivos recientes
  
  // Conexión Bluetooth activa
  BluetoothConnection? _activeConnection;
  
  AppState() {
    _logger.d('AppState inicializado');
    _loadProfileNames();
    _loadRecentDevices();
  }
  
  // Getters
  bool get isLoading => _isLoading;
  String get statusMessage => _statusMessage;
  List<String> get profileNames => _profileNames;
  ProfileModel? get activeProfile => _activeProfile;
  bool get hasActiveProfile => _activeProfile != null;
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get connectedDeviceName => _connectedDeviceName;
  String? get connectedDeviceAddress => _connectedDeviceAddress;
  List<String> get recentDevices => _recentDevices;
  BluetoothConnection? get activeConnection => _activeConnection;
  BluetoothConnection? get connection => _activeConnection; // Alias para mayor claridad
  
  // Setters con notificación de cambios
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void setStatusMessage(String message) {
    _statusMessage = message;
    _logger.i('Estado actualizado: $message');
    notifyListeners();
  }
  
  /// Cargar la lista de nombres de perfiles
  Future<void> _loadProfileNames() async {
    setLoading(true);
    try {
      _profileNames = await _profileService.getProfileNames();
      _logger.d('Perfiles cargados: ${_profileNames.length}');
    } catch (e) {
      _logger.e('Error al cargar perfiles: $e');
    } finally {
      setLoading(false);
    }
  }
  
  /// Guardar un nuevo perfil
  Future<bool> saveProfile(ProfileModel profile) async {
    setLoading(true);
    try {
      final result = await _profileService.saveProfile(profile);
      if (result) {
        setStatusMessage('Perfil guardado: ${profile.name}');
        await _loadProfileNames(); // Recargar la lista de perfiles
      } else {
        setStatusMessage('Error al guardar el perfil');
      }
      return result;
    } catch (e) {
      _logger.e('Error al guardar perfil: $e');
      setStatusMessage('Error: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }
  
  /// Obtener un perfil por nombre
  Future<ProfileModel?> getProfile(String name) async {
    return await _profileService.getProfile(name);
  }
  
  /// Eliminar un perfil por nombre
  Future<bool> deleteProfile(String name) async {
    setLoading(true);
    try {
      final result = await _profileService.deleteProfile(name);
      if (result) {
        setStatusMessage('Perfil eliminado: $name');
        await _loadProfileNames(); // Recargar la lista de perfiles
        // Si el perfil eliminado era el activo, limpiarlo
        if (_activeProfile?.name == name) {
          _activeProfile = null;
          notifyListeners();
        }
      } else {
        setStatusMessage('Error al eliminar el perfil');
      }
      return result;
    } catch (e) {
      _logger.e('Error al eliminar perfil: $e');
      setStatusMessage('Error: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Establece el perfil activo
  Future<bool> setActiveProfile(String name) async {
    setLoading(true);
    try {
      final profile = await _profileService.getProfile(name);
      if (profile != null) {
        _activeProfile = profile;
        setStatusMessage('Perfil activo: ${profile.name}');
        notifyListeners();
        return true;
      } else {
        setStatusMessage('Error: Perfil no encontrado');
        return false;
      }
    } catch (e) {
      _logger.e('Error al establecer perfil activo: $e');
      setStatusMessage('Error: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }
  
  /// Conecta a un dispositivo BlueStack
  /// 
  /// Esta es una implementación simulada que solo cambia el estado.
  /// La implementación real conectará con el dispositivo BlueStack a través de Bluetooth.
  /// 
  /// [device] El dispositivo Bluetooth al que conectarse (opcional).
  /// Si no se proporciona, se utilizará el último dispositivo conectado o se indicará el error.
  Future<bool> connectToDevice([dynamic device]) async {
    // Verificar si ya hay una conexión activa
    if (_isConnected) {
      _logger.w('AppState: Ya hay una conexión activa');
      return true;
    }
    
    // Verificar si hay un perfil activo
    if (_activeProfile == null) {
      _logger.w('AppState: No hay un perfil activo para conectar');
      return false;
    }
    
    _isConnecting = true;
    notifyListeners();
    
    try {
      if (device != null) {
        _logger.d('AppState: Simulando conexión al dispositivo ${device.name ?? "Desconocido"}');
      } else {
        _logger.d('AppState: Simulando conexión al dispositivo BlueStack (genérico)');
      }
      
      // Simular la conexión (se reemplazará con la implementación real)
      await Future.delayed(const Duration(seconds: 2));
      
      // Establecer el dispositivo conectado
      if (device != null) {
        setConnectedDevice(device);
      } else {
        // Si no se proporciona un dispositivo, simplemente actualizamos el estado
        _isConnected = true;
        _isConnecting = false;
        setStatusMessage('Conectado a BlueStack');
      }
      
      return true;
    } catch (e) {
      _logger.e('AppState: Error al conectar: $e');
      _isConnecting = false;
      setStatusMessage('Error al conectar: $e');
      return false;
    }
  }
  
  /// Establece el dispositivo conectado actualmente y la conexión activa
  ///
  /// Actualiza el estado de la aplicación para reflejar la conexión al dispositivo.
  void setConnectedDevice(dynamic device, [BluetoothConnection? connection]) {
    final deviceName = device.name ?? "Desconocido";
    final deviceAddress = device.address ?? "";
    
    _logger.d('AppState: Estableciendo dispositivo conectado: $deviceName');
    
    // Actualizar la información del dispositivo
    _connectedDeviceName = deviceName;
    _connectedDeviceAddress = deviceAddress;
    
    // Guardar la conexión si se proporciona
    if (connection != null) {
      _activeConnection = connection;
      _logger.d('AppState: Conexión Bluetooth almacenada');
    }
    
    // Actualizar el estado de conexión
    _isConnected = true;
    _isConnecting = false;
    
    // Añadir a dispositivos recientes
    if (deviceName != "Desconocido" && deviceAddress.isNotEmpty) {
      addRecentDevice(deviceName, deviceAddress);
    }
    
    setStatusMessage('Conectado a $deviceName');
  }
  
  /// Cierra la conexión Bluetooth activa y limpia la información del dispositivo
  Future<void> disconnectDevice() async {
    // Verificar si hay una conexión activa
    if (!_isConnected) {
      _logger.w('AppState: No hay una conexión activa');
      return;
    }
    
    _isConnecting = true;
    notifyListeners();
    
    try {
      _logger.d('AppState: Cerrando conexión Bluetooth...');
      
      // Cerrar la conexión si existe
      if (_activeConnection != null && _activeConnection!.isConnected) {
        await _activeConnection!.close();
        _logger.d('AppState: Conexión Bluetooth cerrada');
      }
      
      // Limpiar la conexión
      _activeConnection = null;
      
      // Limpiar información del dispositivo
      clearConnectedDevice();
      
      return;
    } catch (e) {
      _logger.e('AppState: Error al desconectar: $e');
      _isConnecting = false;
      setStatusMessage('Error al desconectar: $e');
    }
  }
  
  /// Alias para disconnectDevice (para compatibilidad)
  Future<void> disconnectFromDevice() => disconnectDevice();
  
  /// Envía datos al dispositivo Bluetooth conectado
  Future<bool> sendData(Uint8List data) async {
    if (!_isConnected || _activeConnection == null) {
      _logger.e('AppState: No hay dispositivo conectado para enviar datos');
      return false;
    }
    
    try {
      _logger.d('AppState: Enviando ${data.length} bytes de datos al dispositivo');
      
      if (_activeConnection!.isConnected) {
        _activeConnection!.output.add(data);
        await _activeConnection!.output.allSent;
        _logger.d('AppState: Datos enviados correctamente');
        return true;
      } else {
        _logger.e('AppState: La conexión existe pero está cerrada');
        // Actualizar el estado
        _isConnected = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _logger.e('AppState: Error al enviar datos: $e');
      return false;
    }
  }
  
  /// Limpia la información del dispositivo conectado
  void clearConnectedDevice() {
    _logger.d('AppState: Limpiando información del dispositivo conectado');
    
    _connectedDeviceName = null;
    _connectedDeviceAddress = null;
    _isConnected = false;
    
    setStatusMessage('Desconectado');
  }
  
  /// Añade un dispositivo a la lista de dispositivos recientes
  /// 
  /// Esto permite mantener un historial de dispositivos con los que el usuario
  /// se ha conectado anteriormente.
  void addRecentDevice(String deviceName, String deviceAddress) {
    if (deviceName.isEmpty || deviceAddress.isEmpty) return;
    
    // Crear un identificador único para el dispositivo
    final deviceId = '$deviceName|$deviceAddress';
    
    // Evitar duplicados
    if (!_recentDevices.contains(deviceId)) {
      _recentDevices.add(deviceId);
      // Mantener solo los últimos 5 dispositivos
      if (_recentDevices.length > 5) {
        _recentDevices.removeAt(0);
      }
      notifyListeners();
      _logger.d('AppState: Dispositivo añadido a recientes: $deviceName');
      
      // Guardar en SharedPreferences
      _saveRecentDevices();
    }
  }
  
  /// Obtiene los dispositivos recientes en un formato más útil
  List<Map<String, String>> getRecentDevicesInfo() {
    return _recentDevices.map((deviceId) {
      final parts = deviceId.split('|');
      return {
        'name': parts[0],
        'address': parts.length > 1 ? parts[1] : '',
      };
    }).toList();
  }
  
  /// Limpia la lista de dispositivos recientes
  void clearRecentDevices() {
    _recentDevices.clear();
    notifyListeners();
    _logger.d('AppState: Lista de dispositivos recientes limpiada');
    
    // Actualizar en SharedPreferences
    _saveRecentDevices();
  }
  
  /// Carga la lista de dispositivos recientes desde SharedPreferences
  Future<void> _loadRecentDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentDevicesJson = prefs.getString(_recentDevicesKey);
      
      if (recentDevicesJson != null) {
        final List<dynamic> decodedList = jsonDecode(recentDevicesJson);
        _recentDevices = decodedList.map((item) => item.toString()).toList();
        _logger.d('AppState: Dispositivos recientes cargados: ${_recentDevices.length}');
      }
    } catch (e) {
      _logger.e('AppState: Error al cargar dispositivos recientes: $e');
    }
  }
  
  /// Guarda la lista de dispositivos recientes en SharedPreferences
  Future<void> _saveRecentDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentDevicesJson = jsonEncode(_recentDevices);
      await prefs.setString(_recentDevicesKey, recentDevicesJson);
      _logger.d('AppState: Dispositivos recientes guardados');
    } catch (e) {
      _logger.e('AppState: Error al guardar dispositivos recientes: $e');
    }
  }
} 