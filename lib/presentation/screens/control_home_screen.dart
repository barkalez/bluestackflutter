import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../core/logger_config.dart';
import '../../core/constants.dart';
import '../../state/app_state.dart';
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
  
  BluetoothConnection? _connection;
  bool _isConnected = false;
  String _statusMessage = 'Esperando datos...';
  StreamSubscription<Uint8List>? _dataSubscription;
  
  // Stream transformado para permitir múltiples listeners
  Stream<Uint8List>? _inputStream;
  
  // Controlador para enviar comandos
  final TextEditingController _commandController = TextEditingController();
  
  // Buffer para almacenar datos recibidos
  final List<String> _receivedData = [];
  
  @override
  void initState() {
    super.initState();
    _logger.d('$_className: Inicializando pantalla de control');
    _initializeConnection();
  }
  
  @override
  void dispose() {
    _logger.d('$_className: Liberando recursos');
    
    // Cancelar suscripción a datos
    if (_dataSubscription != null) {
      _dataSubscription!.cancel();
      _dataSubscription = null;
      _logger.d('$_className: Suscripción de datos cancelada en dispose');
    }
    
    // Limpiar referencia al stream
    _inputStream = null;
    
    // No cerramos la conexión aquí para permitir que persista si se usa en otra pantalla
    // (la gestión de la conexión se hace a través de AppState)
    
    // Liberar controlador de texto
    _commandController.dispose();
    
    _logger.d('$_className: Recursos liberados correctamente');
    super.dispose();
  }
  
  /// Inicializa la conexión Bluetooth
  void _initializeConnection() {
    _logger.d('$_className: Inicializando conexión Bluetooth');
    
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      
      if (!appState.isConnected) {
        _logger.w('$_className: No hay dispositivo conectado');
        setState(() {
          _statusMessage = 'No hay dispositivo conectado';
          _isConnected = false;
        });
        return;
      }
      
      _connection = appState.connection;
      
      if (_connection != null && _connection!.isConnected) {
        _logger.d('$_className: Conexión Bluetooth existente encontrada');
        
        // Configurar el stream de entrada
        _setupInputStream();
        
        setState(() {
          _isConnected = true;
          _statusMessage = 'Conectado a ${appState.connectedDeviceName}';
        });
        
        // Configurar la escucha de datos recibidos después de configurar el stream
        _setupDataListener();
      } else {
        _logger.w('$_className: La conexión no está activa');
        setState(() {
          _statusMessage = 'La conexión no está activa';
          _isConnected = false;
        });
      }
    } catch (e) {
      _logger.e('$_className: Error al inicializar conexión: $e');
      setState(() {
        _statusMessage = 'Error al inicializar conexión: $e';
        _isConnected = false;
      });
    }
  }
  
  /// Configura el stream de entrada para permitir múltiples listeners
  void _setupInputStream() {
    _logger.d('$_className: Configurando stream de entrada');
    
    try {
      if (_connection == null || _connection!.input == null) {
        _logger.w('$_className: No hay conexión o stream de entrada disponible');
        return;
      }
      
      // Cancelar suscripción anterior si existe antes de crear un nuevo stream
      if (_dataSubscription != null) {
        _dataSubscription!.cancel();
        _dataSubscription = null;
        _logger.d('$_className: Suscripción anterior cancelada antes de crear nuevo stream');
      }
      
      // Crear un nuevo broadcast stream solo si no existe
      if (_inputStream == null) {
        _inputStream = _connection!.input!.asBroadcastStream();
        _logger.d('$_className: Stream de entrada configurado como broadcast');
      }
    } catch (e) {
      _logger.e('$_className: Error al configurar stream de entrada: $e');
    }
  }
  
  /// Configura un listener para los datos recibidos
  void _setupDataListener() {
    _logger.d('$_className: Configurando listener para datos');
    
    // Cancelar suscripción anterior si existe
    if (_dataSubscription != null) {
      _dataSubscription!.cancel();
      _dataSubscription = null;
      _logger.d('$_className: Suscripción anterior cancelada');
    }
    
    try {
      // Verificar si el inputStream está disponible
      if (_inputStream == null) {
        _logger.w('$_className: No hay stream de entrada disponible. Configurando stream primero.');
        _setupInputStream();
        
        if (_inputStream == null) {
          _logger.e('$_className: No se pudo configurar el stream de entrada');
          return;
        }
      }
      
      // Suscribirse al stream (ahora broadcast)
      _dataSubscription = _inputStream!.listen(
        (Uint8List data) {
          // Decodificar datos recibidos
          String dataString = utf8.decode(data, allowMalformed: true);
          _logger.d('$_className: Datos recibidos: $dataString');
          
          if (mounted) {
            setState(() {
              _receivedData.add(dataString);
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
            setState(() {
              _statusMessage = 'Error en la conexión: $error';
              _isConnected = false;
            });
          }
        },
        onDone: () {
          _logger.w('$_className: Conexión cerrada remotamente');
          if (mounted) {
            setState(() {
              _statusMessage = 'Conexión cerrada por el dispositivo remoto';
              _isConnected = false;
            });
          }
        },
      );
      
      _logger.d('$_className: Listener configurado correctamente');
    } catch (e) {
      _logger.e('$_className: Error al configurar listener: $e');
      if (mounted) {
        setState(() {
          _statusMessage = 'Error al monitorear datos: $e';
        });
      }
    }
  }
  
  /// Envía un comando al dispositivo Bluetooth
  Future<void> _sendCommand(String command) async {
    if (!_isConnected || _connection == null) {
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
    
    if (command.isEmpty) {
      return;
    }
    
    try {
      _logger.d('$_className: Enviando comando: $command');
      
      // Asegurar que el comando termine con retorno de carro y nueva línea para HC-05
      if (!command.endsWith('\r\n')) {
        command = '$command\r\n';
      }
      
      // Convertir a bytes y enviar
      Uint8List data = Uint8List.fromList(utf8.encode(command));
      
      // Verificar que la conexión sigue activa
      if (!_connection!.isConnected) {
        _logger.e('$_className: Conexión no activa al intentar enviar datos');
        if (mounted) {
          setState(() {
            _isConnected = false;
            _statusMessage = 'Conexión perdida';
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conexión perdida. No se pueden enviar datos.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Enviar los datos
      _connection!.output.add(data);
      await _connection!.output.allSent;
      
      _logger.d('$_className: Comando enviado correctamente');
      
      // Limpiar el campo de texto
      _commandController.clear();
      
      // Registrar el comando enviado en la lista de datos
      if (mounted) {
        setState(() {
          _receivedData.add('>> $command');
        });
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
        
        // Actualizar estado si la conexión se perdió
        if (e.toString().contains('closed') || 
            e.toString().contains('disconnected') ||
            e.toString().contains('not connected')) {
          setState(() {
            _isConnected = false;
            _statusMessage = 'Conexión cerrada';
          });
        }
      }
    }
  }
  
  /// Desconecta del dispositivo Bluetooth
  Future<void> _disconnectDevice() async {
    _logger.d('$_className: Iniciando desconexión del dispositivo');
    
    try {
      // Cancelar la suscripción de datos
      if (_dataSubscription != null) {
        await _dataSubscription!.cancel();
        _dataSubscription = null;
        _logger.d('$_className: Suscripción de datos cancelada');
      }
      
      // Limpiar referencia al stream de entrada
      _inputStream = null;
      _logger.d('$_className: Referencia al stream de entrada limpiada');
      
      // Cerrar conexión
      if (_connection != null) {
        try {
          if (_connection!.isConnected) {
            await _connection!.finish();  // Más seguro que close() para liberar recursos
            _logger.d('$_className: Conexión cerrada correctamente');
          } else {
            _logger.d('$_className: La conexión ya estaba cerrada');
          }
        } catch (closeError) {
          _logger.e('$_className: Error al cerrar la conexión: $closeError');
          // Continuar con la desconexión incluso si hay un error al cerrar
        }
        _connection = null;
      }
      
      // Actualizar el estado global de la aplicación
      if (mounted) {
        try {
          final appState = Provider.of<AppState>(context, listen: false);
          appState.disconnectFromDevice();
          _logger.d('$_className: Estado global de la aplicación actualizado');
        } catch (stateError) {
          _logger.e('$_className: Error al actualizar estado global: $stateError');
        }
      }
      
      // Actualizar el estado local
      if (mounted) {
        setState(() {
          _isConnected = false;
          _statusMessage = 'Desconectado';
        });
        
        // Mostrar mensaje al usuario
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
      body: _buildBody(),
    );
  }
  
  /// Construye el cuerpo principal de la pantalla
  Widget _buildBody() {
    return Column(
      children: [
        _buildStatusBar(),
        Expanded(
          child: _buildDataView(),
        ),
        _buildCommandInput(),
      ],
    );
  }
  
  /// Construye la barra de estado de conexión
  Widget _buildStatusBar() {
    Color statusColor = _isConnected ? Colors.green : Colors.red;
    
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: statusColor.withAlpha(25),
      child: Row(
        children: [
          Icon(
            _isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
            color: statusColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _statusMessage,
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
  Widget _buildCommandInput() {
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
              enabled: _isConnected,
              onSubmitted: _sendCommand,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _isConnected
                ? () => _sendCommand(_commandController.text)
                : null,
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }
} 