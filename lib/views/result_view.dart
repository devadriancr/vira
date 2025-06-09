import 'package:flutter/material.dart';
import '../main.dart';

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
  bool _showCodeInput = false;

  @override
  void initState() {
    super.initState();
    // Si es NG, mostrar el input de código
    if (!widget.isValid) {
      _showCodeInput = true;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _validateCode() async {
    if (_codeController.text == '9876') {
      // Código correcto, cerrar la pantalla
      if (!mounted) return;
      Navigator.pop(context);
    } else {
      // Código incorrecto, mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Código incorrecto',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(bottom: 30, left: 20, right: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.red, width: 1.5),
          ),
          elevation: 6,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si hay error de conexión, mostrar pantalla de error
    if (widget.hasConnectionError) {
      return _buildConnectionErrorScreen();
    }

    // Si es NG y necesita código, mostrar pantalla de bloqueo
    if (!widget.isValid && _showCodeInput) {
      return _buildLockScreen();
    }

    // Mostrar resultado normal (OK o NG después de desbloquear)
    return _buildResultScreen();
  }

  Widget _buildResultScreen() {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>();
    final color =
        widget.isValid
            ? (customColors?.okColor ?? const Color(0xFF0000FF))
            : (customColors?.ngColor ?? const Color(0xFFFF0000));

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: color,
        body: Stack(
          children: [
            Center(
              child: Text(
                widget.isValid ? 'OK' : 'NG',
                style: TextStyle(
                  fontSize: 200,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(3, 3),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.isValid)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.95),
                    foregroundColor: color,
                    fixedSize: const Size.fromHeight(52),
                    minimumSize: const Size(double.infinity, 52),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 8,
                    shadowColor: Colors.black26,
                  ),
                  icon: Icon(Icons.arrow_back_rounded, color: color, size: 24),
                  label: const Text(
                    'REGRESAR',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockScreen() {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>();
    final ngColor = customColors?.ngColor ?? const Color(0xFFFF0000);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: ngColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'NG',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 200,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 15,
                        offset: Offset(3, 3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _codeController,
                    style: TextStyle(
                      color: ngColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ingrese Código',
                      hintStyle: TextStyle(color: ngColor.withOpacity(0.7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _validateCode(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionErrorScreen() {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>();
    final errorColor =
        customColors?.connectionErrorColor ?? const Color(0xFFFF8F00);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: errorColor,
        body: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wifi_off_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'ERROR DE CONEXIÓN',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'No se pudo conectar al servidor.\nVerifique su conexión a internet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.95),
                  foregroundColor: errorColor,
                  fixedSize: const Size.fromHeight(52),
                  minimumSize: const Size(double.infinity, 52),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 8,
                  shadowColor: Colors.black26,
                ),
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: errorColor,
                  size: 24,
                ),
                label: const Text(
                  'REGRESAR',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
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
