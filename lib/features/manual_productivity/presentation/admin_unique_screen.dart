import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tectrackerbpm/core/api/api_client.dart';
import 'package:tectrackerbpm/core/widgets/bpm_scaffold.dart';
import 'package:tectrackerbpm/core/widgets/bpm_side_menu.dart';

import '../data/admin_unique_api.dart';

class AdminUniqueScreen extends StatefulWidget {
  const AdminUniqueScreen({Key? key}) : super(key: key);

  @override
  State<AdminUniqueScreen> createState() => _AdminUniqueScreenState();
}

class _AdminUniqueScreenState extends State<AdminUniqueScreen> {
  final _api = AdminUniqueApi();

  // Header (BpmScaffold)
  String _companyName = 'TEC-BPM';
  String _userName = 'Usuario';
  String _displayName = '1';

  bool _loading = true;
  bool _saving = false;
  String? _error;

  AdminUniqueInitResponse? _vm;

  // Form state (crear/editar)
  String? _editingIdAnswersAdmin;
  String? _activityId;
  String? _timeUnitId;
  String? _freqUnitId;

  final _amountCtrl = TextEditingController();
  final _txCtrl = TextEditingController(text: '1');

  final _fmt = NumberFormat('#0.##', 'es_CO');

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _txCtrl.dispose();
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final vm = await _api.init();
      setState(() => _vm = vm);
    } catch (e) {
      setState(() => _error = 'Error al cargar datos: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _resetForm() {
    setState(() {
      _editingIdAnswersAdmin = null;
      _activityId = null;
      _timeUnitId = null;
      _freqUnitId = null;
      _amountCtrl.text = '';
      _txCtrl.text = '1';
    });
  }

  void _loadEntryToForm(AdminUniqueEntryDto e) {
    setState(() {
      _editingIdAnswersAdmin = e.idAnswersAdmin;
      _activityId = e.activityId;
      _timeUnitId = e.idTimeUnit;
      _freqUnitId = e.idFrequencyUnit;
      _amountCtrl.text = _fmt.format(e.amount);
      _txCtrl.text = e.numberTransactions.toString();
    });
  }

  double _safeParseDouble(String s) {
    final v = s.trim().replaceAll(',', '.');
    return double.tryParse(v) ?? 0;
  }

  int _safeParseInt(String s, {int fallback = 1}) {
    final v = int.tryParse(s.trim());
    if (v == null || v <= 0) return fallback;
    return v;
  }

  Future<void> _save() async {
    final vm = _vm;
    if (vm == null) return;

    final act = (_activityId ?? '').trim();
    final tu = (_timeUnitId ?? '').trim();
    final fu = (_freqUnitId ?? '').trim();
    final amount = _safeParseDouble(_amountCtrl.text);
    final tx = _safeParseInt(_txCtrl.text);

    if (act.isEmpty) return _toast('Selecciona una actividad.');
    if (tu.isEmpty) return _toast('Selecciona unidad de tiempo.');
    if (fu.isEmpty) return _toast('Selecciona unidad de frecuencia.');
    if (amount <= 0) return _toast('El valor debe ser mayor que 0.');

    setState(() => _saving = true);

    try {
      final req = AdminUniqueSaveRequest(
        idAnswersAdmin: _editingIdAnswersAdmin,
        activityId: act,
        amount: amount,
        numberTransactions: tx,
        idTimeUnit: tu,
        idFrequencyUnit: fu,
      );

      final result = await _api.save(req);

      // refrescar VM rápido: o recargas, o aplicas patch local.
      // Aquí: patch local para que se sienta instantáneo.
      setState(() {
        // total desde backend
        final updatedTotal = result.totalCalculation;

        // buscar entry existente
        final existingIdx = vm.entries
            .indexWhere((x) => x.idAnswersAdmin == result.idAnswersAdmin);
        if (existingIdx >= 0) {
          final old = vm.entries[existingIdx];
          vm.entries[existingIdx] = AdminUniqueEntryDto(
            idAnswersAdmin: result.idAnswersAdmin,
            activityId: result.activityId,
            activityCode: old.activityCode,
            activityName: old.activityName,
            amount: result.amount,
            numberTransactions: result.numberTransactions,
            idTimeUnit: result.idTimeUnit,
            timeUnitName:
                vm.timeUnits.firstWhere((x) => x.id == result.idTimeUnit).name,
            idFrequencyUnit: result.idFrequencyUnit,
            frequencyUnitName: vm.frequencyUnits
                .firstWhere((x) => x.id == result.idFrequencyUnit)
                .name,
            calculation: result.calculation,
          );
        } else {
          // crear: necesitamos nombre/código desde activities
          final a = vm.activities
              .firstWhere((x) => x.activityId == result.activityId);
          vm.entries.insert(
            0,
            AdminUniqueEntryDto(
              idAnswersAdmin: result.idAnswersAdmin,
              activityId: result.activityId,
              activityCode: a.code,
              activityName: a.name,
              amount: result.amount,
              numberTransactions: result.numberTransactions,
              idTimeUnit: result.idTimeUnit,
              timeUnitName: vm.timeUnits
                  .firstWhere((x) => x.id == result.idTimeUnit)
                  .name,
              idFrequencyUnit: result.idFrequencyUnit,
              frequencyUnitName: vm.frequencyUnits
                  .firstWhere((x) => x.id == result.idFrequencyUnit)
                  .name,
              calculation: result.calculation,
            ),
          );
        }

        // reconstruir vm (inmutable “manual”)
        _vm = AdminUniqueInitResponse(
          activities: vm.activities,
          timeUnits: vm.timeUnits,
          frequencyUnits: vm.frequencyUnits,
          entries: vm.entries,
          totalCalculation: updatedTotal,
          maxHoursPerDay: result.maxHoursPerDay,
        );
      });

      _toast(_editingIdAnswersAdmin == null
          ? 'Registro creado.'
          : 'Registro actualizado.');
      _resetForm();
    } catch (e) {
      _toast('Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(AdminUniqueEntryDto e) async {
    final vm = _vm;
    if (vm == null) return;

    try {
      await _api.delete(e.idAnswersAdmin);

      setState(() {
        vm.entries.removeWhere((x) => x.idAnswersAdmin == e.idAnswersAdmin);
        final newTotal =
            vm.entries.fold<double>(0, (p, n) => p + n.calculation);

        _vm = AdminUniqueInitResponse(
          activities: vm.activities,
          timeUnits: vm.timeUnits,
          frequencyUnits: vm.frequencyUnits,
          entries: vm.entries,
          totalCalculation: newTotal,
          maxHoursPerDay: vm.maxHoursPerDay,
        );
      });

      _toast('Registro eliminado.');
    } catch (ex) {
      _toast('Error al eliminar: $ex');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm;

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
                : vm == null
                    ? const Center(child: Text('Sin datos'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                          children: [
                            _SummaryCard(
                              total: vm.totalCalculation,
                              max: vm.maxHoursPerDay,
                              fmt: _fmt,
                              onReset: _resetForm,
                              editing: _editingIdAnswersAdmin != null,
                            ),
                            const SizedBox(height: 12),
                            _FormCard(
                              saving: _saving,
                              vm: vm,
                              activityId: _activityId,
                              timeUnitId: _timeUnitId,
                              freqUnitId: _freqUnitId,
                              amountCtrl: _amountCtrl,
                              txCtrl: _txCtrl,
                              onChangeActivity: (v) =>
                                  setState(() => _activityId = v),
                              onChangeTimeUnit: (v) =>
                                  setState(() => _timeUnitId = v),
                              onChangeFreqUnit: (v) =>
                                  setState(() => _freqUnitId = v),
                              onSave: _save,
                              onCancelEdit: _editingIdAnswersAdmin == null
                                  ? null
                                  : _resetForm,
                              editing: _editingIdAnswersAdmin != null,
                            ),
                            const SizedBox(height: 12),
                            _EntriesHeader(count: vm.entries.length),
                            const SizedBox(height: 10),
                            if (vm.entries.isEmpty)
                              const _EmptyState()
                            else
                              ...vm.entries.map((e) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Dismissible(
                                    key: ValueKey(e.idAnswersAdmin),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(Icons.delete_outline,
                                          color: Colors.red),
                                    ),
                                    confirmDismiss: (_) async {
                                      return await showDialog<bool>(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text(
                                                  'Eliminar registro'),
                                              content: Text(
                                                  '¿Eliminar "${e.activityCode} - ${e.activityName}"?'),
                                              actions: [
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, false),
                                                    child:
                                                        const Text('Cancelar')),
                                                ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, true),
                                                    child:
                                                        const Text('Eliminar')),
                                              ],
                                            ),
                                          ) ??
                                          false;
                                    },
                                    onDismissed: (_) => _delete(e),
                                    child: _EntryCard(
                                      entry: e,
                                      fmt: _fmt,
                                      onEdit: () => _loadEntryToForm(e),
                                    ),
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
      ),
    );
  }
}

