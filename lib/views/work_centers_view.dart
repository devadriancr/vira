import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class WorkCentersView extends StatelessWidget {
  const WorkCentersView({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    // Mostrar diálogo de confirmación
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
              // Container(
              //   width: double.infinity,
              //   padding: const EdgeInsets.all(16),
              //   child: Container(
              //     padding: const EdgeInsets.all(16),
              //     decoration: BoxDecoration(
              //       color: Theme.of(context).colorScheme.primaryContainer,
              //       borderRadius: BorderRadius.circular(12),
              //     ),
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         Text(
              //           'Bienvenido, ${user?.name}',
              //           style: Theme.of(context).textTheme.headlineSmall
              //               ?.copyWith(fontWeight: FontWeight.bold),
              //         ),
              //         const SizedBox(height: 4),
              //         Text(
              //           user?.email ?? '',
              //           style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              //             color: Colors.grey[600],
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
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
                              Text(
                                'Estaciones (${workCenters.length})',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
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
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                            borderRadius: BorderRadius.circular(
                                              25,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              workCenter.number,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          workCenter.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            if (workCenter.line != null)
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.linear_scale,
                                                    size: 16,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Línea: ${workCenter.line!.name}',
                                                  ),
                                                ],
                                              ),
                                            if (workCenter.ip != null) ...[
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.computer,
                                                    size: 16,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text('IP: ${workCenter.ip}'),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                        trailing: const Icon(
                                          Icons.arrow_forward_ios,
                                        ),
                                        onTap: () {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Seleccionaste: ${workCenter.name}',
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
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
