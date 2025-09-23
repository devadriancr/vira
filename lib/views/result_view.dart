import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vira/main.dart';

class ResultView extends StatefulWidget {
  final bool isValid;
  final bool hasConnectionError;
  final String? errorMessage;
  final List<String>? apiErrors;

  const ResultView({
    super.key,
    required this.isValid,
    this.hasConnectionError = false,
    this.errorMessage,
    this.apiErrors,
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
      if (!mounted) return;
      Navigator.pop(context);
    } else {
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
    if (!widget.isValid && !_isUnlocked) {
      return _buildLockedScreen();
    }
    return _buildResultScreen();
  }

  Widget _buildLockedScreen() {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>();
    final ngColor = customColors?.ngColor ?? const Color(0xFFFF0000);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: ngColor,
        body: PopScope(
          canPop: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calcular tamaño de fuente responsivo basado en el ancho de la pantalla
              double responsiveFontSize = constraints.maxWidth * 0.4;
              if (responsiveFontSize > 200) responsiveFontSize = 200;
              if (responsiveFontSize < 100) responsiveFontSize = 100;

              return SingleChildScrollView(
                // Permitir scroll en pantallas pequeñas
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Texto NG con tamaño responsivo
                      Container(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight * 0.5,
                        ),
                        child: Center(
                          child: Text(
                            'NG',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: responsiveFontSize,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: Offset(3, 3),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
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
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).viewInsets.bottom + 20,
                      ),
                    ],
                  ),
                ),
              );
            },
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
    String? subtitleText;

    if (widget.hasConnectionError) {
      backgroundColor =
          customColors?.connectionErrorColor ?? const Color(0xFFFF8F00);
      displayText = 'ERROR DE CONEXIÓN';
      showBackButton = true;

      if (widget.errorMessage != null) {
        subtitleText = widget.errorMessage;
      } else if (widget.apiErrors != null && widget.apiErrors!.isNotEmpty) {
        subtitleText = widget.apiErrors!.join('\n');
      } else {
        subtitleText =
            'No se pudo conectar al servidor.\nVerifique su conexión a internet.';
      }
    } else {
      backgroundColor =
          widget.isValid
              ? theme.colorScheme.primary
              : (customColors?.ngColor ?? const Color(0xFFFF0000));
      displayText = widget.isValid ? 'OK' : 'NG';
      showBackButton = widget.isValid;
    }

    return WillPopScope(
      onWillPop: () async => showBackButton,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: LayoutBuilder(
          builder: (context, constraints) {
            // Tamaño de fuente responsivo para la pantalla de resultados
            double responsiveFontSize = constraints.maxWidth * 0.3;
            if (responsiveFontSize > 200) responsiveFontSize = 200;
            if (responsiveFontSize < 80) responsiveFontSize = 80;

            return Stack(
              children: [
                // Contenido principal
                Center(
                  child:
                      widget.hasConnectionError
                          ? SingleChildScrollView(
                            padding: EdgeInsets.all(20),
                            child: Column(
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
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Text(
                                    subtitleText ?? 'Error desconocido',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w300,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          : Text(
                            displayText,
                            style: TextStyle(
                              fontSize: responsiveFontSize,
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
                            textAlign: TextAlign.center,
                          ),
                ),
                // Botón de regresar
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
                        elevation: 8,
                      ),
                      icon: Icon(Icons.arrow_back_rounded, size: 24),
                      label: Text(
                        'REGRESAR',
                        style: TextStyle(fontSize: 16, letterSpacing: 1.0),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
