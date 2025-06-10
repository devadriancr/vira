import 'package:flutter/material.dart';
import 'package:vira/controllers/material_validation_controller.dart';

class ValidationHistoryView extends StatefulWidget {
  const ValidationHistoryView({super.key}); // Eliminar workCenter

  @override
  State<ValidationHistoryView> createState() => _ValidationHistoryViewState();
}

class _ValidationHistoryViewState extends State<ValidationHistoryView> {
  List<Map<String, dynamic>> _validations = [];
  bool _isLoading = true;
  String? _selectedStatus;
  final List<String> _statusOptions = ['Todos', 'OK', 'NG'];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final validations =
          await MaterialValidationController.getValidationHistory(
            status: _selectedStatus == 'Todos' ? null : _selectedStatus,
          );

      setState(() {
        _validations = validations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar el historial: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text(
            'Filtrar por estado:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedStatus ?? 'Todos',
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items:
                  _statusOptions
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value == 'Todos' ? null : value;
                });
                _loadHistory();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationCard(Map<String, dynamic> validation) {
    final status = validation['validation_status'] as String;
    final isOK = status == 'OK';
    final createdAt = DateTime.parse(validation['created_at']);
    final containerCode = validation['container_code'] ?? 'N/A';
    final visualAidCode = validation['visual_aid_code'] ?? 'N/A';
    final finalLabelCode = validation['final_label_code'] ?? 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOK ? Colors.green : Colors.red,
          child: Icon(isOK ? Icons.check : Icons.close, color: Colors.white),
        ),
        title: Text(
          'Resultado: $status',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Etiqueta Final: $finalLabelCode'),
            Text('Ayuda Visual: $visualAidCode'),
            Text('Contenedor: $containerCode'),
            Text(
              '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color:
                isOK
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOK ? Colors.green : Colors.red,
              width: 1,
            ),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: isOK ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Validaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusFilter(),
          const Divider(height: 1),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _validations.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay validaciones registradas',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _loadHistory,
                      child: ListView.builder(
                        itemCount: _validations.length,
                        itemBuilder: (context, index) {
                          return _buildValidationCard(_validations[index]);
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
