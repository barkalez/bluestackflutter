import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/logger_config.dart';
import '../../core/constants.dart';
import '../../state/bluetooth_provider.dart';

/// Pantalla para configurar el apilado automático
class StackConfigScreen extends StatefulWidget {
  /// Ruta nombrada para esta pantalla
  static const String routeName = AppConstants.stackConfigRoute;
  
  const StackConfigScreen({super.key});

  @override
  State<StackConfigScreen> createState() => _StackConfigScreenState();
}

class _StackConfigScreenState extends State<StackConfigScreen> {
  static const _className = 'StackConfigScreen';
  final _logger = LoggerConfig.logger;
  
  // Controladores para campos de texto
  final TextEditingController _columnCountController = TextEditingController(text: '3');
  final TextEditingController _rowCountController = TextEditingController(text: '3');
  final TextEditingController _stackHeightController = TextEditingController(text: '10');
  final TextEditingController _spacingController = TextEditingController(text: '5');
  
  // Buffer para almacenar datos recibidos
  final List<String> _receivedData = [];
  
  @override
  void initState() {
    super.initState();
    _logger.d('$_className: Inicializando pantalla de configuración de apilado');
    
    // Configurar el listener de datos después de que el widget esté construido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _setupDataListener();
      }
    });
  }
  
  @override
  void dispose() {
    _columnCountController.dispose();
    _rowCountController.dispose();
    _stackHeightController.dispose();
    _spacingController.dispose();
    super.dispose();
  }
  
  /// Configura un listener para los datos recibidos
  void _setupDataListener() {
    _logger.d('$_className: Configurando listener para datos');
    
    try {
      final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);
      
      bluetoothProvider.dataStream.listen(
        (String data) {
          _logger.d('$_className: Datos recibidos: $data');
          
          if (mounted) {
            setState(() {
              _receivedData.add(data);
              // Limitar el tamaño del buffer
              if (_receivedData.length > 100) {
                _receivedData.removeAt(0);
              }
            });
          }
        },
        onError: (error) {
          _logger.e('$_className: Error al recibir datos: $error');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error en la conexión: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
      
      _logger.d('$_className: Listener configurado correctamente');
    } catch (e) {
      _logger.e('$_className: Error al configurar listener: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al monitorear datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Envía un comando al dispositivo Bluetooth
  Future<void> _sendCommand(String command) async {
    _logger.d('$_className: Preparando para enviar comando: $command');
    
    try {
      final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);
      
      if (!bluetoothProvider.isConnected) {
        _logger.w('$_className: No hay conexión activa');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay conexión Bluetooth activa'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      // Asegurar que el comando termine con '\n'
      if (!command.endsWith('\n')) {
        command = '$command\n';
      }
      
      // Enviar comando
      final success = await bluetoothProvider.sendCommand(command);
      
      if (success) {
        _logger.d('$_className: Comando enviado: $command');
      } else {
        _logger.e('$_className: Error al enviar comando');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al enviar comando'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      _logger.e('$_className: Excepción al enviar comando: $e');
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
  
  /// Maneja la conexión/desconexión del Bluetooth
  Future<void> _toggleBluetoothConnection() async {
    final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);
    
    if (bluetoothProvider.isConnected) {
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
        
        // Volver a la pantalla anterior
        Navigator.pop(context);
      }
    }
  }
  
  /// Inicia el proceso de apilado con los parámetros configurados
  void _startStacking() {
    try {
      final columns = int.parse(_columnCountController.text);
      final rows = int.parse(_rowCountController.text);
      final height = int.parse(_stackHeightController.text);
      final spacing = int.parse(_spacingController.text);
      
      // Comando personalizado para configurar el apilado
      final command = 'STACK C$columns R$rows H$height S$spacing';
      
      _sendCommand(command);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Iniciando proceso de apilado...'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _logger.e('$_className: Error al parsear valores de configuración: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Revise los valores ingresados'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final bluetoothProvider = Provider.of<BluetoothProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Apilado'),
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
        actions: [
          // Botón de Bluetooth
          Padding(
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
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Información de conexión
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dispositivo: ${bluetoothProvider.connectedDeviceName ?? "No conectado"}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 12,
                          color: bluetoothProvider.isConnected ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          bluetoothProvider.isConnected ? 'Conectado' : 'Desconectado',
                          style: TextStyle(
                            color: bluetoothProvider.isConnected ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Configuración de apilado
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuración de Apilado',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    // Número de columnas
                    const Text('Número de columnas:'),
                    TextField(
                      controller: _columnCountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Ej: 3',
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Número de filas
                    const Text('Número de filas:'),
                    TextField(
                      controller: _rowCountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Ej: 3',
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Altura de apilado
                    const Text('Altura de apilado (mm):'),
                    TextField(
                      controller: _stackHeightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Ej: 10',
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Espaciado
                    const Text('Espaciado entre piezas (mm):'),
                    TextField(
                      controller: _spacingController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Ej: 5',
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Botón para iniciar apilado
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: bluetoothProvider.isConnected ? _startStacking : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('INICIAR APILADO', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Visualización de respuestas
                    if (_receivedData.isNotEmpty) ...[
                      const Text(
                        'Respuestas del dispositivo:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: ListView.builder(
                          itemCount: _receivedData.length,
                          itemBuilder: (context, index) {
                            final data = _receivedData[_receivedData.length - 1 - index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                '> $data',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 