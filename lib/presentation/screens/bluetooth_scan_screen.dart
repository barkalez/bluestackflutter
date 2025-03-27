import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:provider/provider.dart';
import '../../core/logger_config.dart';
import '../../core/constants.dart';
import '../../state/app_state.dart';
import '../../state/bluetooth_provider.dart';
import '../widgets/bluetooth/bluetooth_device_item.dart';

/// Pantalla para escanear y conectar a dispositivos Bluetooth
/// 
/// Esta pantalla muestra una interfaz para que el usuario pueda escanear
/// y conectarse a dispositivos Bluetooth HC-05.
/// Toda la lógica de Bluetooth está implementada en BluetoothProvider.
class BluetoothScanScreen extends StatefulWidget {
  /// Ruta nombrada para esta pantalla
  static const String routeName = AppConstants.connectRoute;
  
  const BluetoothScanScreen({super.key});

  @override
  State<BluetoothScanScreen> createState() => _BluetoothScanScreenState();
}

class _BluetoothScanScreenState extends State<BluetoothScanScreen> {
  static const _className = 'BluetoothScanScreen';
  final _logger = LoggerConfig.logger;
  
  @override
  void initState() {
    super.initState();
    _logger.d('$_className: Inicializando pantalla de escaneo Bluetooth');
    
    // Iniciar escaneo automáticamente después de que el widget esté completamente construido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);
      bluetoothProvider.startScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothProvider = Provider.of<BluetoothProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            'Bluestack',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF2196F3),  // Azul primario
                Color(0xFF0D47A1),  // Azul oscuro
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: _buildHomeButton(),
        actions: [
          _buildBluetoothButton(bluetoothProvider),
        ],
      ),
      body: _buildDeviceList(bluetoothProvider),
    );
  }
  
  /// Construye el botón de Bluetooth
  Widget _buildBluetoothButton(BluetoothProvider bluetoothProvider) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bluetoothProvider.isConnected ? Colors.green : Colors.orange,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.bluetooth, color: Colors.white),
          tooltip: bluetoothProvider.isConnected ? 'Desconectar' : 'Conectar',
          padding: EdgeInsets.zero,
          iconSize: 20,
          onPressed: _toggleBluetoothConnection,
        ),
      ),
    );
  }
  
  /// Construye el botón de inicio
  Widget _buildHomeButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.lightBlue,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.home, color: Colors.white),
          tooltip: 'Ir a inicio',
          padding: EdgeInsets.zero,
          iconSize: 20,
          onPressed: _navigateToHome,
        ),
      ),
    );
  }
  
  /// Maneja la conexión/desconexión real del Bluetooth
  Future<void> _toggleBluetoothConnection() async {
    final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);
    
    if (bluetoothProvider.isConnected) {
      // Si está conectado, desconectar realmente
      _logger.d('$_className: Desconectando dispositivo Bluetooth');
      await bluetoothProvider.disconnectDevice();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bluetooth desconectado'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } else if (bluetoothProvider.connectedDeviceAddress != null) {
      // Si está desconectado pero tenemos la dirección del último dispositivo, reconectar
      _logger.d('$_className: Intentando reconectar al último dispositivo');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Intentando reconectar...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 1),
          ),
        );
      }
      
      // Intentar reconectar al último dispositivo
      try {
        final reconnected = await bluetoothProvider.reconnectLastDevice();
        
        if (mounted) {
          if (reconnected) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Reconectado exitosamente'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 1),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo reconectar. Intente desde la pantalla de escaneo.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        _logger.e('$_className: Error al reconectar: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  /// Navega a la pantalla de inicio
  void _navigateToHome() {
    _logger.d('$_className: Navegando a la pantalla de inicio');
    Navigator.pushReplacementNamed(context, AppConstants.homeRoute);
  }
  
  /// Construye la lista de dispositivos encontrados
  Widget _buildDeviceList(BluetoothProvider bluetoothProvider) {
    if (bluetoothProvider.discoveredDevices.isEmpty) {
      return Center(
        child: bluetoothProvider.isScanning
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bluetooth_disabled,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 8),
                  const Text(
                    'Asegúrate de que el módulo esté encendido\ny en modo de emparejamiento (LED parpadeando)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Consejo: Reinicia el módulo si el LED\nno está parpadeando lentamente',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Icono grande de refrescar
                  InkWell(
                    onTap: () {
                      final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);
                      bluetoothProvider.startScan();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.refresh,
                        size: 60,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
      );
    }
    
    // Mostrar dispositivos encontrados
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: bluetoothProvider.discoveredDevices.length,
      itemBuilder: (context, index) {
        final device = bluetoothProvider.discoveredDevices[index];
        return BluetoothDeviceItem(
          device: device,
          onTap: () => _connectToDevice(device),
        );
      },
    );
  }
  
  /// Conecta a un dispositivo Bluetooth
  void _connectToDevice(BluetoothDevice device) async {
    _logger.d('$_className: Solicitando conexión a ${device.name}');
    
    final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Intentar conectar usando el provider
    final connection = await bluetoothProvider.connectToDevice(device);
    
    if (connection != null && mounted) {
      _logger.d('$_className: Conexión establecida con ${device.name}');
      
      // Guardar la conexión en AppState
      appState.setConnectedDevice(device, connection);
      
      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conectado a ${device.name ?? "dispositivo"}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      // Navegar a la pantalla de control
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppConstants.controlRoute);
      }
    } else if (mounted) {
      // Si hay un error, mostrar el mensaje que ya está en el provider
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bluetoothProvider.statusMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Ayuda',
            onPressed: () {
              _showResetInstructionsDialog();
            },
          ),
        ),
      );
    }
  }
  
  /// Muestra instrucciones para reiniciar un módulo HC-05
  void _showResetInstructionsDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cómo reiniciar el HC-05'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Opción 1: Reinicio rápido', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('1. Desconecta la alimentación del módulo'),
              Text('2. Espera 5 segundos'),
              Text('3. Vuelve a conectar la alimentación'),
              SizedBox(height: 12),
              
              Text('Opción 2: Reinicio completo', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('1. Desconecta la alimentación del módulo'),
              Text('2. Presiona y mantén el botón pequeño del HC-05'),
              Text('3. Mientras mantienes el botón, conecta la alimentación'),
              Text('4. Mantén el botón presionado por 5 segundos'),
              Text('5. Suelta el botón - el LED debe parpadear lentamente'),
              SizedBox(height: 12),
              
              Text('Opción 3: Retiro y nuevo emparejamiento', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('1. Ve a Configuración > Bluetooth de tu teléfono'),
              Text('2. Busca el HC-05 en la lista de dispositivos emparejados'),
              Text('3. Selecciona "Olvidar este dispositivo"'),
              Text('4. Reinicia el módulo HC-05'),
              Text('5. Empareja de nuevo (PIN: 1234 o 0000)'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

} 