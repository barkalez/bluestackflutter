import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../domain/services/bluetooth_service.dart';
import '../domain/services/permission_service.dart';
import '../core/logger_config.dart';
import 'dart:async';
import 'dart:convert';

/// Provider que gestiona el estado del Bluetooth en toda la aplicación
class BluetoothProvider with ChangeNotifier {
  static const _className = 'BluetoothProvider';
  final _logger = LoggerConfig.logger;
  
  // Servicios
  final _bluetoothService = BluetoothService();
  final _permissionService = PermissionService();
  
  // Estado
  List<BluetoothDevice> _discoveredDevices = [];
  bool _isScanning = false;
  bool _hasPermissions = false;
  bool _isBluetoothEnabled = false;
  String _statusMessage = '';
  BluetoothDevice? _connectingDevice;
  StreamSubscription<BluetoothDiscoveryResult>? _discoverySubscription;
  
  // Estado de conexión
  bool _isConnected = false;
  BluetoothDevice? _connectedDevice;
  BluetoothConnection? _connection;
  StreamSubscription<Uint8List>? _dataSubscription;
  
  // Stream para datos recibidos 
  final _dataStreamController = StreamController<String>.broadcast();
  
  // Getters
  List<BluetoothDevice> get discoveredDevices => _discoveredDevices;
  bool get isScanning => _isScanning;
  bool get hasPermissions => _hasPermissions;
  bool get isBluetoothEnabled => _isBluetoothEnabled;
  String get statusMessage => _statusMessage;
  BluetoothDevice? get connectingDevice => _connectingDevice;
  bool get isConnected => _isConnected;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  String? get connectedDeviceName => _connectedDevice?.name;
  String? get connectedDeviceAddress => _connectedDevice?.address;
  Stream<String> get dataStream => _dataStreamController.stream;
  
  /// Constructor
  BluetoothProvider() {
    _init();
  }
  
  /// Inicialización del provider
  Future<void> _init() async {
    _logger.d('$_className: Inicializando BluetoothProvider');
    await _checkBluetoothState();
  }
  
  /// Verifica si los permisos están concedidos
  Future<bool> checkAndRequestPermissions() async {
    _logger.d('$_className: Verificando permisos');
    
    final permissionsGranted = await _permissionService.requestBluetoothPermissions();
    _hasPermissions = permissionsGranted;
    
    if (!_hasPermissions) {
      _statusMessage = 'Se requieren permisos de Bluetooth y ubicación';
      notifyListeners();
    }
    
    return _hasPermissions;
  }
  
  /// Verifica el estado del Bluetooth
  Future<void> _checkBluetoothState() async {
    _logger.d('$_className: Verificando estado del Bluetooth');
    
    try {
      final state = await _bluetoothService.getBluetoothState();
      _isBluetoothEnabled = state == BluetoothState.STATE_ON;
      
      if (!_isBluetoothEnabled) {
        _statusMessage = 'Bluetooth está desactivado';
      } else {
        _statusMessage = 'Bluetooth está activo';
        await checkAndRequestPermissions();
      }
      
      notifyListeners();
    } catch (e) {
      _logger.e('$_className: Error al verificar estado del Bluetooth: $e');
      _statusMessage = 'Error al verificar estado del Bluetooth';
      notifyListeners();
    }
  }
  
  /// Solicita la activación del Bluetooth
  Future<bool> requestEnableBluetooth() async {
    _logger.d('$_className: Solicitando activación del Bluetooth');
    
    try {
      final result = await _bluetoothService.requestEnableBluetooth();
      if (result) {
        _isBluetoothEnabled = true;
        _statusMessage = 'Bluetooth activado';
        await checkAndRequestPermissions();
      } else {
        _statusMessage = 'El usuario no activó el Bluetooth';
      }
      
      notifyListeners();
      return result;
    } catch (e) {
      _logger.e('$_className: Error al solicitar activación del Bluetooth: $e');
      _statusMessage = 'Error al activar Bluetooth';
      notifyListeners();
      return false;
    }
  }
  
