import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vira/main.dart';

class ResultView extends StatefulWidget {
  final bool isValid;
  final bool hasConnectionError;

  const ResultView({
    super.key,
    required this.isValid,
    this.hasConnectionError = false,
  });

  @override
  State<ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<ResultView> {
  final TextEditingController _codeController = TextEditingController();
  bool _isUnlocked = false;

  @override
  void initState() {
    super.initState();
    _isUnlocked = widget.isValid || widget.hasConnectionError;
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _validateCode() {
    if (_codeController.text == '9876') {
      // Código correcto, regresar a material_validation_view.dart
      if (!mounted) return;
      Navigator.pop(context);
    } else {
      // Limpiar el campo y mostrar error
      _codeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                'Código incorrecto',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.red, width: 1.5),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // BLOQUEO TOTAL: Si es NG y no está desbloqueado, mostrar pantalla de código
    if (!widget.isValid && !_isUnlocked) {
      return _buildLockedScreen();
    }

    // Pantallas normales (OK, NG desbloqueado, o error de conexión)
    return _buildResultScreen();
  }

  Widget _buildLockedScreen() {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>();
    final ngColor = customColors?.ngColor ?? const Color(0xFFFF0000);

    return WillPopScope(
      // BLOQUEO TOTAL - No permite salir de ninguna manera
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: ngColor,
        body: PopScope(
          // También bloquea el gesto de deslizar hacia atrás en iOS
          canPop: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Texto NG grande
                  Text(
                    'NG',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 200,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          offset: Offset(3, 3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                  // Campo de código
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _validateCode(),
                      style: TextStyle(color: ngColor, fontSize: 20),
                      decoration: InputDecoration(
                        hintText: 'Ingrese Código',
                        hintStyle: TextStyle(color: ngColor),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>();

    Color backgroundColor;
    String displayText;
    bool showBackButton = true;

    if (widget.hasConnectionError) {
      backgroundColor =
          customColors?.connectionErrorColor ?? const Color(0xFFFF8F00);
      displayText = 'ERROR DE CONEXIÓN';
      showBackButton = true;
    } else {
      backgroundColor =
          widget.isValid
              ? (customColors?.okColor ?? const Color(0xFF1D24CA))
              : (customColors?.ngColor ?? const Color(0xFFFF0000));
      displayText = widget.isValid ? 'OK' : 'NG';
      showBackButton = widget.isValid; // Solo mostrar botón si es OK
    }

    return WillPopScope(
      onWillPop: () async => showBackButton,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Stack(
          children: [
            // Contenido principal
            Center(
              child:
                  widget.hasConnectionError
                      ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.wifi_off_rounded,
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Text(
                            displayText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            'No se pudo conectar al servidor.\nVerifique su conexión a internet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                              height: 1.4,
                            ),
                          ),
                        ],
                      )
                      : Text(
                        displayText,
                        style: TextStyle(
                          fontSize: 200,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 15,
                              offset: Offset(3, 3),
                            ),
                          ],
                        ),
                      ),
            ),
            // Botón de regresar (solo si está permitido)
            if (showBackButton)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.95),
                    foregroundColor: backgroundColor,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 8,
                  ),
                  icon: Icon(Icons.arrow_back_rounded, size: 24),
                  label: Text(
                    'REGRESAR',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
