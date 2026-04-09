import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vira/main.dart';

class ResultView extends StatefulWidget {
  final bool isValid;
  final bool hasConnectionError;
  final String? errorMessage; // se usa también como "validationComment"
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
              final maxWidth = constraints.maxWidth;
              final maxHeight = constraints.maxHeight;

              double responsiveFontSize = (maxWidth * 0.5).clamp(
                48.0,
                maxHeight * 0.45,
              );

              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: maxHeight * 0.45,
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'NG',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: responsiveFontSize,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: Offset(3, 3),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FractionallySizedBox(
                          widthFactor: 0.9,
                          child: Container(
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
                              obscureText: true,
                              obscuringCharacter: '*',
                              onSubmitted: (_) => _validateCode(),
                              style: TextStyle(color: ngColor, fontSize: 18),
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
                                  vertical: 14,
                                  horizontal: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).viewInsets.bottom + 16,
                        ),
                      ],
                    ),
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
      if (!widget.isValid && widget.errorMessage != null) {
        subtitleText = widget.errorMessage;
      }
    }

    return WillPopScope(
      onWillPop: () async => showBackButton,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxW = constraints.maxWidth;
              final maxH = constraints.maxHeight;

              final base = maxW < maxH ? maxW : maxH;
              double responsiveFontSize = (base * 0.35).clamp(40.0, 220.0);

              // Altura del botón + padding
              final buttonHeight = showBackButton ? 70.0 : 0.0;
              // Altura disponible para el contenido
              final availableHeight = maxH - buttonHeight;

              return Column(
                children: [
                  // Contenido principal
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.hasConnectionError) ...[
                              Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.wifi_off_rounded,
                                  size: 80,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                displayText,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ] else ...[
                              // OK / NG grande
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: availableHeight * 0.5,
                                  maxWidth: maxW * 0.8,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: Text(
                                    displayText,
                                    style: TextStyle(
                                      fontSize: responsiveFontSize,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.25),
                                          blurRadius: 10,
                                          offset: Offset(3, 3),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],

                            if (subtitleText != null) ...[
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  subtitleText!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Botón en la parte inferior
                  if (showBackButton)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.95),
                            foregroundColor: backgroundColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_back_rounded, size: 22),
                          label: const Text(
                            'REGRESAR',
                            style: TextStyle(fontSize: 15, letterSpacing: 1.0),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