  /// Inicia el escaneo de dispositivos Bluetooth
  Future<void> startScan() async {
    _logger.d('$_className: Iniciando escaneo de dispositivos');
    
    if (_isScanning) {
      _logger.d('$_className: Ya se está realizando un escaneo');
      return;
    }
    
    // Verificar permisos y estado del Bluetooth
    if (!_hasPermissions) {
      final permissionsGranted = await checkAndRequestPermissions();
      if (!permissionsGranted) {
        return;
      }
    }
    
    if (!_isBluetoothEnabled) {
      final enabled = await requestEnableBluetooth();
      if (!enabled) {
        return;
      }
    }
    
    // Limpiar lista de dispositivos
    _discoveredDevices = [];
    _isScanning = true;
    _statusMessage = 'Buscando dispositivos...';
    notifyListeners();
    
    // Cancelar suscripción anterior si existe
    await _cancelDiscovery();
    
    try {
      _discoverySubscription = _bluetoothService.startDiscovery().listen(
        (result) {
          // Procesar dispositivo encontrado
          _processDiscoveryResult(result);
        },
        onDone: () {
          _logger.d('$_className: Escaneo completado');
          _isScanning = false;
          _statusMessage = _discoveredDevices.isEmpty
              ? 'No se encontraron dispositivos' 
              : 'Dispositivos encontrados: ${_discoveredDevices.length}';
          notifyListeners();
        },
        onError: (error) {
          _logger.e('$_className: Error durante el escaneo: $error');
          _isScanning = false;
          _statusMessage = 'Error durante el escaneo: $error';
          notifyListeners();
        },
        cancelOnError: false,
      );
      
      // Detener el escaneo después de un tiempo
      Timer(const Duration(seconds: 30), () {
        if (_isScanning) {
          stopScan();
        }
      });
    } catch (e) {
      _logger.e('$_className: Error al iniciar el escaneo: $e');
      _isScanning = false;
      _statusMessage = 'Error al iniciar el escaneo';
      notifyListeners();
    }
  }
  
  /// Procesa un resultado del descubrimiento
  void _processDiscoveryResult(BluetoothDiscoveryResult result) {
    final device = result.device;
    _logger.d('$_className: Dispositivo encontrado: ${device.name ?? "Sin nombre"} - ${device.address}');
    
    // Verificar si el dispositivo ya está en la lista
    bool deviceExists = _discoveredDevices.any((d) => d.address == device.address);
    
    if (deviceExists) {
      return; // No agregar dispositivos duplicados
    }
    
    // Solo mostrar dispositivos HC-05
    if (_bluetoothService.isHC05Device(device)) {
      _logger.d('$_className: Dispositivo HC-05 encontrado: ${device.name}');
      _discoveredDevices.add(device);
      notifyListeners();
    } else {
      _logger.d('$_className: Ignorando dispositivo no HC-05: ${device.name}');
    }
  }
  
  /// Detiene el escaneo de dispositivos
  Future<void> stopScan() async {
    _logger.d('$_className: Deteniendo escaneo');
    
    if (!_isScanning) return;
    
    await _cancelDiscovery();
    
    _isScanning = false;
    _statusMessage = _discoveredDevices.isEmpty 
        ? 'No se encontraron dispositivos' 
        : 'Dispositivos encontrados: ${_discoveredDevices.length}';
    notifyListeners();
  }
  
  /// Cancela el descubrimiento en curso
  Future<void> _cancelDiscovery() async {
    try {
      if (_discoverySubscription != null) {
        await _discoverySubscription!.cancel();
        _discoverySubscription = null;
      }
      
      await _bluetoothService.cancelDiscovery();
    } catch (e) {
      _logger.e('$_className: Error al cancelar descubrimiento: $e');
    }
  }
  
