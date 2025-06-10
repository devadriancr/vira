import 'package:flutter/material.dart';
import 'package:vira/controllers/material_validation_controller.dart';

class ValidationStatisticsView extends StatefulWidget {
  const ValidationStatisticsView({super.key}); // Eliminar parámetro workCenter

  @override
  State<ValidationStatisticsView> createState() =>
      _ValidationStatisticsViewState();
}

class _ValidationStatisticsViewState extends State<ValidationStatisticsView> {
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final statistics =
          await MaterialValidationController.getValidationStatistics();

      setState(() {
        _statistics = statistics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar estadísticas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStatisticCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessRateChart(double successRate) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Tasa de Éxito',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              width: 120,
              child: Stack(
                children: [
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey[300]!,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: CircularProgressIndicator(
                      value: successRate / 100,
                      strokeWidth: 12,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        successRate >= 80
                            ? Colors.green
                            : successRate >= 60
                            ? Colors.orange
                            : Colors.red,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        '${successRate.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _getSuccessRateMessage(successRate),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  String _getSuccessRateMessage(double rate) {
    if (rate >= 95) return '¡Excelente desempeño!';
    if (rate >= 85) return 'Muy buen desempeño';
    if (rate >= 70) return 'Buen desempeño';
    if (rate >= 50) return 'Desempeño regular';
    return 'Necesita mejorar';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas Generales'), // Título actualizado
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _statistics == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No se pudieron cargar las estadísticas',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadStatistics,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadStatistics,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tarjetas de estadísticas
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: [
                          _buildStatisticCard(
                            title: 'Total de\nValidaciones',
                            value: _statistics!['total_validations'].toString(),
                            icon: Icons.assignment,
                            color: Colors.blue,
                          ),
                          _buildStatisticCard(
                            title: 'Validaciones\nExitosas',
                            value: _statistics!['ok_validations'].toString(),
                            icon: Icons.check_circle,
                            color: Colors.green,
                          ),
                          _buildStatisticCard(
                            title: 'Validaciones\nFallidas',
                            value: _statistics!['ng_validations'].toString(),
                            icon: Icons.cancel,
                            color: Colors.red,
                          ),
                          _buildStatisticCard(
                            title: 'Tasa de\nÉxito',
                            value: '${_statistics!['success_rate']}%',
                            icon: Icons.trending_up,
                            color:
                                _statistics!['success_rate'] >= 80
                                    ? Colors.green
                                    : _statistics!['success_rate'] >= 60
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Gráfico circular de tasa de éxito
                      _buildSuccessRateChart(
                        _statistics!['success_rate'].toDouble(),
                      ),
                      const SizedBox(height: 24),
                      // Información adicional - Eliminada la sección de centro de trabajo
                      // Podemos agregar información alternativa si es necesario
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Resumen de Actividad',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Estadísticas globales de todas las validaciones',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
