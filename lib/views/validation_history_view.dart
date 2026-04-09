import 'package:flutter/material.dart';
import 'package:vira/controllers/material_validation_controller.dart';
import 'package:provider/provider.dart';
import 'package:vira/services/auth_service.dart';

class ValidationHistoryView extends StatefulWidget {
  const ValidationHistoryView({super.key});

  @override
  State<ValidationHistoryView> createState() => _ValidationHistoryViewState();
}

class _ValidationHistoryViewState extends State<ValidationHistoryView>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _validations = [];
  bool _isLoading = true;
  String? _selectedStatus;
  final List<String> _statusOptions = ['Todos', 'OK', 'NG'];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadWeeklyHistory();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadWeeklyHistory() async {
    setState(() => _isLoading = true);

    try {
      final validations =
          await MaterialValidationController.getValidationHistory(
            status: _selectedStatus == 'Todos' ? null : _selectedStatus,
          );

      setState(() {
        _validations = validations;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  String _getWeekRange() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 6));

    return '${start.day}-${start.month} a ${end.day}-${end.month}';
  }

  Widget _buildHeader() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.user;
    final userName = currentUser?.name ?? 'Usuario';

    final okCount =
        _validations.where((v) => v['validation_status'] == 'OK').length;
    final ngCount =
        _validations.where((v) => v['validation_status'] == 'NG').length;
    final total = _validations.length;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          children: [
            // Título con icono
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 350;

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade400,
                                Colors.blue.shade600,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade200,
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.analytics_outlined,
                            color: Colors.white,
                            size: isSmallScreen ? 20 : 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Resumen Semanal',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 18 : 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Semana ${_getWeekRange()}',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 13 : 16,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Usuario: $userName',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 14,
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Cards de estadísticas - MEJORADO PARA RESPONSIVE
            LayoutBuilder(
              builder: (context, constraints) {
                // Si es muy pequeño, mostrar en columna
                if (constraints.maxWidth < 300) {
                  return Column(
                    children: [
                      _buildStatCard(
                        'TOTAL',
                        total,
                        Colors.blue,
                        Icons.inventory_2_outlined,
                        isFullWidth: true,
                      ),
                      const SizedBox(height: 8),
                      _buildStatCard(
                        'OK',
                        okCount,
                        Colors.green,
                        Icons.check_circle_outline,
                        isFullWidth: true,
                      ),
                      const SizedBox(height: 8),
                      _buildStatCard(
                        'NG',
                        ngCount,
                        Colors.red,
                        Icons.error_outline,
                        isFullWidth: true,
                      ),
                    ],
                  );
                }

                // Modo normal en fila
                return Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'TOTAL',
                        total,
                        Colors.blue,
                        Icons.inventory_2_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'OK',
                        okCount,
                        Colors.green,
                        Icons.check_circle_outline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'NG',
                        ngCount,
                        Colors.red,
                        Icons.error_outline,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // El resto del código permanece exactamente igual...
  // [Mantengo todos los demás métodos sin cambios]

  Widget _buildStatCard(
    String label,
    int count,
    Color color,
    IconData icon, {
    bool isFullWidth = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = !isFullWidth && constraints.maxWidth < 100;

        return Container(
          padding: EdgeInsets.all(isSmall ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isSmall ? 6 : 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: isSmall ? 18 : 24),
              ),
              SizedBox(height: isSmall ? 8 : 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: isSmall ? 20 : 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmall ? 11 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 300;

          // Si es muy pequeño, mostrar en columna
          if (isSmallScreen) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.filter_alt_outlined,
                        size: 18,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Filtrar por estado:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDropdown(),
              ],
            );
          }

          // Modo normal en fila
          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.filter_alt_outlined,
                  size: 20,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Filtrar por estado:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildDropdown()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.grey.shade50,
      ),
      child: DropdownButton<String>(
        value: _selectedStatus ?? 'Todos',
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: Colors.white,
        items:
            _statusOptions.map((status) {
              Color? statusColor;
              IconData? statusIcon;

              switch (status) {
                case 'OK':
                  statusColor = Colors.green;
                  statusIcon = Icons.check_circle;
                  break;
                case 'NG':
                  statusColor = Colors.red;
                  statusIcon = Icons.error;
                  break;
                default:
                  statusColor = Colors.grey.shade600;
                  statusIcon = Icons.list;
              }

              return DropdownMenuItem(
                value: status,
                child: Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        onChanged: (value) {
          setState(() => _selectedStatus = value == 'Todos' ? null : value);
          _animationController.reset();
          _loadWeeklyHistory();
        },
      ),
    );
  }

  Widget _buildValidationCard(Map<String, dynamic> validation, int index) {
    final status = validation['validation_status'] as String;
    final isOK = status == 'OK';
    final createdAtString = validation['created_at'] as String;

    DateTime createdAt;
    try {
      createdAt = DateTime.parse(createdAtString).toLocal();
    } catch (e) {
      createdAt = DateTime.now();
    }

    final labelCode = validation['final_label_code'] ?? 'N/A';
    final containerCode = validation['container_code'] ?? 'N/A';
    final visualAidCode = validation['visual_aid_code'] ?? 'N/A';

    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutBack,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isOK ? Colors.green : Colors.red).withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: (isOK ? Colors.green : Colors.red).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // Navegación a detalles
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // HEADER - MEJORADO PARA RESPONSIVE
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isSmallScreen = constraints.maxWidth < 300;

                      if (isSmallScreen) {
                        // Layout vertical para pantallas muy pequeñas
                        return Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color:
                                        isOK
                                            ? Colors.green.shade50
                                            : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          isOK
                                              ? Colors.green.shade200
                                              : Colors.red.shade200,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    isOK
                                        ? Icons.check_circle
                                        : Icons.error_outline,
                                    color:
                                        isOK
                                            ? Colors.green.shade600
                                            : Colors.red.shade600,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        labelCode,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatDateTime(createdAt),
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isOK
                                          ? Colors.green.shade600
                                          : Colors.red.shade600,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      // Layout horizontal normal
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  isOK
                                      ? Colors.green.shade50
                                      : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    isOK
                                        ? Colors.green.shade200
                                        : Colors.red.shade200,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              isOK ? Icons.check_circle : Icons.error_outline,
                              color:
                                  isOK
                                      ? Colors.green.shade600
                                      : Colors.red.shade600,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  labelCode,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDateTime(createdAt),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isOK
                                      ? Colors.green.shade600
                                      : Colors.red.shade600,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // INFO ADICIONAL - MEJORADO PARA RESPONSIVE
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Si es muy pequeño, mostrar en columna
                        if (constraints.maxWidth < 250) {
                          return Column(
                            children: [
                              _buildInfoChip(
                                'Contenedor',
                                containerCode,
                                Icons.inventory,
                                isFullWidth: true,
                              ),
                              const SizedBox(height: 8),
                              _buildInfoChip(
                                'Visual Aid',
                                visualAidCode,
                                Icons.visibility,
                                isFullWidth: true,
                              ),
                            ],
                          );
                        }

                        // Modo normal en fila
                        return Row(
                          children: [
                            Expanded(
                              child: _buildInfoChip(
                                'Contenedor',
                                containerCode,
                                Icons.inventory,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoChip(
                                'Visual Aid',
                                visualAidCode,
                                Icons.visibility,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    String label,
    String value,
    IconData icon, {
    bool isFullWidth = false,
  }) {
    return Column(
      crossAxisAlignment:
          isFullWidth ? CrossAxisAlignment.start : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No hay validaciones',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No se encontraron validaciones para esta semana',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final localTime = dateTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(localTime.year, localTime.month, localTime.day);

    String dayText;
    if (date == today) {
      dayText = 'Hoy';
    } else if (date == yesterday) {
      dayText = 'Ayer';
    } else {
      final weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      dayText = weekdays[date.weekday - 1];
    }

    final hour = localTime.hour;
    final minute = localTime.minute;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;

    final time = '$hour12:${minute.toString().padLeft(2, '0')} $ampm';
    return '$dayText • $time';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Historial de Validaciones',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        shadowColor: Colors.grey.shade200,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.refresh, color: Colors.blue.shade600),
              onPressed: () {
                _animationController.reset();
                _loadWeeklyHistory();
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          _buildStatusFilter(),
          const SizedBox(height: 12),
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                    : _validations.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                      onRefresh: _loadWeeklyHistory,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _validations.length,
                        itemBuilder: (context, index) {
                          return _buildValidationCard(
                            _validations[index],
                            index,
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
