import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vira/controllers/material_validation_controller.dart';
import 'package:vira/views/validation_history_view.dart';
import 'package:vira/views/profile_view.dart';
import 'package:vira/views/result_view.dart';
import 'package:vira/services/auth_service.dart';

class MaterialValidationView extends StatefulWidget {
  const MaterialValidationView({super.key});

  @override
  State<MaterialValidationView> createState() => _MaterialValidationViewState();
}

class _MaterialValidationViewState extends State<MaterialValidationView> {
  final _formKey = GlobalKey<FormState>();
  final _finalLabelController = TextEditingController();
  final _visualAidController = TextEditingController();
  final _containerController = TextEditingController();

  final FocusNode _finalLabelFocus = FocusNode();
  final FocusNode _visualAidFocus = FocusNode();
  final FocusNode _containerFocus = FocusNode();

  bool _isSubmitting = false;
  bool _firstBuild = true;

  @override
  void initState() {
    super.initState();
    // Configura el foco inicial después del primer renderizado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _firstBuild) {
        _finalLabelFocus.requestFocus();
        _firstBuild = false;
      }
    });
  }

  @override
  void dispose() {
    // Limpia todos los controladores y focus nodes
    _finalLabelController.dispose();
    _visualAidController.dispose();
    _containerController.dispose();
    _finalLabelFocus.dispose();
    _visualAidFocus.dispose();
    _containerFocus.dispose();
    super.dispose();
  }

  /// Maneja el cambio de foco entre campos del formulario
  void _fieldFocusChange(FocusNode current, FocusNode next) {
    current.unfocus();
    FocusScope.of(context).requestFocus(next);
  }

  /// Reinicia el formulario a su estado inicial
  void _resetForm() {
    _formKey.currentState?.reset();
    _finalLabelController.clear();
    _visualAidController.clear();
    _containerController.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _finalLabelFocus.requestFocus();
      }
    });
  }

  /// Maneja el proceso de cierre de sesión con confirmación
  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cerrar Sesión'),
            content: const Text('¿Estás seguro que deseas cerrar sesión?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Cerrar Sesión'),
              ),
            ],
          ),
    );

    if (shouldLogout == true) {
      await context.read<AuthService>().logout();
    }
  }

  /// Valida y envía el formulario de validación de materiales
  /// Valida y envía el formulario de validación de materiales
  Future<void> _validateAndSubmit() async {
    if (_formKey.currentState!.validate() && !_isSubmitting) {
      setState(() {
        _isSubmitting = true;
      });

      final containerCode = _containerController.text;
      final visualAidCode = _visualAidController.text;
      final finalLabelCode = _finalLabelController.text;

      try {
        // Realiza la validación del material
        final validationResult = await MaterialValidationController.validate(
          containerCode,
          visualAidCode,
          finalLabelCode,
        );

        final isValid = validationResult['isValid'] as bool;
        final partNumber = validationResult['partNumber'] as String?;
        final validationComment =
            validationResult['validationComment'] as String?;
        final displayMessage = validationResult['displayMessage'] as String?;

        final messageToShow =
            (displayMessage?.isNotEmpty == true)
                ? displayMessage
                : validationComment;

        // MOSTRAR NOTIFICACIÓN PERSISTENTE CON BOTÓN DE CERRAR
        if (messageToShow != null && messageToShow.isNotEmpty) {
          final snackBar = SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.red.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    messageToShow,
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red.shade700, size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ],
            ),
            backgroundColor: Colors.red.shade50,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            duration: const Duration(days: 1), // Duración muy larga
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.red.shade700, width: 1.5),
            ),
            elevation: 3,
            // Eliminar el dismissDirection para evitar que se cierre deslizando
            dismissDirection: DismissDirection.none,
          );

          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }

        // Envía los resultados a la API
        final accessErrors =
            await MaterialValidationController.sendValidationToAPI(
              containerCode: containerCode,
              visualAidCode: visualAidCode,
              finalLabelCode: finalLabelCode,
              isValid: isValid,
              partNumber: partNumber,
              validationComment: validationComment,
            );

        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ResultView(
                    isValid: isValid,
                    hasConnectionError: false,
                    errorMessage: messageToShow,
                    apiErrors: accessErrors,
                  ),
            ),
          );

          // Ocultar el SnackBar cuando se regrese de ResultView
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          _resetForm();
        }
      } catch (e) {
        // Maneja errores de conexión o validación
        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ResultView(
                    isValid: false,
                    hasConnectionError: true,
                    errorMessage: e.toString(),
                  ),
            ),
          );

          // Ocultar el SnackBar cuando se regrese de ResultView
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          Future.delayed(const Duration(milliseconds: 1000), _resetForm);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  /// Valida que la etiqueta final cumpla con los requisitos
  String? _validateFinalLabel(String? value) {
    if (value == null || value.isEmpty) {
      return 'La etiqueta final no puede estar vacía.';
    }

    if (value.length <= 30) {
      return 'La etiqueta final debe tener más de 30 caracteres.';
    }

    return null;
  }

  /// Valida que la ayuda visual no esté vacía
  String? _validateVisualAid(String? value) {
    if (value == null || value.isEmpty) {
      return 'La ayuda visual no puede estar vacía.';
    }
    return null;
  }

  /// Valida que el contenedor no esté vacío
  String? _validateContainer(String? value) {
    if (value == null || value.isEmpty) {
      return 'El contenedor no puede estar vacío.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validación de Materiales'),
        actions: [
          Consumer<AuthService>(
            builder: (context, authService, child) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (String value) {
                  if (value == 'profile') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileView(),
                      ),
                    );
                  } else if (value == 'history') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ValidationHistoryView(),
                      ),
                    );
                  } else if (value == 'logout') {
                    _handleLogout(context);
                  }
                },
                itemBuilder:
                    (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'history',
                        child: ListTile(
                          leading: Icon(Icons.history),
                          title: Text('Historial'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'logout',
                        child: ListTile(
                          leading:
                              authService.isLoggingOut
                                  ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  )
                                  : const Icon(Icons.logout),
                          title: const Text('Cerrar Sesión'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Campos del formulario
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      top: isSmallScreen ? 8 : 24,
                      bottom: 16,
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _finalLabelController,
                          focusNode: _finalLabelFocus,
                          enabled: !_isSubmitting,
                          decoration: InputDecoration(
                            labelText: 'Etiqueta Final',
                            prefixIcon: Icon(
                              Icons.local_offer,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          validator: _validateFinalLabel,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) {
                            _fieldFocusChange(
                              _finalLabelFocus,
                              _visualAidFocus,
                            );
                          },
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        TextFormField(
                          controller: _visualAidController,
                          focusNode: _visualAidFocus,
                          enabled: !_isSubmitting,
                          decoration: InputDecoration(
                            labelText: 'Ayuda visual',
                            prefixIcon: Icon(
                              Icons.article,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          validator: _validateVisualAid,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) {
                            _fieldFocusChange(_visualAidFocus, _containerFocus);
                          },
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        TextFormField(
                          controller: _containerController,
                          focusNode: _containerFocus,
                          enabled: !_isSubmitting,
                          decoration: InputDecoration(
                            labelText: 'Contenedor',
                            prefixIcon: Icon(
                              Icons.local_shipping,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          validator: _validateContainer,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) {
                            if (!_isSubmitting) {
                              _validateAndSubmit();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Botón fijo en la parte inferior
                Container(
                  padding: EdgeInsets.only(
                    bottom:
                        MediaQuery.of(context).viewInsets.bottom > 0
                            ? 16 // Padding mínimo cuando el teclado está visible
                            : 24, // Más espacio cuando no hay teclado
                    top: 16,
                    left: 8,
                    right: 8,
                  ),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _validateAndSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _isSubmitting
                            ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text(
                              'Verificar',
                              style: TextStyle(fontSize: 16),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
