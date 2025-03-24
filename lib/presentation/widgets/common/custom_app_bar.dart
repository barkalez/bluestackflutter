import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants.dart';

/// AppBar personalizado con gradiente, sombra y texto centrado con fuente de Google Fonts
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Altura de la barra
  final double height;
  
  /// Colores del gradiente
  final List<Color> gradientColors;
  
  /// Color de la sombra
  final Color shadowColor;
  
  /// Título opcional, si es null se usará el nombre de la app
  final String? title;
  
  /// Lista de acciones para mostrar en la barra de herramientas
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    this.height = kToolbarHeight + 25.0,
    this.gradientColors = const [
      Color(0xFF2196F3),  // Azul primario
      Color(0xFF0D47A1),  // Azul oscuro
    ],
    this.shadowColor = const Color(0x66000000),
    this.title,
    this.actions,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 6.0,
            spreadRadius: 0.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Título centrado
              Center(
                child: Text(
                  title ?? AppConstants.appName,
                  style: GoogleFonts.montserrat(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3.0,
                          color: Color(0x99000000),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Acciones a la derecha
              if (actions != null && actions!.isNotEmpty)
                Positioned(
                  right: 4.0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 