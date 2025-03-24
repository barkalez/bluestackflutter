import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:provider/provider.dart';
import '../../core/logger_config.dart';
import '../../core/constants.dart';
import '../../state/app_state.dart';
import '../widgets/bluetooth/bluetooth_device_item.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';

/// Pantalla para escanear y conectar a dispositivos Bluetooth
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
  
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  List<BluetoothDevice> _devices = [];
  bool _isScanning = false;
  // Dispositivo al que se está intentando conectar actualmente
  
  @override
  void initState() {
    super.initState();
    _logger.d('$_className: Inicializando pantalla de escaneo Bluetooth');
    _isScanning = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBluetoothState();
    });
  }

  @override
  void dispose() {
    _logger.d('$_className destruida');
    
    // Cancelar cualquier descubrimiento en curso al salir de la pantalla
    try {
      _bluetooth.cancelDiscovery();
      _logger.d('$_className: Descubrimiento cancelado durante dispose');
    } catch (e) {
      _logger.w('$_className: Error al cancelar descubrimiento durante dispose: $e');
    }
    
    super.dispose();
  }
  
  /// Iniciar el escaneo de dispositivos Bluetooth
  Future<void> _startScan() async {
    _logger.d('$_className: Iniciando escaneo de dispositivos Bluetooth');
    
    setState(() {
      _isScanning = true;
      _devices = [];
    });
    
    try {
      // Solicitar todos los permisos necesarios según la versión de Android
      _logger.d('$_className: Solicitando permisos necesarios');
      
      // Para Android 12+ (API 31+): BLUETOOTH_SCAN, BLUETOOTH_CONNECT
      // Para Android <12: BLUETOOTH, BLUETOOTH_ADMIN, ACCESS_FINE_LOCATION
      
      // Intentar con los nuevos permisos primero
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location, // Todavía necesario para algunos dispositivos
      ].request();
      
      // Verificar si todos los permisos fueron concedidos
      bool allPermissionsGranted = true;
      statuses.forEach((permission, status) {
        if (!status.isGranted) {
          allPermissionsGranted = false;
          _logger.w('$_className: Permiso $permission no concedido. Estado: $status');
        }
      });
      
      if (!allPermissionsGranted) {
        _logger.w('$_className: No todos los permisos fueron concedidos');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Se requieren permisos de Bluetooth y ubicación para buscar dispositivos'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          setState(() {
            _isScanning = false;
          });
        }
        return;
      }
      
      // Verificar si el Bluetooth está habilitado
      bool isEnabled = await _bluetooth.isEnabled ?? false;
      
      if (!isEnabled) {
        _logger.d('$_className: Bluetooth no está habilitado, solicitando activación');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por favor, activa el Bluetooth para continuar'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        
        // Solicitar activación del Bluetooth
        bool? enableResult = await _bluetooth.requestEnable();
        
        if (enableResult != true) {
          _logger.d('$_className: Usuario rechazó activar Bluetooth');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Es necesario activar el Bluetooth para conectar con BlueStack'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              _isScanning = false;
            });
          }
          return;
        }
      }
      
      // Comenzar el descubrimiento de dispositivos
      _logger.d('$_className: Comenzando descubrimiento de dispositivos');
      
      // Iniciar un nuevo descubrimiento directamente
      // En Android 12+, el try/catch anterior para cancelDiscovery puede fallar aunque los permisos estén concedidos
      // porque el sistema puede no haber registrado completamente los permisos
      _logger.d('$_className: Iniciando nuevo descubrimiento...');
      
      // Usar un flag para evitar actualizar el estado si el widget se desmonta
      bool isActive = true;
      
      _bluetooth.startDiscovery().listen(
        (BluetoothDiscoveryResult result) {
          // Manejar los resultados de la búsqueda de forma segura
          try {
            if (!isActive || !mounted) return;
            
            // Obtener información del dispositivo
            final deviceName = result.device.name?.toLowerCase() ?? "";
            final deviceAddress = result.device.address;
            _logger.d('$_className: Dispositivo encontrado: ${result.device.name ?? "Sin nombre"} - $deviceAddress');
            
            // Verificar si el dispositivo ya está en la lista
            bool deviceExists = _devices.any((device) => device.address == deviceAddress);
            
            if (deviceExists) {
              return; // No agregar dispositivos duplicados
            }
            
            // CAMBIO IMPORTANTE: Solo mostrar dispositivos BlueStack (HC-05)
            bool isBlueStackDevice = deviceName.contains("stackblue") || 
                                   deviceName.contains("stack") || 
                                   deviceName.contains("blue") ||
                                   deviceName.contains("hc-05") ||
                                   deviceName.contains("hc05");
            
            if (isBlueStackDevice) {
              _logger.d('$_className: Dispositivo BlueStack encontrado: ${result.device.name}');
              if (mounted) {
                setState(() {
                  _devices.add(result.device);
                });
              }
            } else {
              // Solo registrar en el log los otros dispositivos, pero no mostrarlos
              _logger.d('$_className: Ignorando dispositivo no BlueStack: ${result.device.name}');
            }
          } catch (innerError) {
            _logger.e('$_className: Error al procesar resultado de descubrimiento: $innerError');
          }
        },
        onDone: () {
          _logger.d('$_className: Descubrimiento completado');
          if (!isActive) return;
          
          if (mounted) {
            setState(() {
              _isScanning = false;
            });
            
            if (_devices.isEmpty) {
              _logger.d('$_className: No se encontraron dispositivos Bluetooth');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No se encontraron dispositivos Bluetooth. Asegúrate de que estén encendidos y visibles.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        },
        onError: (error) {
          _logger.e('$_className: Error durante el escaneo: $error');
          if (!isActive) return;
          
          if (mounted) {
            setState(() {
              _isScanning = false;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al buscar dispositivos: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        cancelOnError: false,  // No cancelar en caso de error
      );
      
      // Detener el escaneo después del tiempo configurado
      Future.delayed(Duration(seconds: AppConstants.btScanTimeout), () {
        if (_isScanning && mounted) {
          _logger.d('$_className: Tiempo de escaneo agotado');
          try {
            _bluetooth.cancelDiscovery();
          } catch (e) {
            _logger.w('$_className: Error al cancelar descubrimiento por tiempo: $e');
          }
          setState(() {
            _isScanning = false;
          });
        }
      });
      
      // No devolver nada, solo mantener la variable para uso local
      isActive = isActive; // Esto solo es para mantener la variable sin cambiarla
      
    } catch (e) {
      _logger.e('$_className: Error al iniciar el escaneo: $e');
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar la búsqueda: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Comprueba si el HC-05 responde correctamente
  Future<bool> _verifyHC05Connection(BluetoothConnection connection) async {
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

  /// Mostrar información sobre estado del HC-05
  void _showHC05StatusInfo(BuildContext context, bool isResponding) {
    String title = isResponding 
        ? 'HC-05 conectado correctamente' 
        : 'Conexión establecida, pero HC-05 no responde';
    
    String message = isResponding
        ? 'El módulo HC-05 está respondiendo correctamente. Puede proceder a utilizar la aplicación.'
        : 'Se ha establecido la conexión Bluetooth, pero el módulo HC-05 no responde a comandos. Esto puede deberse a:\n\n'
          '• El módulo está en modo incorrecto\n'
          '• Hay un problema con el cableado\n'
          '• El módulo necesita ser reiniciado\n\n'
          'Recomendación: Reinicie el módulo HC-05 y asegúrese de que el LED parpadea (modo comunicación).';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Entendido'),
            ),
            if (!isResponding)
              TextButton(
                onPressed: () {
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                  _showResetInstructionsDialog();
                },
                child: const Text('Ver instrucciones de reinicio'),
              ),
          ],
        );
      },
    );
  }

  /// Conectar a un dispositivo Bluetooth
  void _connectToDevice(BluetoothDevice device) async {
    // Asegurarse de que no estamos escaneando
    if (_isScanning) {
      _logger.d('$_className: Deteniendo escaneo antes de conectar');
      try {
        await FlutterBluetoothSerial.instance.cancelDiscovery();
      } catch (e) {
        _logger.e('$_className: Error al cancelar descubrimiento: $e');
      }
      setState(() {
        _isScanning = false;
      });
    }

    _logger.d('$_className: Intentando conectar a ${device.name}, dirección: ${device.address}');
    
    try {
      // Verificar si el dispositivo está emparejado
      bool isBonded = false;
      try {
        final bondState = await FlutterBluetoothSerial.instance.getBondStateForAddress(device.address);
        isBonded = bondState == BluetoothBondState.bonded;
        _logger.d('$_className: Estado de emparejamiento para ${device.address}: $bondState');
      } catch (e) {
        _logger.e('$_className: Error al verificar estado de emparejamiento: $e');
      }
      
      if (!isBonded) {
        _logger.w('$_className: El dispositivo no está emparejado. Intentando emparejar...');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El módulo HC-05 necesita ser emparejado primero. Intente emparejar en configuración Bluetooth.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
        
        try {
          bool? bondResultNullable = await FlutterBluetoothSerial.instance.bondDeviceAtAddress(device.address);
          bool bondResult = bondResultNullable ?? false;
          _logger.d('$_className: Resultado del emparejamiento: $bondResult');
          
          if (!bondResult) {
            _showPairingDialog();
            return;
          }
        } catch (e) {
          _logger.e('$_className: Error durante el emparejamiento: $e');
          
          String errorStr = e.toString().toLowerCase();
          if (errorStr.contains('bond') || 
              errorStr.contains('auth') || 
              errorStr.contains('pair') ||
              errorStr.contains('permission')) {
            _showPairingDialog();
            return;
          }
        }
      }
      
      // Intentar conectar al dispositivo
      _logger.d('$_className: Estableciendo conexión con ${device.address}...');
      setState(() {
      });
      
      BluetoothConnection connection = await BluetoothConnection.toAddress(device.address);
      _logger.d('$_className: Conexión establecida con ${device.name}');
      
      // Verificar si el HC-05 responde correctamente
      bool isResponding = await _verifyHC05Connection(connection);
      
      // Guardar el dispositivo conectado en el estado de la app
      if (mounted) {
        Provider.of<AppState>(context, listen: false).addRecentDevice(
          device.name ?? 'Dispositivo desconocido', 
          device.address
        );
        
        // Guardar la conexión en la AppState
        Provider.of<AppState>(context, listen: false).setConnectedDevice(device, connection);
        
        _logger.d('$_className: Conexión guardada en AppState');
        
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
        
        // Mostrar información sobre el estado del HC-05
        _showHC05StatusInfo(context, isResponding);
        
        // Navegar a la pantalla de control
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppConstants.controlRoute);
        }
      }
    } catch (e) {
      _logger.e('$_className: Error al conectar: $e');
      
      // Obtener mensaje de error específico según el tipo de excepción
      String errorMessage = 'Error al conectar con el dispositivo';
      
      String errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socket') || errorStr.contains('connection')) {
        errorMessage = 'Error de conexión al módulo HC-05. Verifique que esté encendido y al alcance.';
      } else if (errorStr.contains('timeout')) {
        errorMessage = 'Tiempo de espera agotado. El módulo HC-05 no responde.';
      } else if (errorStr.contains('bond') || errorStr.contains('auth') || errorStr.contains('pair')) {
        errorMessage = 'El módulo HC-05 necesita ser emparejado. PIN típico: 1234 o 0000.';
        _showPairingDialog();
      } else if (errorStr.contains('discover')) {
        errorMessage = 'Error al descubrir servicios. Reinicie el módulo HC-05 e intente nuevamente.';
      } else if (errorStr.contains('reject')) {
        errorMessage = 'Conexión rechazada por el módulo HC-05. Verifique que esté en modo comunicación.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
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
      
      setState(() {
      });
    }
  }
  
  // Mostrar diálogo para sugerir emparejar el dispositivo
  void _showPairingDialog() {
    // Usar microtarea para evitar problemas con el contexto
    Future.microtask(() {
      if (!mounted) return;
      
      showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: const Text('Emparejamiento requerido'),
          content: const Text(
            'El módulo HC-05 necesita estar emparejado en la configuración de Bluetooth de Android antes de conectarse.\n\n'
            'Código PIN típico: 1234 o 0000\n\n'
            '¿Deseas abrir la configuración de Bluetooth?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('No, gracias'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  // openSettings devuelve void, no asignamos su resultado a una variable
                  await FlutterBluetoothSerial.instance.openSettings();
                  _logger.d('$_className: Configuración Bluetooth abierta');
                } catch (e) {
                  _logger.e('$_className: Error al abrir configuración Bluetooth: $e');
                }
              },
              child: const Text('Abrir configuración'),
            ),
          ],
        ),
      );
    });
  }

  
  /// Muestra instrucciones para reiniciar un módulo HC-05
  void _showResetInstructionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conectar dispositivo Bluetooth'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
            onPressed: () {
              _startScan();
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Ayuda',
            onPressed: () {
              _showHelpDialog();
            },
          ),
        ],
      ),
      body: _buildBody(appState),
      floatingActionButton: FloatingActionButton(
        onPressed: _isScanning ? _stopScan : _startScan,
        tooltip: _isScanning ? 'Detener escaneo' : 'Iniciar escaneo',
        child: Icon(_isScanning ? Icons.stop : Icons.bluetooth_searching),
      ),
    );
  }
  
  Widget _buildStatusIndicator() {
    final hasBlueStackDevice = _devices.any((device) {
      final name = device.name?.toLowerCase() ?? "";
      return name.contains("stackblue") || 
             name.contains("stack") || 
             name.contains("blue") || 
             name.contains("hc-05") || 
             name.contains("hc05");
    });
    
    String statusText;
    Color? statusColor;
    
    if (_isScanning) {
      statusText = 'Buscando módulos BlueStack/HC-05...';
      statusColor = Colors.blue;
    } else if (_devices.isEmpty) {
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
      color: _isScanning ? Colors.blue.withAlpha(25) : Colors.transparent,
      child: Row(
        children: [
          _isScanning
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  hasBlueStackDevice 
                      ? Icons.bluetooth_connected 
                      : (_devices.isEmpty ? Icons.bluetooth_disabled : Icons.bluetooth_searching),
                  color: hasBlueStackDevice ? Colors.green : (_devices.isEmpty ? Colors.grey : Colors.orange),
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
  
  Widget _buildDeviceList() {
    if (_devices.isEmpty) {
      return Center(
        child: _isScanning
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
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        return BluetoothDeviceItem(
          device: device,
          onTap: () => _connectToDevice(device),
        );
      },
    );
  }
  
  
  /// Construye la sección de dispositivos recientes
  Widget _buildRecentDevicesSection(AppState appState) {
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
                    onPressed: () async {
                      // Abrir configuración Bluetooth para emparejar
                      try {
                        await FlutterBluetoothSerial.instance.openSettings();
                        _logger.d('$_className: Configuración Bluetooth abierta para emparejar');
                      } catch (e) {
                        _logger.e('$_className: Error al abrir configuración Bluetooth: $e');
                      }
                    },
                    tooltip: 'Emparejar',
                  ),
                  IconButton(
                    icon: const Icon(Icons.bluetooth, color: Colors.blue),
                    onPressed: () {
                      _logger.d('$_className: Intentando conectar a dispositivo reciente: ${device['name']}');
                      // Crear un BluetoothDevice a partir de la información guardada
                      final bluetoothDevice = BluetoothDevice(
                        name: device['name'],
                        address: device['address'] ?? '',
                      );
                      _connectToDevice(bluetoothDevice);
                    },
                    tooltip: 'Conectar',
                  ),
                ],
              ),
              onTap: () {
                _logger.d('$_className: Intentando conectar a dispositivo reciente: ${device['name']}');
                // Crear un BluetoothDevice a partir de la información guardada
                final bluetoothDevice = BluetoothDevice(
                  name: device['name'],
                  address: device['address'] ?? '',
                );
                _connectToDevice(bluetoothDevice);
              },
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

  /// Verifica el estado del adaptador Bluetooth
  void _checkBluetoothState() async {
    _logger.d('$_className: Verificando estado del Bluetooth');
    try {
      // Verificar si el bluetooth está disponible y encendido
      final state = await FlutterBluetoothSerial.instance.state;
      
      if (state == BluetoothState.STATE_OFF) {
        _logger.w('$_className: Bluetooth está apagado');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Bluetooth está apagado. Por favor encienda el Bluetooth para usar esta funcionalidad.'),
              action: SnackBarAction(
                label: 'Activar',
                onPressed: () async {
                  try {
                    await FlutterBluetoothSerial.instance.requestEnable();
                    _logger.d('$_className: Usuario solicitó habilitar Bluetooth');
                  } catch (e) {
                    _logger.e('$_className: Error al solicitar activación de Bluetooth: $e');
                  }
                },
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else if (state == BluetoothState.STATE_ON) {
        _logger.d('$_className: Bluetooth está encendido, iniciando escaneo');
        _startScan();
      } else {
        _logger.w('$_className: Estado de Bluetooth desconocido o indefinido: $state');
      }
    } catch (e) {
      _logger.e('$_className: Error al verificar estado de Bluetooth: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al verificar estado de Bluetooth: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Muestra un diálogo de ayuda con información sobre el HC-05
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              Navigator.of(context).pop();
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  /// Construye el cuerpo principal de la pantalla
  Widget _buildBody(AppState appState) {
    final hasRecentDevices = appState.recentDevices.isNotEmpty;
    
    return Column(
      children: [
        _buildStatusIndicator(),
        // Sección de dispositivos recientes
        if (hasRecentDevices) _buildRecentDevicesSection(appState),
        // Lista de dispositivos encontrados
        Expanded(
          child: _buildDeviceList(),
        ),
      ],
    );
  }

  /// Detiene el escaneo de dispositivos Bluetooth
  void _stopScan() async {
    _logger.d('$_className: Deteniendo escaneo manualmente');
    if (!_isScanning) return;
    
    try {
      await FlutterBluetoothSerial.instance.cancelDiscovery();
      _logger.d('$_className: Escaneo detenido correctamente');
      
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    } catch (e) {
      _logger.e('$_className: Error al detener escaneo: $e');
    }
  }
} 