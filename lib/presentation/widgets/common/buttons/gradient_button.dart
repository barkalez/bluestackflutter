import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Botón profesional con gradiente, sombras y esquinas redondeadas
/// Widget reutilizable para toda la aplicación
class GradientButton extends StatelessWidget {
  /// Texto a mostrar en el botón
  final String text;
  
  /// Función que se ejecuta al presionar el botón
  final VoidCallback onPressed;
  
  /// Colores para el gradiente del botón
  final List<Color> gradientColors;
  
  /// Radio de las esquinas redondeadas
  final double borderRadius;
  
  /// Elevación/sombra del botón
  final double elevation;
  
  /// Tamaño del texto
  final double fontSize;
  
  /// Ancho del botón (null = automático)
  final double? width;
  
  /// Alto del botón
  final double height;
  
  /// Icono opcional para mostrar antes del texto
  final IconData? icon;
  
  /// Espacio entre el icono y el texto
  final double iconSpacing;

  /// Constructor del botón con gradiente
  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.gradientColors = const [
      Color(0xFF2196F3),  // Azul claro
      Color(0xFF0D47A1),  // Azul oscuro
    ],
    this.borderRadius = 12.0,
    this.elevation = 4.0,
    this.fontSize = 16.0,
    this.width,
    this.height = 52.0,
    this.icon,
    this.iconSpacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: elevation * 2,
            offset: Offset(0, elevation / 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        color: Colors.white,
                        size: fontSize * 1.2,
                      ),
                      SizedBox(width: iconSpacing),
                    ],
                    Text(
                      text,
                      style: GoogleFonts.montserrat(
                        textStyle: TextStyle(
                          color: Colors.white,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 