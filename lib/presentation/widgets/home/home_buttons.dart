import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/logger_config.dart';
import '../../../core/constants.dart';
import '../../../state/app_state.dart';
import 'package:provider/provider.dart';
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
  static const _className = 'ConnectButton';
  /// Constantes de diseño para el botón
  static const double _buttonWidth = 0.5; // 50% del ancho de pantalla
  static const List<Color> _buttonGradient = [
    Color(0xFFE91E63), // Rosa
    Color(0xFF880E4F), // Rosa oscuro
  ];
  static const List<Color> _disconnectGradient = [
    Color(0xFFFF5252), // Rojo brillante
    Color(0xFFB71C1C), // Rojo oscuro
  ];
  
  const ConnectButton({super.key});
  
  @override
  Widget build(BuildContext context) {
    final logger = LoggerConfig.logger;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final bool isConnected = appState.isConnected;
        final bool isConnecting = appState.isConnecting;
        
        return GestureDetector(
          onLongPress: isConnected || isConnecting 
              ? null  // Deshabilitar el gesto cuando está conectado o conectando
              : () {
                  logger.d('$_className: Mostrando detalles del perfil activo');
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
            text: isConnected 
                ? 'Desconectar' 
                : (isConnecting ? 'Conectando...' : 'Conectar'),
            onPressed: isConnecting 
                ? null  // Deshabilitar durante la conexión
                : () => _handleConnectionToggle(context, appState),
            icon: isConnected 
                ? Icons.bluetooth_disabled 
                : Icons.bluetooth_connected,
            width: screenWidth * _buttonWidth,
            gradientColors: isConnected ? _disconnectGradient : _buttonGradient,
            isLoading: isConnecting,
          ),
        );
      },
    );
  }
  
  /// Maneja la conexión o desconexión del dispositivo Bluetooth
  Future<void> _handleConnectionToggle(BuildContext context, AppState appState) async {
    final logger = LoggerConfig.logger;
    
    try {
      if (appState.isConnected) {
        // Si está conectado, desconectar
        logger.d('$_className: Iniciando desconexión de Bluestack');
        
        // Mostrar SnackBar informando que se está desconectando
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Desconectando de BlueStack...'),
              duration: Duration(seconds: 1),
            ),
          );
        }
        
        await appState.disconnectFromDevice();
      } else {
        // Si no está conectado, navegar a la pantalla de escaneo
        _navigateToBluetoothScan(context);
      }
    } catch (e) {
      logger.e('$_className: Error al manejar conexión/desconexión: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Navega a la pantalla de escaneo Bluetooth
  void _navigateToBluetoothScan(BuildContext context) async {
    final logger = LoggerConfig.logger;
    logger.d('$_className: Navegando a pantalla de escaneo Bluetooth');
    
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Verificar si hay un perfil activo antes de continuar
    if (!appState.hasActiveProfile) {
      logger.w('$_className: No hay perfil activo para conectar');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay un perfil activo. Por favor, carga un perfil primero.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    // Navegar a la pantalla de escaneo
    final result = await Navigator.pushNamed(context, AppConstants.connectRoute);
    
    // Procesar el resultado de la pantalla de escaneo (si se conectó exitosamente)
    if (result == true && context.mounted) {
      logger.d('$_className: Conexión exitosa, actualizando UI');
      // Notificar al usuario que la conexión fue exitosa
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conectado a BlueStack correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
} 