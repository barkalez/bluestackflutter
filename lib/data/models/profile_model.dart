import 'dart:convert';
import '../../core/logger_config.dart';

/// Modelo inmutable para almacenar los datos de un perfil de configuración
/// Sigue principios de Clean Architecture y SOLID
class ProfileModel {
  /// Nombre único del perfil
  final String name;
  
  /// Número de pasos por revolución del motor
  final int stepsPerRevolution;
  
  /// Distancia recorrida por revolución en milímetros
  final double distancePerRevolution;
  
  /// Sensibilidad del tornillo en milímetros
  final double screwSensitivity;
  
  /// Distancia máxima de recorrido en milímetros
  final double maxDistance;

  /// Logger para depuración
  static final _logger = LoggerConfig.logger;

  /// Constructor con valores requeridos y validación
  ProfileModel({
    required this.name,
    required this.stepsPerRevolution,
    required this.distancePerRevolution,
    required this.screwSensitivity,
    required this.maxDistance,
  }) : assert(name.isNotEmpty, 'El nombre no puede estar vacío'),
       assert(stepsPerRevolution > 0, 'Los pasos por revolución deben ser positivos'),
       assert(distancePerRevolution > 0, 'La distancia por revolución debe ser positiva'),
       assert(screwSensitivity >= 0, 'La sensibilidad del tornillo no puede ser negativa'),
       assert(maxDistance > 0, 'La distancia máxima debe ser positiva');

  /// Distancia recorrida por cada paso del motor (en milímetros)
  /// Calculado como: Distancia por revolución / Pasos por revolución
  double get distancePerStep {
    if (stepsPerRevolution <= 0) return 0;
    return distancePerRevolution / stepsPerRevolution;
  }
  
  /// Número de pasos agrupados necesarios para alcanzar la sensibilidad del tornillo
  /// Calculado como: Sensibilidad del tornillo / Distancia por paso
  /// Redondeado hacia arriba al entero más cercano
  /// Si la sensibilidad del tornillo es 0, se establece automáticamente a 1
  int get stepGroup {
    // Si la sensibilidad del tornillo es 0, retornar directamente 1
    if (screwSensitivity <= 0) return 1;
    
    final dps = distancePerStep;
    if (dps <= 0) return 1;
    
    final rawValue = screwSensitivity / dps;
    // Redondeo hacia arriba (ceiling)
    return rawValue.ceil();
  }
  
  /// Distancia real recorrida por un grupo de pasos (en milímetros)
  /// Calculado como: Grupo de pasos * Distancia por paso
  double get distPerStepGroup {
    // Usamos el método stepGroup que ya tiene la lógica de manejo para sensibilidad 0
    final sg = stepGroup;
    final dps = distancePerStep;
    return sg * dps;
  }
  
  /// Número total de grupos de pasos necesarios para recorrer la distancia máxima
  /// Calculado como: Distancia máxima / Distancia por grupo de pasos
  /// Redondeado hacia abajo al entero más cercano
  int get totalStepGroups {
    final dpsg = distPerStepGroup;
    // Si la distancia por grupo de pasos es 0, evitamos división por cero
    if (dpsg <= 0) return 0;
    
    final rawValue = maxDistance / dpsg;
    // Redondeo hacia abajo (floor)
    return rawValue.floor();
  }

  /// Crea una copia del perfil con nuevos valores opcionales
  ProfileModel copyWith({
    String? name,
    int? stepsPerRevolution,
    double? distancePerRevolution,
    double? screwSensitivity,
    double? maxDistance,
  }) {
    return ProfileModel(
      name: name ?? this.name,
      stepsPerRevolution: stepsPerRevolution ?? this.stepsPerRevolution,
      distancePerRevolution: distancePerRevolution ?? this.distancePerRevolution,
      screwSensitivity: screwSensitivity ?? this.screwSensitivity,
      maxDistance: maxDistance ?? this.maxDistance,
    );
  }

  /// Convertir de JSON a ProfileModel con manejo de errores
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    try {
      return ProfileModel(
        name: json['name'] as String,
        stepsPerRevolution: (json['stepsPerRevolution'] as num).toInt(),
        distancePerRevolution: (json['distancePerRevolution'] as num).toDouble(),
        screwSensitivity: (json['screwSensitivity'] as num).toDouble(),
        maxDistance: (json['maxDistance'] as num).toDouble(),
      );
    } catch (e) {
      _logger.e('Error al convertir JSON a ProfileModel: $e');
      throw FormatException('El formato del JSON no es válido: $e');
    }
  }

  /// Convertir de ProfileModel a JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'stepsPerRevolution': stepsPerRevolution,
      'distancePerRevolution': distancePerRevolution,
      'screwSensitivity': screwSensitivity,
      'maxDistance': maxDistance,
    };
  }

  /// Convertir a String para guardar en SharedPreferences
  String toJsonString() => jsonEncode(toJson());

  /// Crear desde String almacenado en SharedPreferences con manejo de errores
  static ProfileModel fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return ProfileModel.fromJson(json);
    } catch (e) {
      _logger.e('Error al convertir String a ProfileModel: $e');
      throw FormatException('El formato del string JSON no es válido: $e');
    }
  }
  
  /// Sobrescribe equals para comparación correcta
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ProfileModel &&
        other.name == name &&
        other.stepsPerRevolution == stepsPerRevolution &&
        other.distancePerRevolution == distancePerRevolution &&
        other.screwSensitivity == screwSensitivity &&
        other.maxDistance == maxDistance;
  }

  /// Sobrescribe hashCode para consistencia con equals
  @override
  int get hashCode {
    return name.hashCode ^
        stepsPerRevolution.hashCode ^
        distancePerRevolution.hashCode ^
        screwSensitivity.hashCode ^
        maxDistance.hashCode;
  }
  
  /// Sobrescribe toString para depuración más fácil
  @override
  String toString() {
    return 'ProfileModel(name: $name, stepsPerRevolution: $stepsPerRevolution, '
        'distancePerRevolution: $distancePerRevolution, screwSensitivity: $screwSensitivity, '
        'maxDistance: $maxDistance, distancePerStep: $distancePerStep, '
        'stepGroup: $stepGroup, distPerStepGroup: $distPerStepGroup, '
        'totalStepGroups: $totalStepGroups)';
  }
} 