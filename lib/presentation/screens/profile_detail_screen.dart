import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/logger_config.dart';
import '../../core/constants.dart';
import '../../state/app_state.dart';
import '../../data/models/profile_model.dart';
import '../widgets/common/custom_app_bar.dart';

/// Pantalla que muestra los detalles del perfil activo
class ProfileDetailScreen extends StatelessWidget {
  /// Ruta nombrada para esta pantalla
  static const String routeName = AppConstants.profileDetailRoute;

  const ProfileDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logger = LoggerConfig.logger;
    logger.d('Mostrando detalles del perfil activo');

    return Scaffold(
      appBar: const CustomAppBar(title: 'Detalles del Perfil'),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          if (!appState.hasActiveProfile) {
            return const Center(
              child: Text('No hay un perfil activo'),
            );
          }

          // Acceder al perfil activo
          final profile = appState.activeProfile!;
          return _ProfileDetailContent(profile: profile);
        },
      ),
    );
  }
}

/// Widget para mostrar el contenido de los detalles del perfil
class _ProfileDetailContent extends StatelessWidget {
  final ProfileModel profile;

  const _ProfileDetailContent({required this.profile});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildMainParametersSection(),
          const SizedBox(height: 24),
          _buildCalculatedParametersSection(),
        ],
      ),
    );
  }

  /// Construye el encabezado con el nombre del perfil
  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          const Icon(
            Icons.settings,
            size: 48,
            color: Colors.blue,
          ),
          const SizedBox(height: 8),
          Text(
            profile.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'Perfil Activo',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye la sección de parámetros principales
  Widget _buildMainParametersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Parámetros Principales'),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildParameterRow(
                  'Pasos por revolución:',
                  profile.stepsPerRevolution.toString(),
                  Icons.rotate_right,
                ),
                const Divider(),
                _buildParameterRow(
                  'Distancia por revolución:',
                  '${profile.distancePerRevolution} mm',
                  Icons.straighten,
                ),
                const Divider(),
                _buildParameterRow(
                  'Sensibilidad del tornillo:',
                  '${profile.screwSensitivity} mm',
                  Icons.architecture,
                ),
                const Divider(),
                _buildParameterRow(
                  'Distancia máxima:',
                  '${profile.maxDistance} mm',
                  Icons.compare_arrows,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Construye la sección de parámetros calculados
  Widget _buildCalculatedParametersSection() {
    // Verificar si la sensibilidad del tornillo es 0
    final isScrewSensitivityZero = profile.screwSensitivity <= 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Parámetros Calculados'),
        
        if (isScrewSensitivityZero)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'La sensibilidad del tornillo es 0. Se utilizará un grupo de pasos con valor 1 para los cálculos.',
                      style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.blue.withValues(alpha: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildParameterRow(
                  'Distancia por paso:',
                  '${profile.distancePerStep.toStringAsFixed(9)} mm',
                  Icons.trending_flat,
                  isCalculated: true,
                ),
                const Divider(),
                _buildParameterRow(
                  'Grupo de pasos:',
                  profile.stepGroup.toString() + (isScrewSensitivityZero ? ' (automático)' : ''),
                  Icons.group_work,
                  isCalculated: true,
                ),
                const Divider(),
                _buildParameterRow(
                  'Distancia por grupo:',
                  '${profile.distPerStepGroup.toStringAsFixed(9)} mm',
                  Icons.straighten,
                  isCalculated: true,
                ),
                const Divider(),
                _buildParameterRow(
                  'Total grupos de pasos:',
                  profile.totalStepGroups.toString(),
                  Icons.calculate,
                  isCalculated: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Construye una fila para mostrar un parámetro
  Widget _buildParameterRow(
    String label,
    String value,
    IconData icon, {
    bool isCalculated = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: isCalculated ? Colors.blue : Colors.black54,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isCalculated ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isCalculated ? Colors.blue.shade700 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para los títulos de sección
class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }
} 