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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _firstBuild) {
        _finalLabelFocus.requestFocus();
        _firstBuild = false;
      }
    });
  }

  @override
  void dispose() {
    _finalLabelController.dispose();
    _visualAidController.dispose();
    _containerController.dispose();
    _finalLabelFocus.dispose();
    _visualAidFocus.dispose();
    _containerFocus.dispose();
    super.dispose();
  }

  void _fieldFocusChange(FocusNode current, FocusNode next) {
    current.unfocus();
    FocusScope.of(context).requestFocus(next);
  }

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

  Future<void> _validateAndSubmit() async {
    if (_formKey.currentState!.validate() && !_isSubmitting) {
      setState(() {
        _isSubmitting = true;
      });

      final containerCode = _containerController.text;
      final visualAidCode = _visualAidController.text;
      final finalLabelCode = _finalLabelController.text;

      try {
        final validationResult = await MaterialValidationController.validate(
          containerCode,
          visualAidCode,
          finalLabelCode,
        );

        final isValid = validationResult['isValid'] as bool;
        final partNumber = validationResult['partNumber'] as String?;
        final validationComment =
            validationResult['validationComment'] as String?;

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
                    apiErrors: accessErrors,
                  ),
            ),
          );

          // if (accessErrors != null && accessErrors.isNotEmpty) {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     SnackBar(
          //       content: Text(accessErrors.join('\n')),
          //       backgroundColor: Colors.orange,
          //       duration: const Duration(seconds: 2),
          //     ),
          //   );
          // }

          _resetForm();
        }
      } catch (e) {
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

  String? _validateFinalLabel(String? value) {
    if (value == null || value.isEmpty) {
      return 'La etiqueta final no puede estar vacía.';
    }

    if (value.length <= 30) {
      return 'La etiqueta final debe tener más de 30 caracteres.';
    }

    return null;
  }

  String? _validateVisualAid(String? value) {
    if (value == null || value.isEmpty) {
      return 'La ayuda visual no puede estar vacía.';
    }
    return null;
  }

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
                      // const PopupMenuItem<String>(
                      //   value: 'profile',
                      //   child: ListTile(
                      //     leading: Icon(Icons.person),
                      //     title: Text('Perfil'),
                      //     contentPadding: EdgeInsets.zero,
                      //   ),
                      // ),
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
                            ? 16 // Mantenemos un padding mínimo cuando el teclado está visible
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
