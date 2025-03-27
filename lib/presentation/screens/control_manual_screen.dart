import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/logger_config.dart';
import '../../core/constants.dart';
import '../../state/bluetooth_provider.dart';

/// Pantalla para control manual de los motores
class ControlManualScreen extends StatefulWidget {
  /// Ruta nombrada para esta pantalla
  static const String routeName = AppConstants.manualControlRoute;
  
  const ControlManualScreen({super.key});

  @override
  State<ControlManualScreen> createState() => _ControlManualScreenState();
}

class _ControlManualScreenState extends State<ControlManualScreen> {
  static const _className = 'ControlManualScreen';
  final _logger = LoggerConfig.logger;
  
  // Buffer para almacenar datos recibidos
  final List<String> _receivedData = [];
  
  @override
  void initState() {
    super.initState();
    _logger.d('$_className: Inicializando pantalla de control manual');
    
    // Configurar el listener de datos después de que el widget esté construido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _setupDataListener();
      }
    });
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
  
  /// Envía un comando para control continuo de motor hacia adelante
  void _sendContinuousForward() {
    _sendCommand('CONT+F3200A2000');
  }
  
  /// Envía un comando para control continuo de motor hacia atrás
  void _sendContinuousBackward() {
    _sendCommand('CONT-F3200A2000');
  }
  
  /// Envía un comando para detener el motor
  void _sendStop() {
    _sendCommand('STOP');
  }
  
  @override
  Widget build(BuildContext context) {
    final bluetoothProvider = Provider.of<BluetoothProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control Manual'),
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
            
            // Controles de movimiento
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Botón para mover hacia atrás
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  ),
                  onPressed: bluetoothProvider.isConnected ? _sendContinuousBackward : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Atrás'),
                ),
                
                // Botón para detener
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  ),
                  onPressed: bluetoothProvider.isConnected ? _sendStop : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('STOP'),
                ),
                
                // Botón para mover hacia adelante
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  ),
                  onPressed: bluetoothProvider.isConnected ? _sendContinuousForward : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Adelante'),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Título para los datos recibidos
            const Text(
              'Datos recibidos:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 8),
            
            // Lista de datos recibidos
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: _receivedData.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay datos recibidos',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
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
            ),
          ],
        ),
      ),
    );
  }
} 