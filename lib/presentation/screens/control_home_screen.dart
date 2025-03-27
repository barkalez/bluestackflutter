import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../core/logger_config.dart';
import '../../core/constants.dart';
import '../../state/bluetooth_provider.dart';
import '../../state/app_state.dart';
import '../widgets/common/buttons/gradient_button.dart';

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
  
  // Buffer para almacenar datos recibidos
  final List<String> _receivedData = [];
  
  // Valor actual del slider
  double _sliderValue = 0.0;
  // Valor máximo para el slider (basado en el perfil activo)
  double _maxSliderValue = 400.0; // Valor por defecto
  
  @override
  void initState() {
    super.initState();
    _logger.d('$_className: Inicializando pantalla de control');
    
    // Configurar el listener de datos después de que el widget esté construido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _setupDataListener();
        _initializeSliderValues();
      }
    });
  }
  
  @override
  void dispose() {
    _logger.d('$_className: Liberando recursos');
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
  
  /// Inicializa los valores del slider basado en el perfil activo
  void _initializeSliderValues() {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.hasActiveProfile && appState.activeProfile != null) {
      setState(() {
        // Usar el total de grupos de pasos del perfil como valor máximo del slider
        _maxSliderValue = appState.activeProfile!.totalStepGroups.toDouble();
        _logger.d('$_className: Valor máximo del slider configurado a: $_maxSliderValue');
      });
    } else {
      _logger.w('$_className: No hay perfil activo, usando valor predeterminado para el slider');
    }
  }
  
  /// Envía un comando de movimiento a una posición específica
  void _moveToPosition(double position) async {
    final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);
    
    if (!bluetoothProvider.isConnected) {
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
    
    final int positionValue = position.round();
    _logger.d('$_className: Enviando comando de movimiento a posición: $positionValue');
    
    // Comando G1 para movimiento a posición absoluta
    String command = 'G1 X$positionValue\n';
    
    bool success = await bluetoothProvider.sendCommand(command);
    
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Moviendo a posición: $positionValue'),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 500),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al enviar comando de movimiento'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
    } else {
      // Si no hay dispositivo previo, ir a la pantalla de escaneo
      _logger.d('$_className: No hay dispositivo anterior, redirigiendo a pantalla de escaneo');
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppConstants.connectRoute);
      }
    }
  }
  
  /// Navega a la pantalla de inicio
  void _navigateToHome() {
    _logger.d('$_className: Navegando a la pantalla de inicio');
    Navigator.pushReplacementNamed(context, AppConstants.homeRoute);
  }
  
  @override
  Widget build(BuildContext context) {
    final bluetoothProvider = Provider.of<BluetoothProvider>(context);
    Provider.of<AppState>(context);
    
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
      body: Column(
        children: [
          // Botones de acción
          _buildActionButtons(bluetoothProvider),
          
          // Control de posición con slider
          _buildPositionSlider(bluetoothProvider),
          
          // Vista de datos
          Expanded(
            child: _buildDataView(),
          ),
        ],
      ),
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
  
  /// Construye la vista de datos recibidos
  Widget _buildDataView() {
    if (_receivedData.isEmpty) {
      return const Center(
        child: SizedBox.shrink(),
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
  
  /// Construye los botones de acción para interactuar con el dispositivo
  Widget _buildActionButtons(BluetoothProvider bluetoothProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Botón de Control Manual
          GradientButton(
            text: 'Control Manual',
            icon: Icons.pan_tool,
            onPressed: () => _navigateToManualControl(),
            width: null, // Ancho ajustado al contenido
          ),
          
          const SizedBox(height: 16),
          
          // Botón de Configurar Apilado
          GradientButton(
            text: 'Configurar Apilado',
            icon: Icons.layers,
            onPressed: () => _navigateToStackConfig(),
            width: null, // Ancho ajustado al contenido
          ),
          
          const SizedBox(height: 16),
          
          // Botón de Homing
          GradientButton(
            text: 'Homing',
            icon: Icons.home_work,
            onPressed: () => _sendHomingCommand(bluetoothProvider),
            width: null, // Ancho ajustado al contenido
          ),
        ],
      ),
    );
  }
  
  /// Envía el comando de homing G28 al dispositivo
  void _sendHomingCommand(BluetoothProvider bluetoothProvider) async {
    if (!bluetoothProvider.isConnected) {
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
    
    _logger.d('$_className: Enviando comando de homing G28');
    
    // Enviar comando G28 con nueva línea
    bool success = await bluetoothProvider.sendCommand('G28\n');
    
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ejecutando homing...'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al enviar comando de homing'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Navega a la pantalla de control manual
  void _navigateToManualControl() {
    _logger.d('$_className: Navegando a la pantalla de control manual');
    Navigator.pushNamed(context, AppConstants.manualControlRoute);
  }
  
  /// Navega a la pantalla de configuración de apilado
  void _navigateToStackConfig() {
    _logger.d('$_className: Navegando a la pantalla de configuración de apilado');
    Navigator.pushNamed(context, AppConstants.stackConfigRoute);
  }
  
  /// Construye el control deslizante de posición
  Widget _buildPositionSlider(BluetoothProvider bluetoothProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Posición:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_sliderValue.round()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('0'),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.blue,
                      inactiveTrackColor: Colors.blue.withAlpha(50),
                      trackShape: const RoundedRectSliderTrackShape(),
                      trackHeight: 4.0,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
                      thumbColor: Colors.blueAccent,
                      overlayColor: Colors.blue.withAlpha(32),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 28.0),
                      tickMarkShape: const RoundSliderTickMarkShape(),
                      activeTickMarkColor: Colors.blue,
                      inactiveTickMarkColor: Colors.blue.withAlpha(70),
                      valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
                      valueIndicatorColor: Colors.blueAccent,
                      valueIndicatorTextStyle: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    child: Slider(
                      value: _sliderValue,
                      min: 0,
                      max: _maxSliderValue,
                      divisions: _maxSliderValue.toInt(),
                      label: '${_sliderValue.round()}',
                      onChanged: (double value) {
                        setState(() {
                          _sliderValue = value;
                        });
                      },
                      onChangeEnd: (double value) {
                        // Enviar comando de movimiento cuando el usuario suelta el slider
                        if (bluetoothProvider.isConnected) {
                          _moveToPosition(_sliderValue);
                        }
                      },
                    ),
                  ),
                ),
                Text('${_maxSliderValue.round()}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Botón de movimiento a posición 0
                ElevatedButton.icon(
                  onPressed: bluetoothProvider.isConnected 
                    ? () {
                        setState(() {
                          _sliderValue = 0;
                        });
                        _moveToPosition(0);
                      }
                    : null,
                  icon: const Icon(Icons.home, size: 18),
                  label: const Text('Inicio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                
                // Botón de movimiento a posición máxima
                ElevatedButton.icon(
                  onPressed: bluetoothProvider.isConnected 
                    ? () {
                        setState(() {
                          _sliderValue = _maxSliderValue;
                        });
                        _moveToPosition(_maxSliderValue);
                      }
                    : null,
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('Máximo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 