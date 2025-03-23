import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/logger_config.dart';
import '../../state/app_state.dart';
import '../widgets/common/custom_app_bar.dart';
import '../../data/models/profile_model.dart';
import '../../core/constants.dart';

/// Pantalla para listar los perfiles creados
class ListProfileScreen extends StatefulWidget {
  /// Ruta nombrada para esta pantalla
  static const String routeName = AppConstants.listProfilesRoute;
  
  const ListProfileScreen({super.key});

  @override
  State<ListProfileScreen> createState() => _ListProfileScreenState();
}

class _ListProfileScreenState extends State<ListProfileScreen> {
  final _logger = LoggerConfig.logger;
  
  @override
  void initState() {
    super.initState();
    _logger.d('ListProfileScreen inicializada');
  }

  @override
  void dispose() {
    _logger.d('ListProfileScreen destruida');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(title: 'Perfiles guardados'),
      body: _ListProfileContent(),
    );
  }
}

/// Widget para el contenido principal de la pantalla de lista de perfiles
/// Separado para mantener la lógica fuera de la UI
class _ListProfileContent extends StatelessWidget {
  const _ListProfileContent();

  @override
  Widget build(BuildContext context) {
    final logger = LoggerConfig.logger;

    return Consumer<AppState>(
      builder: (_, appState, __) {
        // Verificar si hay perfiles guardados
        if (appState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final profileNames = appState.profileNames;
        
        if (profileNames.isEmpty) {
          // Navegar automáticamente a la pantalla de inicio después de un breve retraso
          logger.d('No hay perfiles guardados, navegando a la pantalla de inicio');
          
          // Usar Future.delayed para dar tiempo a que se construya la UI
          Future.delayed(const Duration(milliseconds: 100), () {
            if (context.mounted) {
              Navigator.of(context).pushReplacementNamed(AppConstants.homeRoute);
            }
          });
          
          // Mientras tanto, mostrar un indicador de carga
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('No hay perfiles guardados. Redirigiendo...'),
              ],
            ),
          );
        }
        
        return _ProfileList(profileNames: profileNames);
      },
    );
  }
}



/// Widget para mostrar la lista de perfiles
class _ProfileList extends StatelessWidget {
  final List<String> profileNames;
  
  const _ProfileList({required this.profileNames});
  
  @override
  Widget build(BuildContext context) {
    final logger = LoggerConfig.logger;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: profileNames.length,
      itemBuilder: (context, index) {
        final profileName = profileNames[index];
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () {
                  logger.d('Perfil seleccionado: $profileName');
                  _loadProfileAndNavigateToHome(context, profileName);
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        Colors.blue.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Avatar con gradiente
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: const [
                                Color(0xFF448AFF),
                                Color(0xFF0D47A1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF448AFF).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.account_circle,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Contenido
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profileName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              FutureBuilder<ProfileModel?>(
                                future: Provider.of<AppState>(context, listen: false)
                                    .getProfile(profileName),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Text(
                                      'Cargando detalles...',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    );
                                  }
                                  
                                  if (!snapshot.hasData || snapshot.data == null) {
                                    return const Text(
                                      'No se pudieron cargar los detalles',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                      ),
                                    );
                                  }
                                  
                                  final profile = snapshot.data!;
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pasos por revolución: ${profile.stepsPerRevolution}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Distancia por revolución: ${profile.distancePerRevolution}mm',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        // Icono para eliminar
                        InkWell(
                          onTap: () => _showDeleteConfirmation(context, profileName),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red.withValues(alpha: 0.1),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Método para mostrar el diálogo de confirmación de eliminación
  void _showDeleteConfirmation(BuildContext context, String profileName) {
    final logger = LoggerConfig.logger;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Eliminar perfil'),
        content: Text('¿Estás seguro que deseas eliminar el perfil "$profileName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              // Cerrar el diálogo
              Navigator.of(context).pop();
              
              // Eliminar el perfil usando AppState
              logger.d('Intentando eliminar perfil: $profileName');
              final appState = Provider.of<AppState>(context, listen: false);
              final success = await appState.deleteProfile(profileName);
              
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Perfil "$profileName" eliminado correctamente')),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al eliminar el perfil')),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // Método para cargar el perfil y navegar a la pantalla de inicio
  void _loadProfileAndNavigateToHome(BuildContext context, String profileName) async {
    final logger = LoggerConfig.logger;
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Mostrar SnackBar informando que se está cargando el perfil
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cargando perfil "$profileName"...'),
        duration: const Duration(seconds: 1),
      ),
    );
    
    try {
      // Establecer el perfil activo
      final success = await appState.setActiveProfile(profileName);
      
      if (!success) {
        throw Exception('No se pudo cargar el perfil');
      }
      
      logger.d('Perfil "$profileName" cargado correctamente');
      
      // Esperar un momento para que se vea el SnackBar
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (context.mounted) {
        // Mostrar SnackBar informando que el perfil se cargó correctamente
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Perfil "$profileName" cargado correctamente'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navegar a la pantalla de inicio
        Navigator.of(context).pushReplacementNamed(AppConstants.homeRoute);
      }
    } catch (e) {
      logger.e('Error al cargar el perfil: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar el perfil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 