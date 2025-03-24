import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../core/logger_config.dart';
import '../../core/constants.dart';
import '../../state/bluetooth_provider.dart';
import '../widgets/common/custom_app_bar.dart';

/// Pantalla principal de control cuando el dispositivo está conectado
class ControlHomeScreen extends StatefulWidget {
  /// Ruta nombrada para esta pantalla
  static const String routeName = AppConstants.controlRoute;
  
  const ControlHomeScreen({super.key});

  @override
  State<ControlHomeScreen> createState() => _ControlHomeScreenState();
}

class _ControlHomeScreenState extends State<ControlHomeScreen> {
  static const _className = 'ControlHomeScreen';
  final _logger = LoggerConfig.logger;
  
  // Controlador para enviar comandos
  final TextEditingController _commandController = TextEditingController();
  
  // Buffer para almacenar datos recibidos
  final List<String> _receivedData = [];
  
  @override
  void initState() {
    super.initState();
    _logger.d('$_className: Inicializando pantalla de control');
    
    // Configurar el listener de datos después de que el widget esté construido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _setupDataListener();
      }
    });
  }
  
  @override
  void dispose() {
    _logger.d('$_className: Liberando recursos');
    
    // Liberar controlador de texto
    _commandController.dispose();
    
    _logger.d('$_className: Recursos liberados correctamente');
    super.dispose();
  }
  
  /// Configura un listener para los datos recibidos desde el BluetoothProvider
  void _setupDataListener() {
    _logger.d('$_className: Configurando listener para datos');
    
    try {
      final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);
      
      // Suscribirse al stream de datos
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
    if (command.isEmpty) {
      return;
    }
    
    try {
      final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);
      
      if (!bluetoothProvider.isConnected) {
        _logger.w('$_className: No hay conexión activa para enviar comandos');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay conexión activa'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      _logger.d('$_className: Enviando comando: $command');
      
      // Enviar el comando a través del provider
      bool success = await bluetoothProvider.sendCommand(command);
      
      if (success) {
        _logger.d('$_className: Comando enviado correctamente');
        
        // Limpiar el campo de texto
        _commandController.clear();
        
        // Registrar el comando enviado en la lista de datos
        if (mounted) {
          setState(() {
            _receivedData.add('>> $command');
          });
        }
      } else {
        _logger.e('$_className: Error al enviar comando');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al enviar el comando'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      _logger.e('$_className: Error al enviar comando: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Desconecta del dispositivo Bluetooth
  Future<void> _disconnectDevice() async {
    _logger.d('$_className: Iniciando desconexión del dispositivo');
    
    try {
      final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);
      
      // Desconectar utilizando el provider
      await bluetoothProvider.disconnectDevice();
      
      // Actualizar el estado local
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Desconectado del dispositivo'),
            backgroundColor: Colors.orange,
          ),
        );
        
        // Navegar a la pantalla anterior
        Future.microtask(() {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      _logger.e('$_className: Error al desconectar: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al desconectar: $e'),
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
      appBar: CustomAppBar(
        title: 'Control HC-05',
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth_disabled),
            tooltip: 'Desconectar',
            onPressed: _disconnectDevice,
          ),
        ],
      ),
      body: _buildBody(bluetoothProvider),
    );
  }
  
  /// Construye el cuerpo principal de la pantalla
  Widget _buildBody(BluetoothProvider bluetoothProvider) {
    return Column(
      children: [
        _buildStatusBar(bluetoothProvider),
        Expanded(
          child: _buildDataView(),
        ),
        _buildCommandInput(bluetoothProvider),
      ],
    );
  }
  
  /// Construye la barra de estado de conexión
  Widget _buildStatusBar(BluetoothProvider bluetoothProvider) {
    Color statusColor = bluetoothProvider.isConnected ? Colors.green : Colors.red;
    String statusMessage = bluetoothProvider.isConnected 
        ? 'Conectado a ${bluetoothProvider.connectedDeviceName ?? "dispositivo"}'
        : 'Sin conexión';
    
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: statusColor.withAlpha(25),
      child: Row(
        children: [
          Icon(
            bluetoothProvider.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
            color: statusColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusMessage,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Construye la vista de datos recibidos
  Widget _buildDataView() {
    if (_receivedData.isEmpty) {
      return const Center(
        child: Text(
          'Esperando datos del dispositivo...',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        itemCount: _receivedData.length,
        itemBuilder: (context, index) {
          return Card(
            color: Colors.blue.withAlpha(25),
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _receivedData[index],
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          );
        },
      ),
    );
  }
  
  /// Construye el campo para enviar comandos
  Widget _buildCommandInput(BluetoothProvider bluetoothProvider) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.withAlpha(128)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commandController,
              decoration: const InputDecoration(
                hintText: 'Escribe un comando...',
                border: OutlineInputBorder(),
              ),
              enabled: bluetoothProvider.isConnected,
              onSubmitted: _sendCommand,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: bluetoothProvider.isConnected
                ? () => _sendCommand(_commandController.text)
                : null,
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }
} 