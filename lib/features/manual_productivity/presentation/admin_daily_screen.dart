// features/manual_productivity/presentation/admin_daily_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tectrackerbpm/core/api/api_client.dart';
import 'package:tectrackerbpm/core/widgets/bpm_scaffold.dart';
import 'package:tectrackerbpm/core/widgets/bpm_side_menu.dart';

import '../data/admin_daily_api.dart';
import '../data/models/admin_daily_models.dart';

class AdminDailyScreen extends StatefulWidget {
  const AdminDailyScreen({Key? key}) : super(key: key);

  @override
  State<AdminDailyScreen> createState() => _AdminDailyScreenState();
}

class _AdminDailyScreenState extends State<AdminDailyScreen> {
  // ✅ La API se crea aquí, no se inyecta por constructor
  final AdminDailyApi _api = AdminDailyApi();

  // Header (BpmScaffold)
  String _companyName = 'TEC-BPM';
  String _userName = 'Usuario';
  String _displayName = '1';

  bool _loading = true;
  bool _saving = false;
  String? _error;

  AdminDailyInitResponse? _vm;
  String? _selectedIso; // yyyy-MM-dd
  final _fmt = NumberFormat('#0.##', 'es_CO');

  // Controllers cacheados por actividad + día
  final Map<String, TextEditingController> _hoursCtrls = {};
  bool _syncingControllers = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    for (final c in _hoursCtrls.values) {
      c.dispose();
    }
    _hoursCtrls.clear();
    super.dispose();
  }

  Future<void> _init() async {
    await _loadAuthData();
    await _load();
  }

  Future<void> _loadAuthData() async {
    final auth = await ApiClient().loadAuthResult();
    if (!mounted) return;

    setState(() {
      _companyName = auth?.company ?? 'TEC-BPM';
      _userName = auth?.userName ?? 'Usuario';
      _displayName = auth?.identification ?? '1';
    });
  }

  String _todayIso() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> _load({String? focusIso}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final vm = await _api.init(focusIso: focusIso);

      final cols = vm.columns;
      String? selected;
      final today = _todayIso();

      // ✅ Por defecto HOY si existe en columns
      if (cols.contains(today)) {
        selected = today;
      } else if (vm.focusIso.isNotEmpty && cols.contains(vm.focusIso)) {
        selected = vm.focusIso;
      } else if (cols.isNotEmpty) {
        selected = cols.last;
      }

      setState(() {
        _vm = vm;
        _selectedIso = selected;
      });

      _syncAllControllers();
    } catch (e) {
      setState(() => _error = 'Error al cargar: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // ===================== Helpers / data =====================
  bool _isHoliday(String iso) => _vm?.holidays.contains(iso) ?? false;

  double? _getAmount(AdminDailyInitRowDto row, String iso) {
    final idx = row.days.indexWhere((x) => x.date == iso);
    if (idx < 0) return null;
    return row.days[idx].amountHours;
  }

  void _setAmount(AdminDailyInitRowDto row, String iso, double? value) {
    final idx = row.days.indexWhere((x) => x.date == iso);
    if (idx >= 0) {
      row.days[idx].amountHours = value;
    } else {
      row.days.add(AdminDailyInitDayDto(date: iso, amountHours: value));
    }
  }

  bool _isMinuteUnit(String? unitName) {
    if (unitName == null || unitName.isEmpty) return false;

    final u = unitName.toLowerCase();
    return u.contains('minuto') || u.contains('minute');
  }

  bool _dayHasRecords(String iso) {
    final vm = _vm;
    if (vm == null) return false;

    for (final r in vm.rows) {
      final v = _getAmount(r, iso);
      if (v != null && v > 0) return true;
    }
    return false;
  }

  double _totalDayHours(String iso) {
    final vm = _vm;
    if (vm == null) return 0;

    double total = 0;

    for (final row in vm.rows) {
      final amount = _getAmount(row, iso);
      if (amount == null || amount <= 0) continue;

      final unitId = row.idTimeUnit;

      // Buscamos el nombre de la unidad
      final unitName = vm.timeUnits
          .firstWhere(
            (u) => u.idTimeUnit == unitId,
            orElse: () => AdminDailyTimeUnitDto(
              idTimeUnit: unitId ?? '',
              name: '',
              valueKey: 1,
            ),
          )
          .name;

      // 👉 CONVERSIÓN CLARA
      if (_isMinuteUnit(unitName)) {
        total += amount / 60.0; // minutos → horas
      } else {
        total += amount; // horas → horas
      }
    }

    return total;
  }

  // ===================== Controllers (para que SI pinte valores) =====================
  String _ctrlKey(AdminDailyInitRowDto row, String iso) =>
      '${row.activityId}|$iso';

  TextEditingController _getCtrl(AdminDailyInitRowDto row, String iso) {
    final key = _ctrlKey(row, iso);
    return _hoursCtrls.putIfAbsent(key, () => TextEditingController());
  }

  void _syncController(AdminDailyInitRowDto row, String iso) {
    final ctrl = _getCtrl(row, iso);
    final amount = _getAmount(row, iso);
    final desired = (amount == null || amount == 0) ? '' : _fmt.format(amount);

    if (ctrl.text != desired) {
      _syncingControllers = true;
      ctrl.text = desired;
      ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
      _syncingControllers = false;
    }
  }

  void _syncAllControllers() {
    final vm = _vm;
    final iso = _selectedIso;
    if (vm == null || iso == null) return;

    for (final r in vm.rows) {
      _syncController(r, iso);
    }
  }

  // ===================== Save =====================
  Future<void> _saveDay() async {
    final vm = _vm;
    final iso = _selectedIso;
    if (vm == null || iso == null) return;

    if (_isHoliday(iso)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Este día es festivo y no se puede registrar.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final rows = <AdminDailyClientRow>[];

      for (final r in vm.rows) {
        final amount = _getAmount(r, iso);
        if (amount == null || amount <= 0) continue;

        final unit = (r.idTimeUnit ?? '').trim();
        if (unit.isEmpty) {
          throw Exception(
              'Falta unidad de tiempo en "${r.activityCode} - ${r.activityName}".');
        }

        rows.add(
          AdminDailyClientRow(
            activityId: r.activityId,
            idTimeUnit: unit,
            date: iso,
            amount: amount.toString(),
          ),
        );
      }

      if (rows.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No hay valores para guardar en este día.')),
        );
        return;
      }

      final total = _totalDayHours(iso);
      if (vm.maxHoursPerDay > 0 && total > vm.maxHoursPerDay) {
        throw Exception(
          'El total del día (${_fmt.format(total)}h) supera el máximo permitido (${_fmt.format(vm.maxHoursPerDay)}h).',
        );
      }

      await _api.save(AdminDailyClientPayload(submitDate: iso, rows: rows));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Guardado OK para $iso')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    final vm = _vm;
    final iso = _selectedIso;

    return BpmScaffold(
      companyName: _companyName,
      userName: _userName,
      displayName: _displayName,
      drawer: BpmSideMenu(
        userName: _userName,
        companyName: _companyName,
        displayName: _displayName,
      ),
      body: Container(
        color: const Color(0xFFF4F5F7),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : (vm == null || iso == null)
                    ? const Center(child: Text('Sin datos'))
                    : Column(
                        children: [
                          _TopHeader(
                            vm: vm,
                            iso: iso,
                            isHoliday: _isHoliday(iso),
                            total: _totalDayHours(iso),
                            fmt: _fmt,
                            saving: _saving,
                            hasRecords: _dayHasRecords(iso),
                            onRefresh: () => _load(focusIso: iso),
                            onSave: _saveDay,
                            onChangeDay: (newIso) {
                              setState(() => _selectedIso = newIso);
                              _syncAllControllers(); // ✅ clave para “pintar” valores del nuevo día
                            },
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(12, 10, 12, 16),
                              itemCount: vm.rows.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final row = vm.rows[i];

                                final enabled = !_isHoliday(iso);
                                final ctrl = _getCtrl(row, iso);
                                _syncController(row, iso);

                                final amount = _getAmount(row, iso);
                                final unitMissing =
                                    (row.idTimeUnit ?? '').trim().isEmpty;
                                final hasHours = (amount != null && amount > 0);

                                return _ActivityCard(
                                  row: row,
                                  enabled: enabled,
                                  units: vm.timeUnits,
                                  hoursController: ctrl,
                                  highlightMissingUnit: unitMissing && hasHours,
                                  onChangedUnit: (val) =>
                                      setState(() => row.idTimeUnit = val),
                                  onChangedAmount: (val) {
                                    if (_syncingControllers) return;
                                    final parsed = double.tryParse(
                                        val.replaceAll(',', '.'));
                                    setState(
                                        () => _setAmount(row, iso, parsed));
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }
}

// ===================== Top header (día + total + acciones) =====================
class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.vm,
    required this.iso,
    required this.isHoliday,
    required this.total,
    required this.fmt,
    required this.saving,
    required this.onRefresh,
    required this.onSave,
    required this.onChangeDay,
    required this.hasRecords,
  });

  final AdminDailyInitResponse vm;
  final String iso;
  final bool isHoliday;
  final double total;
  final NumberFormat fmt;
  final bool saving;

  final VoidCallback onRefresh;
  final VoidCallback onSave;
  final ValueChanged<String> onChangeDay;
  final bool hasRecords;

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.tryParse(iso);
    final label =
        (dt == null) ? iso : DateFormat('EEE dd/MM', 'es_CO').format(dt);

    final statusColor =
        isHoliday ? Colors.red : (hasRecords ? Colors.green : Colors.red);

    final statusText =
        isHoliday ? 'Festivo (bloqueado)' : 'Registrando para: $label';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.06),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: iso,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Día',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: vm.columns
                      .map(
                        (d) => DropdownMenuItem<String>(
                          value: d,
                          child: Text(
                            DateFormat('EEE dd/MM', 'es_CO')
                                .format(DateTime.parse(d)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: saving
                      ? null
                      : (v) {
                          if (v == null) return;
                          onChangeDay(v);
                        },
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.blue.withOpacity(0.08),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Total (h)',
                        style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 2),
                    Text(fmt.format(total),
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                isHoliday ? Icons.event_busy : Icons.event_available,
                size: 18,
                color: isHoliday ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Refrescar',
                onPressed: saving ? null : onRefresh,
                icon: const Icon(Icons.refresh),
              ),
              ElevatedButton.icon(
                onPressed: (saving || isHoliday) ? null : onSave,
                icon: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Guardar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===================== Card =====================
class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.row,
    required this.units,
    required this.enabled,
    required this.hoursController,
    required this.highlightMissingUnit,
    required this.onChangedUnit,
    required this.onChangedAmount,
  });

  final AdminDailyInitRowDto row;
  final List<AdminDailyTimeUnitDto> units;
  final bool enabled;

  final TextEditingController hoursController;
  final bool highlightMissingUnit;

  final ValueChanged<String?> onChangedUnit;
  final ValueChanged<String> onChangedAmount;

  @override
  Widget build(BuildContext context) {
    final borderColor = highlightMissingUnit
        ? Colors.orange.withOpacity(0.85)
        : Colors.black.withOpacity(0.06);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                offset: const Offset(0, 5),
                color: Colors.black.withOpacity(0.05),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CodeBadge(code: row.activityCode),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        row.activityName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, c) {
                    final isNarrow = c.maxWidth < 360;

                    final unitField = DropdownButtonFormField<String>(
                      value:
                          (row.idTimeUnit != null && row.idTimeUnit!.isNotEmpty)
                              ? row.idTimeUnit
                              : null,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Unidad de tiempo',
                        isDense: true,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.timer_outlined),
                        helperText: highlightMissingUnit
                            ? 'Selecciona unidad (obligatoria)'
                            : null,
                        helperStyle: const TextStyle(color: Colors.orange),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('-- Seleccionar --'),
                        ),
                        ...units.map(
                          (u) => DropdownMenuItem<String>(
                            value: u.idTimeUnit,
                            child:
                                Text(u.name, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                      onChanged: enabled ? onChangedUnit : null,
                    );

                    final hoursField = TextField(
                      enabled: enabled,
                      controller: hoursController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Tiempo',
                        isDense: true,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.edit_outlined),
                      ),
                      onChanged: onChangedAmount,
                    );

                    if (isNarrow) {
                      return Column(
                        children: [
                          unitField,
                          const SizedBox(height: 10),
                          hoursField,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(flex: 2, child: unitField),
                        const SizedBox(width: 10),
                        Expanded(flex: 1, child: hoursField),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        if (!enabled)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withOpacity(0.70),
              ),
              child: const Center(
                child: Text(
                  'Bloqueado por festivo',
                  style:
                      TextStyle(fontWeight: FontWeight.w800, color: Colors.red),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CodeBadge extends StatelessWidget {
  const _CodeBadge({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.blue.withOpacity(0.10),
        border: Border.all(color: Colors.blue.withOpacity(0.20)),
      ),
      child: Text(
        code,
        style: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}
