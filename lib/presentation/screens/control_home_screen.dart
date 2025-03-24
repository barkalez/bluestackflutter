import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../core/logger_config.dart';
import '../../core/constants.dart';
import '../../state/bluetooth_provider.dart';

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
      body: _buildDataView(),
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
        child: Text(
          'Panel de control Bluestack',
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
} 