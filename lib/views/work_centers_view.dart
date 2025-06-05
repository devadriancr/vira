import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'material_validation_view.dart';

class WorkCentersView extends StatelessWidget {
  const WorkCentersView({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    // Mostrar diálogo de confirmación
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            // Corregida la indentación
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
      // Cerrar el popup menu primero
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Ejecutar logout
      await context.read<AuthService>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Centros de Trabajo'),
        actions: [
          Consumer<AuthService>(
            builder: (context, authService, child) {
              return PopupMenuButton(
                icon: const Icon(Icons.account_circle),
                itemBuilder:
                    (context) => [
                      PopupMenuItem(
                        child: ListTile(
                          leading:
                              authService.isLoggingOut
                                  ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.logout),
                          title: Text(
                            authService.isLoggingOut
                                ? 'Cerrando...'
                                : 'Cerrar Sesión',
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                        onTap:
                            authService.isLoggingOut
                                ? null
                                : () => _handleLogout(context),
                      ),
                    ],
              );
            },
          ),
        ],
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          final workCenters = authService.workCenters;

          return Column(
            children: [
              Expanded(
                child:
                    workCenters.isEmpty
                        ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.work_off_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No tienes centros de trabajo asignados',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                        : Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  itemCount: workCenters.length,
                                  itemBuilder: (context, index) {
                                    final workCenter = workCenters[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      elevation: 2,
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.all(
                                          16,
                                        ),
                                        leading: Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ) // Corregido: usar Theme.of(context)
                                            .colorScheme.primary.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              25,
                                            ),
                                            border: Border.all(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                              width: 2,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.precision_manufacturing,
                                            color:
                                                Theme.of(context) // Corregido
                                                .colorScheme.primary,
                                            size: 30,
                                          ),
                                        ),
                                        title: Text(
                                          workCenter.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        subtitle:
                                            workCenter.line != null
                                                ? Text(
                                                  '${workCenter.line!.name}',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 14,
                                                  ),
                                                )
                                                : null,
                                        trailing: const Icon(
                                          Icons.arrow_forward_ios,
                                        ),
                                        onTap: () {
                                          // Navegar a la nueva vista de validación de materiales
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      MaterialValidationView(
                                                        workCenter: workCenter,
                                                      ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
              ),
            ],
          );
        },
      ),
    );
  }
}
