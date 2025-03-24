import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../../core/logger_config.dart';
import '../../state/app_state.dart';
import '../../state/bluetooth_provider.dart';
import '../widgets/common/custom_app_bar.dart';
import '../../core/constants.dart';
import '../widgets/home/home_buttons.dart';
import '../widgets/home/profile_info_message.dart';
import '../widgets/common/buttons/gradient_button.dart';

/// Pantalla de inicio de la aplicación.
/// Es la primera pantalla que ve el usuario al iniciar la app.
class HomeScreen extends StatefulWidget {
  /// Ruta nombrada para esta pantalla
  static const String routeName = AppConstants.homeRoute;
  
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Logger _logger = LoggerConfig.logger;

  @override
  void initState() {
    super.initState();
    _logger.d('HomeScreen inicializada');
  }

  @override
  void dispose() {
    _logger.d('HomeScreen destruida');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(),
      body: HomeScreenContent(),
    );
  }
}

/// Widget para el contenido principal de la pantalla de inicio.
/// Separado para mantener la lógica fuera de la UI y minimizar reconstrucciones.
class HomeScreenContent extends StatelessWidget {
  /// Constantes de diseño para mejorar la consistencia visual
  static const double verticalSpacing = 20.0;
  static const double extraSpacing = 40.0;
  static const double _buttonWidth = 0.5; // 50% del ancho de pantalla
  static const List<Color> _controlButtonGradient = [
    Color(0xFF9C27B0), // Morado
    Color(0xFF4A148C), // Morado oscuro
  ];
  
  const HomeScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtenemos el BluetoothProvider para escuchar específicamente los cambios de conexión
    final bluetoothProvider = Provider.of<BluetoothProvider>(context);
    final appState = Provider.of<AppState>(context);
    
    // Variables derivadas del estado
    final hasProfiles = appState.profileNames.isNotEmpty;
    final hasActiveProfile = appState.hasActiveProfile;
    final isConnected = bluetoothProvider.isConnected;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CreateProfileButton(),
          const SizedBox(height: verticalSpacing),
          
          if (hasProfiles) ...[
            const LoadProfileButton(),
            const SizedBox(height: verticalSpacing),
            
            // Si el dispositivo está conectado, mostrar el botón de control
            // Al usar directamente bluetoothProvider.isConnected nos aseguramos que
            // este bloque se actualice cuando cambie el estado de conexión
            if (isConnected) ...[
              GradientButton(
                text: 'Control',
                onPressed: () => _navigateToControlScreen(context),
                icon: Icons.gamepad,
                width: screenWidth * _buttonWidth,
                gradientColors: _controlButtonGradient,
              ),
              const SizedBox(height: verticalSpacing),
            ],
            
            // Mostrar información de perfiles solo si no hay un perfil activo
            if (!hasActiveProfile)
              ProfileInfoMessage(profileCount: appState.profileNames.length),
          ],
          
          // Mostrar el indicador de perfil activo y los botones cuando hay un perfil activo
          if (hasActiveProfile) ...[
            const SizedBox(height: verticalSpacing),
            // Haciendo clickeable el indicador de perfil activo
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppConstants.profileDetailRoute),
              child: _buildActiveProfileIndicator(appState),
            ),
            
            const SizedBox(height: extraSpacing),
            // Botón de conectar/desconectar que ahora operará con el bluetoothProvider
            _buildConnectButton(context, bluetoothProvider),
          ],
        ],
      ),
    );
  }
  
  /// Construye el botón de conexión basado en el estado actual de bluetoothProvider
  Widget _buildConnectButton(BuildContext context, BluetoothProvider bluetoothProvider) {
    final isConnected = bluetoothProvider.isConnected;
    
    // Definir los colores para conectado y desconectado
    final List<Color> connectColors = [
      const Color(0xFF2196F3),  // Azul claro
      const Color(0xFF0D47A1),  // Azul oscuro
    ];
    
    final List<Color> disconnectColors = [
      const Color(0xFFF44336),  // Rojo claro
      const Color(0xFFB71C1C),  // Rojo oscuro
    ];
    
    return GradientButton(
      text: isConnected ? 'Desconectar' : 'Conectar',
      onPressed: () {
        if (isConnected) {
          bluetoothProvider.disconnectDevice();
        } else {
          Navigator.pushNamed(context, AppConstants.connectRoute);
        }
      },
      icon: isConnected ? Icons.link_off : Icons.link,
      gradientColors: isConnected ? disconnectColors : connectColors,
      width: MediaQuery.of(context).size.width * 0.5,  // 50% del ancho de pantalla
      height: 52.0,
      fontSize: 16.0,
    );
  }

  
  /// Construye el indicador del perfil activo
  Widget _buildActiveProfileIndicator(AppState appState) {
    final profileName = appState.activeProfile?.name ?? '';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(25),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.green.withAlpha(120)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 22,
          ),
          const SizedBox(width: 8),
          Text(
            'Perfil activo: $profileName',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Navega a la pantalla de control
  void _navigateToControlScreen(BuildContext context) {
    final logger = LoggerConfig.logger;
    logger.d('HomeScreenContent: Navegando a pantalla de control');
    Navigator.pushNamed(context, AppConstants.controlRoute);
  }
}