/* ===================== Widgets UI ===================== */

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.total,
    required this.max,
    required this.fmt,
    required this.onReset,
    required this.editing,
  });

  final double total;
  final double max;
  final NumberFormat fmt;
  final VoidCallback onReset;
  final bool editing;

  @override
  Widget build(BuildContext context) {
    final pct = (max <= 0) ? 0.0 : (total / max).clamp(0.0, 1.0);
    final danger = max > 0 && total > max;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
              blurRadius: 14,
              offset: const Offset(0, 8),
              color: Colors.black.withOpacity(0.06)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assessment_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Resumen del día (Unique)',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              if (editing)
                TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.close),
                  label: const Text('Salir edición'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _Kpi(label: 'Total', value: '${fmt.format(total)} h')),
              const SizedBox(width: 10),
              Expanded(
                  child: _Kpi(label: 'Máximo', value: '${fmt.format(max)} h')),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: Colors.grey.withOpacity(0.15),
              valueColor:
                  AlwaysStoppedAnimation(danger ? Colors.red : Colors.blue),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            danger ? 'Supera el máximo permitido.' : 'Dentro del límite.',
            style: TextStyle(
                color: danger ? Colors.red : Colors.green,
                fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.blue.withOpacity(0.06),
        border: Border.all(color: Colors.blue.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.saving,
    required this.vm,
    required this.activityId,
    required this.timeUnitId,
    required this.freqUnitId,
    required this.amountCtrl,
    required this.txCtrl,
    required this.onChangeActivity,
    required this.onChangeTimeUnit,
    required this.onChangeFreqUnit,
    required this.onSave,
    required this.onCancelEdit,
    required this.editing,
  });

  final bool saving;
  final AdminUniqueInitResponse vm;

  final String? activityId;
  final String? timeUnitId;
  final String? freqUnitId;

  final TextEditingController amountCtrl;
  final TextEditingController txCtrl;

  final ValueChanged<String?> onChangeActivity;
  final ValueChanged<String?> onChangeTimeUnit;
  final ValueChanged<String?> onChangeFreqUnit;

  final VoidCallback onSave;
  final VoidCallback? onCancelEdit;
  final bool editing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(editing ? Icons.edit_note : Icons.add_circle_outline),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  editing ? 'Editar registro' : 'Agregar registro',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              if (editing && onCancelEdit != null)
                TextButton(
                  onPressed: saving ? null : onCancelEdit,
                  child: const Text('Cancelar'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: activityId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Actividad',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.work_outline),
            ),
            items: vm.activities
                .map((a) => DropdownMenuItem(
                      value: a.activityId,
                      child: Text('${a.code} - ${a.name}',
                          overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: saving ? null : onChangeActivity,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: timeUnitId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Unidad de tiempo',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.timer_outlined),
                  ),
                  items: vm.timeUnits
                      .map((u) => DropdownMenuItem(
                          value: u.id,
                          child: Text(u.name, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: saving ? null : onChangeTimeUnit,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: freqUnitId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Unidad de frecuencia',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.repeat),
                  ),
                  items: vm.frequencyUnits
                      .map((u) => DropdownMenuItem(
                          value: u.id,
                          child: Text(u.name, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: saving ? null : onChangeFreqUnit,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: amountCtrl,
                  enabled: !saving,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Valor (Amount)',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.edit_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: txCtrl,
                  enabled: !saving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '# Trans.',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.numbers),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: saving ? null : onSave,
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: Text(editing ? 'Guardar cambios' : 'Guardar registro'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntriesHeader extends StatelessWidget {
  const _EntriesHeader({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.list_alt_outlined),
        const SizedBox(width: 8),
        Text('Registros ($count)',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.fmt,
    required this.onEdit,
  });

  final AdminUniqueEntryDto entry;
  final NumberFormat fmt;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
                blurRadius: 10,
                offset: const Offset(0, 6),
                color: Colors.black.withOpacity(0.05)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _CodeBadge(code: entry.activityCode),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.activityName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                const Icon(Icons.edit, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ChipInfo(icon: Icons.timer_outlined, text: entry.timeUnitName),
                _ChipInfo(icon: Icons.repeat, text: entry.frequencyUnitName),
                _ChipInfo(
                    icon: Icons.numbers,
                    text: 'Tx: ${entry.numberTransactions}'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: Text('Amount: ${fmt.format(entry.amount)}',
                        style: const TextStyle(fontWeight: FontWeight.w700))),
                Text('Calc: ${fmt.format(entry.calculation)} h',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
                'Tip: toca la tarjeta para editar · desliza para eliminar',
                style: TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class _ChipInfo extends StatelessWidget {
  const _ChipInfo({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.blue.withOpacity(0.06),
        border: Border.all(color: Colors.blue.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.blueGrey),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: const Row(
        children: [
          Icon(Icons.inbox_outlined),
          SizedBox(width: 10),
          Expanded(
              child: Text(
                  'No hay registros todavía. Usa el formulario de arriba para crear uno.')),
        ],
      ),
    );
  }
}
