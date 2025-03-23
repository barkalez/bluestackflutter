import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/logger_config.dart';
import '../../../core/constants.dart';
import '../common/buttons/gradient_button.dart';

/// Widget para el botón de crear perfil.
/// Mejora la modularidad y testabilidad siguiendo el principio de responsabilidad única.
class CreateProfileButton extends StatelessWidget {
  /// Constantes de diseño para el botón
  static const double _buttonWidth = 0.6; // 60% del ancho de pantalla
  
  const CreateProfileButton({super.key});
  
  @override
  Widget build(BuildContext context) {
    final Logger logger = LoggerConfig.logger;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return GradientButton(
      text: 'Crear perfil',
      onPressed: () {
        logger.d('Navegando a pantalla de nuevo perfil');
        Navigator.pushNamed(context, AppConstants.newProfileRoute);
      },
      icon: Icons.person_add,
      width: screenWidth * _buttonWidth,
    );
  }
}

/// Widget para el botón de cargar perfil.
/// Sigue el principio de responsabilidad única del SOLID.
class LoadProfileButton extends StatelessWidget {
  /// Constantes de diseño para el botón
  static const double _buttonWidth = 0.6; // 60% del ancho de pantalla
  static const List<Color> _buttonGradient = [
    Color(0xFF4CAF50), // Verde claro
    Color(0xFF1B5E20), // Verde oscuro
  ];
  
  const LoadProfileButton({super.key});
  
  @override
  Widget build(BuildContext context) {
    final Logger logger = LoggerConfig.logger;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return GradientButton(
      text: 'Cargar perfil',
      onPressed: () {
        logger.d('Navegando a pantalla de lista de perfiles');
        Navigator.pushNamed(context, AppConstants.listProfilesRoute);
      },
      icon: Icons.folder_open,
      width: screenWidth * _buttonWidth,
      gradientColors: _buttonGradient,
    );
  }
}

/// Widget para el botón de conectar.
/// Mejora la modularidad y testabilidad siguiendo el principio de responsabilidad única.
class ConnectButton extends StatelessWidget {
  /// Constantes de diseño para el botón
  static const double _buttonWidth = 0.5; // 50% del ancho de pantalla
  static const List<Color> _buttonGradient = [
    Color(0xFFE91E63), // Rosa
    Color(0xFF880E4F), // Rosa oscuro
  ];
  
  const ConnectButton({super.key});
  
  @override
  Widget build(BuildContext context) {
    final Logger logger = LoggerConfig.logger;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return GestureDetector(
      onLongPress: () {
        logger.d('Mostrando detalles del perfil activo');
        Navigator.pushNamed(context, AppConstants.profileDetailRoute);
        
        // Mostrar un mensaje para indicar que se accedió a los detalles
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mostrando detalles del perfil'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: GradientButton(
        text: 'Conectar',
        onPressed: () {
          logger.d('Iniciando conexión con Bluestack');
          // Aquí se implementará la lógica de conexión
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Conectando con dispositivo Bluestack...')),
          );
        },
        icon: Icons.bluetooth_connected,
        width: screenWidth * _buttonWidth,
        gradientColors: _buttonGradient,
      ),
    );
  }
} 