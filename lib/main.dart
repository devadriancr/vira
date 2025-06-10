import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'views/splash_view.dart';
import 'views/login_view.dart';
import 'views/material_validation_view.dart';

void main() {
  runApp(const ViraApp());
}

class ViraApp extends StatelessWidget {
  const ViraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: MaterialApp(
        title: 'Vira',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0000FF), // Azul puro
            brightness: Brightness.light,
            // primary: const Color(0xFF0000FF),
            primary: const Color(0xFF1565C0),
            secondary: const Color(0xFF42A5F5), // Azul claro
            tertiary: const Color(0xFF90CAF9), // Azul muy claro
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          // Colores personalizados para la aplicación
          extensions: <ThemeExtension<dynamic>>[
            CustomColors(
              okColor: const Color(0xFF0000FF),
              ngColor: const Color(0xFFFF0000),
              connectionErrorColor: const Color(
                0xFFFF8F00,
              ), // Naranja para errores de conexión
            ),
          ],
        ),
        home: const AppRouter(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.isLoading || authService.isLoggingOut) {
          return const SplashView();
        }
        if (authService.isAuthenticated) {
          return const MaterialValidationView();
        }
        return const LoginView();
      },
    );
  }
}

@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  const CustomColors({
    required this.okColor,
    required this.ngColor,
    required this.connectionErrorColor,
  });

  final Color okColor;
  final Color ngColor;
  final Color connectionErrorColor;

  @override
  CustomColors copyWith({
    Color? okColor,
    Color? ngColor,
    Color? connectionErrorColor,
  }) {
    return CustomColors(
      okColor: okColor ?? this.okColor,
      ngColor: ngColor ?? this.ngColor,
      connectionErrorColor: connectionErrorColor ?? this.connectionErrorColor,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) {
      return this;
    }
    return CustomColors(
      okColor: Color.lerp(okColor, other.okColor, t) ?? okColor,
      ngColor: Color.lerp(ngColor, other.ngColor, t) ?? ngColor,
      connectionErrorColor:
          Color.lerp(connectionErrorColor, other.connectionErrorColor, t) ??
          connectionErrorColor,
    );
  }

  // Método estático para acceder fácilmente a los colores desde el contexto
  static CustomColors of(BuildContext context) {
    return Theme.of(context).extension<CustomColors>() ??
        const CustomColors(
          okColor: Color(0xFF0000FF), // Azul por defecto
          ngColor: Color(0xFFFF0000), // Rojo por defecto
          connectionErrorColor: Color(0xFFFF8F00), // Naranja por defecto
        );
  }

  @override
  String toString() {
    return 'CustomColors(okColor: $okColor, ngColor: $ngColor, connectionErrorColor: $connectionErrorColor)';
  }
}
