import 'package:flutter/material.dart';
import 'package:vira/controllers/material_validation_controller.dart';
import 'package:vira/views/validation_history_view.dart';
import 'package:vira/views/validation_statistics_view.dart';
import 'package:vira/views/result_view.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_finalLabelFocus);
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

  // Función para resetear el formulario y enfocar el primer campo
  void _resetForm() {
    _formKey.currentState?.reset();
    _finalLabelController.clear();
    _visualAidController.clear();
    _containerController.clear();
    FocusScope.of(context).requestFocus(_finalLabelFocus);
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
        // Paso 1: Validar localmente
        final validationResult = await MaterialValidationController.validate(
          containerCode,
          visualAidCode,
          finalLabelCode,
        );

        final isValid = validationResult['isValid'] as bool;
        final partNumber = validationResult['partNumber'] as String?;

        // Paso 2: Enviar a la API
        final accessErrors =
            await MaterialValidationController.sendValidationToAPI(
              containerCode: containerCode,
              visualAidCode: visualAidCode,
              finalLabelCode: finalLabelCode,
              isValid: isValid,
              partNumber: partNumber,
            );

        // Paso 3: Navegar a la pantalla de resultados
        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      ResultView(isValid: isValid, hasConnectionError: false),
            ),
          );

          // Mostrar mensajes de acceso si los hay
          if (accessErrors != null && accessErrors.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(accessErrors.join('\n')),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          }

          _resetForm();
        }
      } catch (e) {
        // Error de conexión - mostrar pantalla de error
        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      ResultView(isValid: false, hasConnectionError: true),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Validación de Materiales'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (String value) {
              if (value == 'history') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ValidationHistoryView(),
                  ),
                );
              } else if (value == 'statistics') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ValidationStatisticsView(),
                  ),
                );
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
                  const PopupMenuItem<String>(
                    value: 'statistics',
                    child: ListTile(
                      leading: Icon(Icons.bar_chart),
                      title: Text('Estadísticas'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    vertical: 16,
                  ),
                ),
                validator: _validateFinalLabel,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) {
                  _fieldFocusChange(_finalLabelFocus, _visualAidFocus);
                },
              ),
              const SizedBox(height: 16),
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
                    vertical: 16,
                  ),
                ),
                validator: _validateVisualAid,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) {
                  _fieldFocusChange(_visualAidFocus, _containerFocus);
                },
              ),
              const SizedBox(height: 16),
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
                    vertical: 16,
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
              const SizedBox(height: 32),
              ElevatedButton(
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
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Text('Verificar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
