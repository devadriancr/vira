import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/connectivity_service.dart';
import 'views/splash_view.dart';
import 'views/login_view.dart';
import 'views/material_validation_view.dart';
import 'views/connectivity_view.dart';

void main() {
  runApp(const ViraApp());
}

class ViraApp extends StatelessWidget {
  const ViraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ConnectivityService()),
        ChangeNotifierProvider(create: (context) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Vira',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1D24CA),
            brightness: Brightness.light,
            primary: const Color(0xFF1D24CA),
            secondary: const Color(0xFF646FD4),
            tertiary: const Color(0xFF9BA3EB),
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
          extensions: <ThemeExtension<dynamic>>[
            CustomColors(
              okColor: const Color(0xFF0065F8),
              ngColor: const Color(0xFFFC3C3C),
              connectionErrorColor: const Color(0xFFFC7300),
            ),
          ],
        ),
        home: const ConnectivityWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class ConnectivityWrapper extends StatelessWidget {
  const ConnectivityWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ConnectivityView(child: const AppRouter());
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

  static CustomColors of(BuildContext context) {
    return Theme.of(context).extension<CustomColors>() ??
        const CustomColors(
          okColor: Color(0xFF1D24CA),
          ngColor: Color(0xFFFF0000),
          connectionErrorColor: Color(0xFFFF8F00),
        );
  }

  @override
  String toString() {
    return 'CustomColors(okColor: $okColor, ngColor: $ngColor, connectionErrorColor: $connectionErrorColor)';
  }
}
