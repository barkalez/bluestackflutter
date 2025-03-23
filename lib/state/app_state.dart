import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../core/logger_config.dart';
import '../data/models/profile_model.dart';
import '../data/services/profile_service.dart';

/// Clase para manejar el estado global de la aplicación
class AppState extends ChangeNotifier {
  final Logger _logger = LoggerConfig.logger;
  final ProfileService _profileService = ProfileService();
  
  bool _isLoading = false;
  String _statusMessage = '';
  List<String> _profileNames = [];
  ProfileModel? _activeProfile;
  
  AppState() {
    _logger.d('AppState inicializado');
    _loadProfileNames();
  }
  
  // Getters
  bool get isLoading => _isLoading;
  String get statusMessage => _statusMessage;
  List<String> get profileNames => _profileNames;
  ProfileModel? get activeProfile => _activeProfile;
  bool get hasActiveProfile => _activeProfile != null;
  
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
} 