// lib/views/login_view.dart (actualizado - solo mostrar los cambios principales)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vira/services/auth_service.dart';

extension StringExtension on String {
  String toTitleCase() {
    return split(' ')
        .map(
          (word) =>
              word.isNotEmpty
                  ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                  : word,
        )
        .join(' ');
  }
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _selectedUserNickname;

  @override
  void initState() {
    super.initState();
    // Cargar usuarios cuando se inicializa la vista
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = context.read<AuthService>();
      authService.loadScanUsers();

      // Si hay sesión expirada, mostrar mensaje
      if (authService.sessionExpired) {
        _showSessionExpiredDialog();
      }
    });
  }

  void _showSessionExpiredDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder:
              (context) => AlertDialog(
                icon: Icon(Icons.schedule, color: Colors.orange, size: 48),
                title: Text('Sesión Expirada'),
                content: Text(
                  'Tu sesión ha caducado por seguridad. Por favor, inicia sesión nuevamente.',
                  style: TextStyle(fontSize: 16),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Limpiar el error después de cerrar el diálogo
                      context.read<AuthService>().clearError();
                    },
                    child: Text('Entendido'),
                  ),
                ],
              ),
        );
      }
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authService = context.read<AuthService>();

      await authService.login(_selectedUserNickname!, _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 600;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.precision_manufacturing,
                      size: isSmallScreen ? 60 : 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 32),
                    Text(
                      'Escaneo de Tres Puntos',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 22 : null,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 24 : 48),

                    // Selector de usuario
                    Consumer<AuthService>(
                      builder: (context, authService, child) {
                        return DropdownButtonFormField<String>(
                          value: _selectedUserNickname,
                          decoration: InputDecoration(
                            labelText: 'Seleccionar Usuario',
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            suffixIcon:
                                authService.loadingUsers
                                    ? Container(
                                      width: 20,
                                      height: 20,
                                      padding: const EdgeInsets.all(12),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      ),
                                    )
                                    : null,
                          ),
                          items:
                              authService.scanUsers
                                  .map(
                                    (user) => DropdownMenuItem<String>(
                                      value: user.nickname,
                                      child: Text(user.name.toTitleCase()),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              authService.loadingUsers
                                  ? null
                                  : (value) {
                                    setState(() {
                                      _selectedUserNickname = value;
                                    });
                                  },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor selecciona un usuario';
                            }
                            return null;
                          },
                          isExpanded: true,
                          hint:
                              authService.loadingUsers
                                  ? Text('Cargando usuarios...')
                                  : Text('Selecciona un usuario'),
                        );
                      },
                    ),

                    SizedBox(height: isSmallScreen ? 12 : 16),

                    // Campo de contraseña
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu contraseña';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: isSmallScreen ? 24 : 32),

                    Consumer<AuthService>(
                      builder: (context, authService, child) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton(
                              onPressed:
                                  authService.isLoading ||
                                          _selectedUserNickname == null
                                      ? null
                                      : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child:
                                  authService.isLoading
                                      ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                      : const Text('Iniciar Sesión'),
                            ),

                            // Mostrar mensaje de error (incluyendo sesión expirada)
                            if (authService.error != null &&
                                !authService.sessionExpired) ...[
                              SizedBox(height: isSmallScreen ? 12 : 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red[300]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red[600],
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        authService.error!,
                                        style: TextStyle(
                                          color: Colors.red[600],
                                          fontSize: isSmallScreen ? 12 : 14,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: authService.clearError,
                                      iconSize: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        );
                      },
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
