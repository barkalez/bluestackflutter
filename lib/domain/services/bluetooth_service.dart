import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../core/logger_config.dart';

/// Servicio que maneja las operaciones de Bluetooth
class BluetoothService {
  static const _className = 'BluetoothService';
  final _logger = LoggerConfig.logger;
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  
  /// Verifica si el Bluetooth está habilitado
  Future<bool> isBluetoothEnabled() async {
    try {
      return await _bluetooth.isEnabled ?? false;
    } catch (e) {
      _logger.e('$_className: Error al verificar si el Bluetooth está habilitado: $e');
      return false;
    }
  }
  
  /// Solicita activar el Bluetooth
  Future<bool> requestEnableBluetooth() async {
    try {
      return await _bluetooth.requestEnable() ?? false;
    } catch (e) {
      _logger.e('$_className: Error al solicitar activación de Bluetooth: $e');
      return false;
    }
  }
  
  /// Obtiene el estado actual del Bluetooth
  Future<BluetoothState> getBluetoothState() async {
    try {
      return await _bluetooth.state;
    } catch (e) {
      _logger.e('$_className: Error al obtener estado de Bluetooth: $e');
      return BluetoothState.ERROR;
    }
  }
  
  /// Inicia el descubrimiento de dispositivos Bluetooth
  Stream<BluetoothDiscoveryResult> startDiscovery() {
    _logger.d('$_className: Iniciando descubrimiento de dispositivos');
    return _bluetooth.startDiscovery();
  }
  
  /// Cancela el descubrimiento de dispositivos Bluetooth
  Future<void> cancelDiscovery() async {
    try {
      await _bluetooth.cancelDiscovery();
      _logger.d('$_className: Descubrimiento cancelado correctamente');
    } catch (e) {
      _logger.e('$_className: Error al cancelar descubrimiento: $e');
    }
  }
  
  /// Verifica si el dispositivo está emparejado
  Future<bool> isDeviceBonded(String address) async {
    try {
      final bondState = await _bluetooth.getBondStateForAddress(address);
      return bondState == BluetoothBondState.bonded;
    } catch (e) {
      _logger.e('$_className: Error al verificar estado de emparejamiento: $e');
      return false;
    }
  }
  
  /// Intenta emparejar con un dispositivo Bluetooth
  Future<bool> bondDevice(String address) async {
    try {
      return await _bluetooth.bondDeviceAtAddress(address) ?? false;
    } catch (e) {
      _logger.e('$_className: Error durante el emparejamiento: $e');
      return false;
    }
  }
  
  /// Abre la configuración de Bluetooth
  Future<void> openBluetoothSettings() async {
    try {
      await _bluetooth.openSettings();
      _logger.d('$_className: Configuración Bluetooth abierta');
    } catch (e) {
      _logger.e('$_className: Error al abrir configuración Bluetooth: $e');
    }
  }
  
  /// Establece una conexión con un dispositivo Bluetooth
  Future<BluetoothConnection> connectToDevice(String address) async {
    _logger.d('$_className: Estableciendo conexión con $address');
    return BluetoothConnection.toAddress(address);
  }
  
  /// Verifica si el HC-05 responde correctamente
  Future<bool> verifyHC05Connection(BluetoothConnection connection) async {
    _logger.d('$_className: Verificando conexión con HC-05...');
    try {
      // Enviar comando AT de prueba
      String command = "AT\r\n";
      connection.output.add(Uint8List.fromList(utf8.encode(command)));
      await connection.output.allSent;
      _logger.d('$_className: Comando AT enviado, esperando respuesta...');
      
      // Esperar respuesta con timeout
      Completer<bool> responseCompleter = Completer<bool>();
      
      // Establecer un timeout
      Timer(const Duration(seconds: 2), () {
        if (!responseCompleter.isCompleted) {
          _logger.w('$_className: Timeout esperando respuesta del HC-05');
          responseCompleter.complete(false);
        }
      });
      
      // Configurar listener para la respuesta
      StreamSubscription<Uint8List>? subscription;
      subscription = connection.input?.listen((data) {
        String response = utf8.decode(data);
        _logger.d('$_className: Respuesta del HC-05: $response');
        
        if (response.contains("OK") || response.isNotEmpty) {
          _logger.d('$_className: HC-05 respondió correctamente');
          if (!responseCompleter.isCompleted) {
            responseCompleter.complete(true);
          }
        }
        
        subscription?.cancel();
      });
      
      return await responseCompleter.future;
    } catch (e) {
      _logger.e('$_className: Error verificando conexión con HC-05: $e');
      return false;
    }
  }
  
  /// Determina si un dispositivo es un HC-05 basado en su nombre
  bool isHC05Device(BluetoothDevice device) {
    final name = device.name?.toLowerCase() ?? "";
    return name.contains("stackblue") ||
           name.contains("stack") ||
           name.contains("blue") ||
           name.contains("hc-05") ||
           name.contains("hc05");
  }
  
  /// Envía un comando AT al HC-05 y espera respuesta
  Future<String> sendCommand(BluetoothConnection connection, String command) async {
    try {
      _logger.d('$_className: Enviando comando: $command');
      
      // Asegurar que el comando termina con retorno de carro y nueva línea (CRLF)
      if (!command.endsWith('\r\n')) {
        command = '$command\r\n';
      }
      
      // Convertir y enviar el comando
      connection.output.add(Uint8List.fromList(utf8.encode(command)));
      await connection.output.allSent;
      
      // Esperar respuesta con timeout
      Completer<String> responseCompleter = Completer<String>();
      
      // Establecer un timeout
      Timer(const Duration(seconds: 3), () {
        if (!responseCompleter.isCompleted) {
          _logger.w('$_className: Timeout esperando respuesta al comando: $command');
          responseCompleter.complete('');
        }
      });
      
      // Configurar listener para la respuesta
      StreamSubscription<Uint8List>? subscription;
      subscription = connection.input?.listen((data) {
        String response = utf8.decode(data, allowMalformed: true);
        _logger.d('$_className: Respuesta recibida: $response');
        
        if (!responseCompleter.isCompleted) {
          responseCompleter.complete(response);
        }
        
        subscription?.cancel();
      });
      
      return await responseCompleter.future;
    } catch (e) {
      _logger.e('$_className: Error al enviar comando: $e');
      return '';
    }
  }
  
  /// Desconecta una conexión Bluetooth
  Future<void> disconnectDevice(BluetoothConnection connection) async {
    _logger.d('$_className: Desconectando dispositivo');
    
    try {
      if (connection.isConnected) {
        await connection.finish();
        _logger.d('$_className: Conexión finalizada correctamente');
      } else {
        _logger.d('$_className: La conexión ya estaba cerrada');
      }
    } catch (e) {
      _logger.e('$_className: Error al desconectar: $e');
    }
  }
  
  /// Obtiene información sobre los dispositivos emparejados
  Future<List<BluetoothDevice>> getBondedDevices() async {
    try {
      _logger.d('$_className: Obteniendo dispositivos emparejados');
      return await _bluetooth.getBondedDevices();
    } catch (e) {
      _logger.e('$_className: Error al obtener dispositivos emparejados: $e');
      return [];
    }
  }
} 