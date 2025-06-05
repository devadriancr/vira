import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'views/splash_view.dart';
import 'views/login_view.dart';
import 'views/work_centers_view.dart';

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
        // Si está cargando inicialmente o cerrando sesión, mostrar splash
        if (authService.isLoading || authService.isLoggingOut) {
          return const SplashView();
        }

        // Si está autenticado, mostrar centros de trabajo
        if (authService.isAuthenticated) {
          return const WorkCentersView();
        }

        // Si no está autenticado, mostrar login
        return const LoginView();
      },
    );
  }
}
