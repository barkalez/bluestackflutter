import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../../core/logger_config.dart';
import '../../state/app_state.dart';
import '../widgets/common/custom_app_bar.dart';
import '../../core/constants.dart';
import '../widgets/home/home_buttons.dart';
import '../widgets/home/profile_info_message.dart';

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
  
  const HomeScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (_, appState, __) {
        final hasProfiles = appState.profileNames.isNotEmpty;
        
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CreateProfileButton(),
              const SizedBox(height: verticalSpacing),
              
              if (hasProfiles) ...[
                const LoadProfileButton(),
                const SizedBox(height: verticalSpacing),
                ProfileInfoMessage(profileCount: appState.profileNames.length),
              ],
              
              // Mostrar el indicador de perfil activo y los botones cuando hay un perfil activo
              if (appState.hasActiveProfile) ...[
                const SizedBox(height: verticalSpacing),
                _buildActiveProfileIndicator(appState),
                const SizedBox(height: extraSpacing),
                const ConnectButton(),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AppConstants.profileDetailRoute);
                  },
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Ver detalles del perfil'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
  
  /// Construye el indicador del perfil activo
  Widget _buildActiveProfileIndicator(AppState appState) {
    final profileName = appState.activeProfile?.name ?? '';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 25),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.green.withValues(alpha: 120)),
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
} 