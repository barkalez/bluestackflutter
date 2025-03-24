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
    final appState = Provider.of<AppState>(context);
    final bluetoothProvider = Provider.of<BluetoothProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conectar dispositivo Bluetooth'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
            onPressed: () => bluetoothProvider.startScan(),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Ayuda',
            onPressed: () => _showHelpDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicador de estado
          _buildStatusIndicator(bluetoothProvider),
          
          // Sección de dispositivos recientes
          if (appState.recentDevices.isNotEmpty) 
            _buildRecentDevicesSection(appState, bluetoothProvider),
          
          // Lista de dispositivos encontrados
          Expanded(
            child: _buildDeviceList(bluetoothProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: bluetoothProvider.isScanning 
            ? bluetoothProvider.stopScan 
            : bluetoothProvider.startScan,
        tooltip: bluetoothProvider.isScanning 
            ? 'Detener escaneo' 
            : 'Iniciar escaneo',
        child: Icon(bluetoothProvider.isScanning 
            ? Icons.stop 
            : Icons.bluetooth_searching),
      ),
    );
  }
  
  /// Construye el indicador de estado de la búsqueda
  Widget _buildStatusIndicator(BluetoothProvider bluetoothProvider) {
    final hasBlueStackDevice = bluetoothProvider.discoveredDevices.isNotEmpty;
    
    String statusText;
    Color? statusColor;
    
    if (bluetoothProvider.isScanning) {
      statusText = 'Buscando módulos BlueStack/HC-05...';
      statusColor = Colors.blue;
    } else if (bluetoothProvider.discoveredDevices.isEmpty) {
      statusText = 'No se encontraron módulos BlueStack/HC-05';
      statusColor = null;
    } else if (hasBlueStackDevice) {
      statusText = 'Módulo BlueStack/HC-05 encontrado';
      statusColor = Colors.green;
    } else {
      statusText = 'No se encontraron módulos compatibles';
      statusColor = Colors.orange;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: bluetoothProvider.isScanning ? Colors.blue.withAlpha(25) : Colors.transparent,
      child: Row(
        children: [
          bluetoothProvider.isScanning
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  hasBlueStackDevice 
                      ? Icons.bluetooth_connected 
                      : (bluetoothProvider.discoveredDevices.isEmpty 
                          ? Icons.bluetooth_disabled 
                          : Icons.bluetooth_searching),
                  color: hasBlueStackDevice 
                      ? Colors.green 
                      : (bluetoothProvider.discoveredDevices.isEmpty 
                          ? Colors.grey 
                          : Colors.orange),
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
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
                  SizedBox(height: 24),
                  Text(
                    'Buscando módulos BlueStack/HC-05...',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Asegúrate de que el módulo esté encendido y visible',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
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
                  const Text(
                    'No se encontraron módulos BlueStack/HC-05',
                    style: TextStyle(fontSize: 18),
                  ),
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
  
  /// Construye la sección de dispositivos recientes
  Widget _buildRecentDevicesSection(AppState appState, BluetoothProvider bluetoothProvider) {
    final recentDevices = appState.getRecentDevicesInfo();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              const Text(
                'Dispositivos recientes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  appState.clearRecentDevices();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 36),
                ),
                child: const Text('Limpiar'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentDevices.length,
          itemBuilder: (context, index) {
            final device = recentDevices[index];
            return ListTile(
              leading: const Icon(Icons.history, color: Colors.grey),
              title: Text(device['name'] ?? 'Dispositivo desconocido'),
              subtitle: Text(device['address'] ?? ''),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.settings_bluetooth, color: Colors.blue),
                    onPressed: () => bluetoothProvider.openBluetoothSettings(),
                    tooltip: 'Emparejar',
                  ),
                  IconButton(
                    icon: const Icon(Icons.bluetooth, color: Colors.blue),
                    onPressed: () => _connectToRecentDevice(device),
                    tooltip: 'Conectar',
                  ),
                ],
              ),
              onTap: () => _connectToRecentDevice(device),
            );
          },
        ),
        const Divider(height: 1),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            'Dispositivos encontrados',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
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
      
      // Guardar dispositivo en recientes
      appState.addRecentDevice(
        device.name ?? 'Dispositivo desconocido', 
        device.address
      );
      
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
  
  /// Conecta a un dispositivo reciente
  void _connectToRecentDevice(Map<String, String?> device) {
    _logger.d('$_className: Intentando conectar a dispositivo reciente: ${device['name']}');
    // Crear un BluetoothDevice a partir de la información guardada
    final bluetoothDevice = BluetoothDevice(
      name: device['name'],
      address: device['address'] ?? '',
    );
    _connectToDevice(bluetoothDevice);
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

  /// Muestra un diálogo de ayuda con información sobre el HC-05
  void _showHelpDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Guía para conectar HC-05'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Preparación del módulo HC-05:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Asegúrese de que el módulo HC-05 esté correctamente alimentado.'),
              Text('2. El LED del módulo debe parpadear (aproximadamente cada 2 segundos).'),
              Text('3. Si el LED está encendido constantemente, el módulo ya está emparejado con otro dispositivo.'),
              SizedBox(height: 16),
              Text(
                'Emparejamiento:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. El HC-05 debe aparecer en la lista de dispositivos escaneados.'),
              Text('2. Si no aparece, intente apagar y encender el módulo.'),
              Text('3. Al seleccionar el dispositivo, se le pedirá emparejarlo.'),
              Text('4. El PIN típico para HC-05 es 1234 o 0000.'),
              SizedBox(height: 16),
              Text(
                'Encontrar la dirección MAC:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Vaya a la configuración Bluetooth de su dispositivo.'),
              Text('2. Busque el dispositivo HC-05 en la lista de dispositivos emparejados.'),
              Text('3. En la mayoría de los dispositivos Android, puede ver la dirección MAC presionando sobre el nombre del dispositivo y seleccionando "Información del dispositivo" o "Propiedades".'),
              Text('4. La dirección MAC tiene el formato XX:XX:XX:XX:XX:XX.'),
              SizedBox(height: 16),
              Text(
                'Resolución de problemas:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Si no puede ver el HC-05, reinicie el módulo.'),
              Text('• Si falla la conexión, verifique que el módulo esté en modo comunicación (LED parpadeando).'),
              Text('• Asegúrese de tener habilitados los permisos de ubicación y Bluetooth.'),
              Text('• Si persisten los problemas, puede ser necesario reiniciar el adaptador Bluetooth de su dispositivo.'),
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