  /// Conecta a un dispositivo Bluetooth
  Future<BluetoothConnection?> connectToDevice(BluetoothDevice device) async {
    _logger.d('$_className: Intentando conectar a ${device.name}, dirección: ${device.address}');
    
    // Detener escaneo si está en curso
    if (_isScanning) {
      await stopScan();
    }
    
    _connectingDevice = device;
    _statusMessage = 'Conectando a ${device.name ?? "dispositivo"}...';
    notifyListeners();
    
    try {
      // Verificar si el dispositivo está emparejado
      bool isBonded = await _bluetoothService.isDeviceBonded(device.address);
      
      if (!isBonded) {
        _logger.w('$_className: El dispositivo no está emparejado');
        _statusMessage = 'El dispositivo necesita ser emparejado primero';
        notifyListeners();
        
        try {
          bool bondResult = await _bluetoothService.bondDevice(device.address);
          
          if (!bondResult) {
            _statusMessage = 'Emparejamiento fallido';
            _connectingDevice = null;
            notifyListeners();
            return null;
          }
        } catch (e) {
          _logger.e('$_className: Error durante el emparejamiento: $e');
          _statusMessage = 'Error durante el emparejamiento';
          _connectingDevice = null;
          notifyListeners();
          return null;
        }
      }
      
      // Intentar conectar al dispositivo
      _statusMessage = 'Estableciendo conexión...';
      notifyListeners();
      
      BluetoothConnection connection = await _bluetoothService.connectToDevice(device.address);
      _logger.d('$_className: Conexión establecida con ${device.name}');
      
      // Verificar si el HC-05 responde correctamente
      _statusMessage = 'Verificando conexión...';
      notifyListeners();
      
      bool isResponding = await _bluetoothService.verifyHC05Connection(connection);
      _statusMessage = isResponding
          ? 'Conectado y funcionando correctamente'
          : 'Conectado, pero el dispositivo no responde correctamente';
      
      // Guardar la conexión y configurar el listener de datos
      _connection = connection;
      _connectedDevice = device;
      _isConnected = true;
      _setupInputListener();
      
      notifyListeners();
      
      return connection;
    } catch (e) {
      _logger.e('$_className: Error al conectar: $e');
      
      // Obtener mensaje de error específico
      String errorMessage = 'Error al conectar con el dispositivo';
      
      String errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socket') || errorStr.contains('connection')) {
        errorMessage = 'Error de conexión. Verifique que el dispositivo esté encendido y al alcance.';
      } else if (errorStr.contains('timeout')) {
        errorMessage = 'Tiempo de espera agotado. El dispositivo no responde.';
      } else if (errorStr.contains('bond') || errorStr.contains('auth') || errorStr.contains('pair')) {
        errorMessage = 'El dispositivo necesita ser emparejado. PIN típico: 1234 o 0000.';
      } else if (errorStr.contains('discover')) {
        errorMessage = 'Error al descubrir servicios. Reinicie el dispositivo e intente nuevamente.';
      } else if (errorStr.contains('reject')) {
        errorMessage = 'Conexión rechazada por el dispositivo. Verifique que esté en modo comunicación.';
      }
      
      _statusMessage = errorMessage;
      _connectingDevice = null;
      notifyListeners();
      
      return null;
    }
  }
  
  /// Configura el listener para los datos recibidos
  void _setupInputListener() {
    _logger.d('$_className: Configurando listener para datos recibidos');
    
    if (_connection == null || !_isConnected) {
      _logger.w('$_className: No hay conexión activa para configurar listener');
      return;
    }
    
    // Cancelar suscripción anterior si existe
    if (_dataSubscription != null) {
      _dataSubscription!.cancel();
      _dataSubscription = null;
      _logger.d('$_className: Suscripción de datos anterior cancelada');
    }
    
    try {
      // Crear un stream de broadcast para los datos recibidos
      final inputStream = _connection!.input!.asBroadcastStream();
      
      // Suscribirse al stream
      _dataSubscription = inputStream.listen(
        (Uint8List data) {
          // Decodificar datos recibidos
          String dataString = utf8.decode(data, allowMalformed: true);
          _logger.d('$_className: Datos recibidos: $dataString');
          
          // Enviar los datos al stream controller
          _dataStreamController.add(dataString);
        },
        onError: (error) {
          _logger.e('$_className: Error al recibir datos: $error');
          _dataStreamController.addError(error);
          
          if (error.toString().contains('closed') || 
              error.toString().contains('disconnected')) {
            _disconnectInternal();
          }
        },
        onDone: () {
          _logger.w('$_className: Conexión cerrada remotamente');
          _disconnectInternal();
        },
      );
      
      _logger.d('$_className: Listener configurado correctamente');
    } catch (e) {
      _logger.e('$_className: Error al configurar listener: $e');
    }
  }
  
  /// Envía un comando al dispositivo Bluetooth
  Future<bool> sendCommand(String command) async {
    if (!_isConnected || _connection == null) {
      _logger.w('$_className: No hay conexión activa para enviar comandos');
      return false;
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
        _disconnectInternal();
        return false;
      }
      
      // Enviar los datos
      _connection!.output.add(data);
      await _connection!.output.allSent;
      
      _logger.d('$_className: Comando enviado correctamente');
      return true;
    } catch (e) {
      _logger.e('$_className: Error al enviar comando: $e');
      
      // Actualizar estado si la conexión se perdió
      if (e.toString().contains('closed') || 
          e.toString().contains('disconnected') ||
          e.toString().contains('not connected')) {
        _disconnectInternal();
      }
      
      return false;
    }
  }
  
  /// Desconecta del dispositivo actual
  Future<void> disconnectDevice() async {
    _logger.d('$_className: Iniciando desconexión del dispositivo');
    await _disconnectInternal();
  }
  
  /// Método interno para desconectar
  Future<void> _disconnectInternal() async {
    if (!_isConnected && _connection == null) {
      _logger.d('$_className: No hay dispositivo conectado');
      return;
    }
    
    try {
      // Cancelar la suscripción de datos
      if (_dataSubscription != null) {
        await _dataSubscription!.cancel();
        _dataSubscription = null;
        _logger.d('$_className: Suscripción de datos cancelada');
      }
      
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
        }
        _connection = null;
      }
      
      // Actualizar estado
      _isConnected = false;
      _connectedDevice = null;
      _statusMessage = 'Desconectado';
      
      notifyListeners();
    } catch (e) {
      _logger.e('$_className: Error al desconectar: $e');
    }
  }
  
  /// Abre la configuración de Bluetooth
  Future<void> openBluetoothSettings() async {
    await _bluetoothService.openBluetoothSettings();
  }
  
  @override
  void dispose() {
    _dataSubscription?.cancel();
    _dataStreamController.close();
    _cancelDiscovery();
    super.dispose();
  }
} 