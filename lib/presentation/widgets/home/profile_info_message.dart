import 'package:flutter/material.dart';

/// Widget para mostrar el mensaje informativo sobre los perfiles creados
class ProfileInfoMessage extends StatelessWidget {
  /// Constantes de diseño para mejorar la consistencia visual
  static const double _horizontalPadding = 32.0;
  static const double _verticalPadding = 10.0;
  static const double _containerPadding = 16.0;
  static const double _iconSize = 28.0;
  static const double _iconSpacing = 8.0;
  static const double _borderRadius = 12.0;

  /// Número de perfiles creados
  final int profileCount;

  const ProfileInfoMessage({
    required this.profileCount,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_containerPadding),
      margin: const EdgeInsets.symmetric(
        horizontal: _horizontalPadding,
        vertical: _verticalPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.blue,
            size: _iconSize,
          ),
          const SizedBox(height: _iconSpacing),
          Text(
            _getProfileCountMessage(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  /// Retorna el mensaje apropiado según la cantidad de perfiles
  String _getProfileCountMessage() {
    return 'Tienes $profileCount ${profileCount == 1 ? 'perfil creado' : 'perfiles creados'}';
  }
} 