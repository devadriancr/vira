import 'package:flutter/material.dart';
import '../models/work_center.dart';
import '../controllers/material_validation_controller.dart';

class MaterialValidationView extends StatefulWidget {
  final WorkCenter workCenter;

  const MaterialValidationView({super.key, required this.workCenter});

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
    if (_formKey.currentState!.validate()) {
      final containerCode = _containerController.text;
      final visualAidCode = _visualAidController.text;
      final finalLabelCode = _finalLabelController.text;

      try {
        final isValid = await MaterialValidationController.validate(
          containerCode,
          visualAidCode,
          finalLabelCode,
        );

        if (isValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '¡Validación exitosa para ${widget.workCenter.name}!',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error en la validación para ${widget.workCenter.name}',
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Resetear el formulario después de mostrar la notificación
        Future.delayed(const Duration(milliseconds: 2100), _resetForm);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        Future.delayed(const Duration(milliseconds: 2100), _resetForm);
      }
    }
  }

  String? _validateFinalLabel(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa la etiqueta final';
    }
    return null;
  }

  String? _validateVisualAid(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa la ayuda visual';
    }
    return null;
  }

  String? _validateContainer(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa el contenedor';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.workCenter.name)),
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
                decoration: InputDecoration(
                  labelText: 'Etiqueta Final',
                  prefixIcon: Icon(
                    Icons.local_offer,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
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
                decoration: InputDecoration(
                  labelText: 'Ayuda visual',
                  prefixIcon: Icon(
                    Icons.article,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
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
                decoration: InputDecoration(
                  labelText: 'Contenedor',
                  prefixIcon: Icon(
                    Icons.local_shipping,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                validator: _validateContainer,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) {
                  _validateAndSubmit();
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _validateAndSubmit,
                style: ElevatedButton.styleFrom(
                  // backgroundColor: Theme.of(context).colorScheme.primary,
                  // foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1,
                    ),
                  ),
                ),
                child: const Text('Verificar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
