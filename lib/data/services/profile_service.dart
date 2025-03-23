import 'package:shared_preferences/shared_preferences.dart';
import '../../core/logger_config.dart';
import '../../core/constants.dart';
import '../models/profile_model.dart';

/// Interfaz para el servicio de perfiles
/// Permite desacoplar la implementación y facilitar pruebas unitarias
abstract class IProfileService {
  /// Guarda un perfil en el almacenamiento persistente
  Future<bool> saveProfile(ProfileModel profile);
  
  /// Obtiene un perfil por su nombre
  Future<ProfileModel?> getProfile(String name);
  
  /// Obtiene la lista de nombres de perfiles guardados
  Future<List<String>> getProfileNames();
  
  /// Elimina un perfil por su nombre
  Future<bool> deleteProfile(String name);
}

/// Implementación del servicio de perfiles usando SharedPreferences
/// Sigue el principio de Responsabilidad Única (SRP) centrándose solo en
/// operaciones de almacenamiento de perfiles
class ProfileService implements IProfileService {
  final _logger = LoggerConfig.logger;
  
  /// Instancia de SharedPreferences (memoizada para optimizar rendimiento)
  SharedPreferences? _prefsInstance;
  
  /// Obtiene la instancia de SharedPreferences optimizando llamadas repetidas
  Future<SharedPreferences> get _prefs async => 
      _prefsInstance ??= await SharedPreferences.getInstance();
  
  /// Obtiene la clave completa para un perfil
  String _getProfileKey(String name) => '${AppConstants.prefProfileKey}_$name';
  
  @override
  Future<bool> saveProfile(ProfileModel profile) async {
    _logger.d('Intentando guardar perfil: ${profile.name}');
    
    try {
      // Validar que el nombre no esté vacío
      if (profile.name.isEmpty) {
        _logger.w('Intento de guardar perfil con nombre vacío');
        return false;
      }
      
      final prefs = await _prefs;
      final result = await prefs.setString(
        _getProfileKey(profile.name), 
        profile.toJsonString()
      );
      
      if (result) {
        // Actualizar la lista de perfiles guardados
        await _updateProfilesList(profile.name);
        _logger.i('Perfil guardado exitosamente: ${profile.name}');
      } else {
        _logger.w('No se pudo guardar el perfil: ${profile.name}');
      }
      
      return result;
    } catch (e) {
      _logger.e('Error al guardar perfil: $e');
      return false;
    }
  }
  
  @override
  Future<ProfileModel?> getProfile(String name) async {
    _logger.d('Intentando obtener perfil: $name');
    
    try {
      final prefs = await _prefs;
      final jsonString = prefs.getString(_getProfileKey(name));
      
      if (jsonString == null) {
        _logger.w('Perfil no encontrado: $name');
        return null;
      }
      
      final profile = ProfileModel.fromJsonString(jsonString);
      _logger.d('Perfil cargado exitosamente: $name');
      return profile;
    } catch (e) {
      _logger.e('Error al cargar perfil: $e');
      return null;
    }
  }
  
  @override
  Future<List<String>> getProfileNames() async {
    _logger.d('Obteniendo lista de perfiles');
    
    try {
      final prefs = await _prefs;
      final profileNames = prefs.getStringList(AppConstants.prefProfilesList) ?? [];
      
      _logger.d('Perfiles cargados: ${profileNames.length}');
      return List.unmodifiable(profileNames); // Inmutable para evitar modificaciones accidentales
    } catch (e) {
      _logger.e('Error al cargar lista de perfiles: $e');
      return const [];
    }
  }
  
  @override
  Future<bool> deleteProfile(String name) async {
    _logger.d('Intentando eliminar perfil: $name');
    
    try {
      final prefs = await _prefs;
      
      // Eliminar el perfil
      final resultDelete = await prefs.remove(_getProfileKey(name));
      
      if (resultDelete) {
        // Actualizar la lista de perfiles
        final profileNames = prefs.getStringList(AppConstants.prefProfilesList) ?? [];
        profileNames.remove(name);
        await prefs.setStringList(AppConstants.prefProfilesList, profileNames);
        _logger.i('Perfil eliminado exitosamente: $name');
      } else {
        _logger.w('No se pudo eliminar el perfil: $name');
      }
      
      return resultDelete;
    } catch (e) {
      _logger.e('Error al eliminar perfil: $e');
      return false;
    }
  }
  
  /// Actualiza la lista de perfiles guardados
  Future<bool> _updateProfilesList(String profileName) async {
    try {
      final prefs = await _prefs;
      final profileNames = prefs.getStringList(AppConstants.prefProfilesList) ?? [];
      
      if (!profileNames.contains(profileName)) {
        profileNames.add(profileName);
        final result = await prefs.setStringList(AppConstants.prefProfilesList, profileNames);
        _logger.d('Lista de perfiles actualizada: ${profileNames.length}');
        return result;
      }
      
      return true;
    } catch (e) {
      _logger.e('Error al actualizar lista de perfiles: $e');
      return false;
    }
  }
  
  /// Limpia la caché interna (útil para pruebas)
  void clearCache() {
    _prefsInstance = null;
  }
} 