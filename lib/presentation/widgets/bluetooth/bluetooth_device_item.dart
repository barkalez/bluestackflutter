import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

/// Widget para mostrar un elemento de dispositivo Bluetooth en la lista
class BluetoothDeviceItem extends StatelessWidget {
  /// El dispositivo Bluetooth a mostrar
  final BluetoothDevice device;
  
  /// Función a ejecutar cuando se toca el dispositivo
  final VoidCallback onTap;
  
  /// Constructor del widget
  const BluetoothDeviceItem({
    super.key,
    required this.device,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    // Determinar si es un dispositivo BlueStack
    final deviceName = device.name?.toLowerCase() ?? "";
    final isBlueStackDevice = deviceName.contains("stackblue") || 
                             deviceName.contains("stack") || 
                             deviceName.contains("blue");
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isBlueStackDevice 
            ? BorderSide(color: Colors.blue.withAlpha(128), width: 2) 
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icono del dispositivo
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isBlueStackDevice ? Colors.blue.shade100 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  isBlueStackDevice ? Icons.bluetooth : Icons.bluetooth_searching,
                  color: isBlueStackDevice ? Colors.blue : Colors.grey,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              // Información del dispositivo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            device.name ?? 'Dispositivo desconocido',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isBlueStackDevice ? Colors.blue.shade800 : null,
                            ),
                          ),
                        ),
                        if (isBlueStackDevice)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.blue.withAlpha(128),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.withAlpha(192)),
                            ),
                            child: const Text(
                              'BlueStack',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      device.address,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    if (isBlueStackDevice) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Dispositivo compatible',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Icono de conexión
              Icon(
                Icons.arrow_forward_ios,
                color: isBlueStackDevice ? Colors.blue : Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 