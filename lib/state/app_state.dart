import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:convert';
import '../core/logger_config.dart';
import '../data/models/profile_model.dart';
import '../data/services/profile_service.dart';

/// Clase para manejar el estado global de la aplicación
class AppState extends ChangeNotifier {
  static const _className = 'AppState';
  final Logger _logger = LoggerConfig.logger;
  final ProfileService _profileService = ProfileService();
  
  // Clave para almacenar dispositivos recientes en SharedPreferences
  static const String _recentDevicesKey = 'recent_bluetooth_devices';
  
  // Estado general de la aplicación
  bool _isLoading = false;
  String _statusMessage = '';
  
  // Perfiles de configuración
  List<String> _profileNames = [];
  ProfileModel? _activeProfile;
  
  // Estado de conexión Bluetooth
  bool _isConnected = false;
  bool _isConnecting = false; // Añadido para indicar proceso de conexión
  String? _connectedDeviceName;
  String? _connectedDeviceAddress;
  List<Map<String, String?>> _recentDevices = []; // Dispositivos recientes
  BluetoothConnection? _activeConnection;
  
  // Estado del slider
  double _sliderValue = 0.0;
  double _maxSliderValue = 400.0; // Valor por defecto
  
  AppState() {
    _logger.d('$_className: Inicializado');
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
  bool get isConnecting => _isConnecting; // Getter para isConnecting
  String? get connectedDeviceName => _connectedDeviceName;
  String? get connectedDeviceAddress => _connectedDeviceAddress;
  List<Map<String, String?>> get recentDevices => _recentDevices;
  BluetoothConnection? get connection => _activeConnection;
  
  // Getters para el estado del slider
  double get sliderValue => _sliderValue;
  double get maxSliderValue => _maxSliderValue;
  
  /// Carga los nombres de perfiles disponibles
  Future<void> _loadProfileNames() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _profileNames = await _profileService.getProfileNames();
      _logger.d('$_className: Perfiles cargados: ${_profileNames.length}');
    } catch (e) {
      _logger.e('$_className: Error al cargar perfiles: $e');
      _statusMessage = 'Error al cargar perfiles: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Obtiene un perfil por su nombre
  Future<ProfileModel?> getProfile(String name) async {
    _logger.d('$_className: Obteniendo perfil: $name');
    try {
      return await _profileService.getProfile(name);
    } catch (e) {
      _logger.e('$_className: Error al obtener perfil: $e');
      return null;
    }
  }
  
  /// Establece el perfil activo
  Future<bool> setActiveProfile(String name) async {
    _isLoading = true;
    _statusMessage = 'Estableciendo perfil activo...';
    notifyListeners();
    
    try {
      final profile = await _profileService.getProfile(name);
      if (profile != null) {
        _activeProfile = profile;
        _statusMessage = 'Perfil activo: ${profile.name}';
        _logger.d('$_className: Perfil activo establecido: ${profile.name}');
        notifyListeners();
        return true;
      } else {
        _statusMessage = 'Error: Perfil no encontrado';
        _logger.e('$_className: Perfil no encontrado: $name');
        return false;
      }
    } catch (e) {
      _statusMessage = 'Error al establecer perfil activo: $e';
      _logger.e('$_className: Error al establecer perfil activo: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Carga un perfil por su nombre
  Future<void> loadProfile(String profileName) async {
    _isLoading = true;
    _statusMessage = 'Cargando perfil...';
    notifyListeners();
    
    try {
      _activeProfile = await _profileService.getProfile(profileName);
      _statusMessage = 'Perfil cargado: $profileName';
      _logger.d('$_className: Perfil cargado: $profileName');
    } catch (e) {
      _activeProfile = null;
      _statusMessage = 'Error al cargar el perfil: $e';
      _logger.e('$_className: Error al cargar el perfil: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Guarda un nuevo perfil
  Future<bool> saveProfile(ProfileModel profile) async {
    _isLoading = true;
    _statusMessage = 'Guardando perfil...';
    notifyListeners();
    
    try {
      await _profileService.saveProfile(profile);
      await _loadProfileNames(); // Actualizar la lista de perfiles
      _statusMessage = 'Perfil guardado correctamente';
      _logger.d('$_className: Perfil guardado: ${profile.name}');
      return true;
    } catch (e) {
      _statusMessage = 'Error al guardar el perfil: $e';
      _logger.e('$_className: Error al guardar el perfil: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Elimina un perfil por su nombre
  Future<bool> deleteProfile(String profileName) async {
    _isLoading = true;
    _statusMessage = 'Eliminando perfil...';
    notifyListeners();
    
    try {
      await _profileService.deleteProfile(profileName);
      
      // Si el perfil activo es el que se está eliminando, desactivarlo
      if (_activeProfile?.name == profileName) {
        _activeProfile = null;
      }
      
      // Actualizar la lista de perfiles
      await _loadProfileNames();
      
      _statusMessage = 'Perfil eliminado correctamente';
      _logger.d('$_className: Perfil eliminado: $profileName');
      return true;
    } catch (e) {
      _statusMessage = 'Error al eliminar el perfil: $e';
      _logger.e('$_className: Error al eliminar el perfil: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Establece un dispositivo como conectado
  void setConnectedDevice(BluetoothDevice device, BluetoothConnection connection) {
    _connectedDeviceName = device.name ?? 'Dispositivo desconocido';
    _connectedDeviceAddress = device.address;
    _activeConnection = connection;
    _isConnected = true;
    _isConnecting = false;
    _logger.d('$_className: Dispositivo conectado: ${device.name ?? "Sin nombre"} (${device.address})');
    notifyListeners();
  }
  
  /// Desconecta del dispositivo actualmente conectado
  Future<void> disconnectFromDevice() async {
    _logger.d('$_className: Desconectando dispositivo');
    
    try {
      _isConnected = false;
      _isConnecting = false;
      _connectedDeviceName = null;
      _connectedDeviceAddress = null;
      
      if (_activeConnection != null) {
        if (_activeConnection!.isConnected) {
          await _activeConnection!.finish();
          _logger.d('$_className: Conexión cerrada correctamente');
        }
        _activeConnection = null;
      }
    } catch (e) {
      _logger.e('$_className: Error al desconectar: $e');
    } finally {
      notifyListeners();
    }
  }
  
  /// Añade un dispositivo a la lista de recientes
  Future<void> addRecentDevice(String name, String address) async {
    _logger.d('$_className: Añadiendo dispositivo reciente: $name ($address)');
    
    // Verificar si el dispositivo ya existe en la lista
    bool deviceExists = _recentDevices.any((device) => 
        device['address'] == address);
    
    // Si ya existe, lo movemos al inicio de la lista
    if (deviceExists) {
      _recentDevices.removeWhere((device) => device['address'] == address);
    }
    
    // Añadir el dispositivo al inicio de la lista
    _recentDevices.insert(0, {'name': name, 'address': address});
    
    // Limitar la lista a 5 dispositivos
    if (_recentDevices.length > 5) {
      _recentDevices = _recentDevices.sublist(0, 5);
    }
    
    // Guardar la lista actualizada
    await _saveRecentDevices();
    
    notifyListeners();
  }
  
  /// Obtiene información sobre los dispositivos recientes
  List<Map<String, String?>> getRecentDevicesInfo() {
    return _recentDevices;
  }
  
  /// Limpia la lista de dispositivos recientes
  Future<void> clearRecentDevices() async {
    _recentDevices = [];
    await _saveRecentDevices();
    notifyListeners();
  }
  
  /// Guarda la lista de dispositivos recientes en SharedPreferences
  Future<void> _saveRecentDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_recentDevices);
      await prefs.setString(_recentDevicesKey, jsonString);
      _logger.d('$_className: Dispositivos recientes guardados');
    } catch (e) {
      _logger.e('$_className: Error al guardar dispositivos recientes: $e');
    }
  }
  
  /// Carga la lista de dispositivos recientes desde SharedPreferences
  Future<void> _loadRecentDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_recentDevicesKey);
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decodedList = jsonDecode(jsonString);
        _recentDevices = decodedList.map((item) => 
          Map<String, String?>.from(item)).toList();
        _logger.d('$_className: Dispositivos recientes cargados: ${_recentDevices.length}');
      }
    } catch (e) {
      _logger.e('$_className: Error al cargar dispositivos recientes: $e');
      _recentDevices = [];
    }
    
    notifyListeners();
  }
  
  // Métodos para actualizar el estado del slider
  void setSliderValue(double value) {
    _sliderValue = value;
    notifyListeners();
  }
  
  void setMaxSliderValue(double value) {
    _maxSliderValue = value;
    notifyListeners();
  }
  
  // Método para inicializar los valores del slider basado en el perfil activo
  void initializeSliderValues() {
    if (hasActiveProfile && activeProfile != null) {
      _maxSliderValue = activeProfile!.totalStepGroups.toDouble();
      notifyListeners();
    }
  }
} 