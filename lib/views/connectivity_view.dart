import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';

class ConnectivityView extends StatelessWidget {
  final Widget child;

  const ConnectivityView({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, service, _) {
        if (service.status == ConnectivityStatus.connected) {
          return child;
        }

        return ConnectivityErrorView(onRetry: service.checkConnectivity);
      },
    );
  }
}

class ConnectivityErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const ConnectivityErrorView({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 64, color: Colors.orange),
              const SizedBox(height: 24),
              const Text(
                'Sin conexión',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'No se pudo conectar al servidor',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              const Text(
                'Verifica tu conexión a internet e intenta nuevamente',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Reintentar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
