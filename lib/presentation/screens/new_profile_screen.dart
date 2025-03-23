import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/logger_config.dart';
import '../../state/app_state.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/profile/profile_form.dart';

/// Pantalla para crear un nuevo perfil
class NewProfileScreen extends StatefulWidget {
  /// Ruta nombrada para esta pantalla
  static const String routeName = '/new-profile';
  
  const NewProfileScreen({super.key});

  @override
  State<NewProfileScreen> createState() => _NewProfileScreenState();
}

class _NewProfileScreenState extends State<NewProfileScreen> {
  final _logger = LoggerConfig.logger;

  @override
  void initState() {
    super.initState();
    _logger.d('NewProfileScreen inicializada');
  }

  @override
  void dispose() {
    _logger.d('NewProfileScreen destruida');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Usar Consumer en un nivel superior para minimizar reconstrucciones
    return const Scaffold(
      appBar: CustomAppBar(),
      body: _NewProfileScreenContent(),
    );
  }
}

/// Widget para el contenido principal de la pantalla de nuevo perfil
/// Separado para mantener la lógica fuera de la UI y minimizar reconstrucciones
class _NewProfileScreenContent extends StatelessWidget {
  const _NewProfileScreenContent();

  @override
  Widget build(BuildContext context) {
    // Acceder al AppState solo cuando se necesita
    return Consumer<AppState>(
      builder: (_, __, ___) => const SingleChildScrollView(
        child: Column(
          children: [
            // Título de la pantalla
            _ProfileTitle(),
            // Formulario de nuevo perfil
            ProfileForm(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Widget separado para el título de la pantalla
/// Mejora la legibilidad y reutilización
class _ProfileTitle extends StatelessWidget {
  const _ProfileTitle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        'Crear Nuevo Perfil',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
} 