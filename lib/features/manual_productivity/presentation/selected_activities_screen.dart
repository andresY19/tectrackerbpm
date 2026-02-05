import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tectrackerbpm/core/api/api_client.dart';
import 'package:tectrackerbpm/core/widgets/bpm_scaffold.dart';
import 'package:tectrackerbpm/core/widgets/bpm_side_menu.dart';
import 'package:tectrackerbpm/core/widgets/bpm_toast.dart';

class ActivityNode {
  final String id;
  final String code;
  final String name;
  final int level;
  final List<ActivityNode> children;

  ActivityNode({
    required this.id,
    required this.code,
    required this.name,
    required this.level,
    this.children = const [],
  });

  bool get isLeaf => children.isEmpty;

  factory ActivityNode.fromJson(Map<String, dynamic> json) {
    return ActivityNode(
      id: json['Id'] as String,
      code: json['Code'] as String,
      name: json['Name'] as String,
      level: json['Level'] as int,
      children: (json['Children'] as List<dynamic>? ?? [])
          .map((c) => ActivityNode.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SelectedActivity {
  final String id; // IdSelectedActivitiesAdmin
  final String activityId;
  final String code;
  final String name;

  SelectedActivity({
    required this.id,
    required this.activityId,
    required this.code,
    required this.name,
  });

  factory SelectedActivity.fromJson(Map<String, dynamic> json) {
    return SelectedActivity(
      id: json['IdSelectedActivitiesAdmin'].toString(),
      activityId: json['ActivityId'].toString(),
      code: json['Code'] as String,
      name: json['Name'] as String,
    );
  }
}

class SelectedActivitiesScreen extends StatefulWidget {
  final String? staffDisplay; // Ej: "Juan Pérez - CC 123456"
  const SelectedActivitiesScreen({Key? key, this.staffDisplay}) : super(key: key);

  @override
  State<SelectedActivitiesScreen> createState() => _SelectedActivitiesScreenState();
}

class _SelectedActivitiesScreenState extends State<SelectedActivitiesScreen> {
  String _companyName = 'TEC-BPM';
  String _userName = 'Usuario';
  String _displayName = '1';

  String? _selectedLevelId;
  List<DropdownMenuItem<String>> _levels = [];

  List<ActivityNode> _treeNodes = [];
  final Set<String> _selectedNodeIds = {}; // solo leaves

  List<SelectedActivity> _savedActivities = [];

  bool _isLoadingTree = false;
  bool _isSending = false;
  bool _isLoadingSaved = false;

  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _init();
    _searchCtrl.addListener(() {
      setState(() => _search = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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

  Future<void> _init() async {
    await ApiClient().loadAuthResult();
    await _loadAuthData();
    await _loadLevels();
    await _loadSavedActivities();
  }

  // ================== API ==================

  Future<void> _loadLevels() async {
    try {
      final resp = await ApiClient().get('/api/selected-activities-admins/levels', auth: true);

      if (resp.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resp.body);

        final seenIds = <String>{};
        final newLevels = <DropdownMenuItem<String>>[];

        for (final e in data) {
          final id = e['Id'].toString();
          if (seenIds.add(id)) {
            newLevels.add(
              DropdownMenuItem<String>(
                value: id,
                child: Text(e['Name'] as String),
              ),
            );
          }
        }

        setState(() {
          _levels = newLevels;
          if (_levels.any((item) => item.value == _selectedLevelId)) {
            // ok
          } else {
            _selectedLevelId = _levels.isNotEmpty ? _levels.first.value : null;
          }
        });

        if (_selectedLevelId != null) {
          _loadTreeByLevel(_selectedLevelId!);
        }
      } else {
        _toastError('Error cargando niveles: ${resp.statusCode}');
      }
    } catch (e) {
      _toastError('Error cargando niveles: $e');
    }
  }

  Future<void> _loadTreeByLevel(String levelId) async {
    setState(() {
      _isLoadingTree = true;
      _treeNodes = [];
      _selectedNodeIds.clear();
      _searchCtrl.text = '';
    });

    try {
      final resp = await ApiClient().get(
        '/api/selected-activities-admins/tree',
        query: {'levelId': levelId},
        auth: true,
      );

      if (resp.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resp.body);
        final nodes = data
            .map((e) => ActivityNode.fromJson(e as Map<String, dynamic>))
            .toList();

        setState(() => _treeNodes = nodes);
      } else {
        _toastError('Error cargando árbol: ${resp.statusCode}');
      }
    } catch (e) {
      _toastError('Error cargando árbol: $e');
    } finally {
      if (mounted) setState(() => _isLoadingTree = false);
    }
  }

  Future<void> _loadSavedActivities() async {
    setState(() => _isLoadingSaved = true);

    try {
      final resp = await ApiClient().get('/api/selected-activities-admins', auth: true);

      if (resp.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resp.body);
        setState(() {
          _savedActivities = data
              .map((e) => SelectedActivity.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      } else {
        _toastError('Error cargando guardadas: ${resp.statusCode}');
      }
    } catch (e) {
      _toastError('Error cargando guardadas: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSaved = false);
    }
  }

  Future<void> _sendSelectedActivities() async {
    if (_selectedNodeIds.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final selectedLeaves = _getLeafNodes()
          .where((n) => _selectedNodeIds.contains(n.id))
          .toList();

      final activityIds = selectedLeaves.map((n) => n.id).toList();

      final resp = await ApiClient().post(
        '/api/selected-activities-admins',
        body: {'activityIds': activityIds},
        auth: true,
      );

      if (resp.statusCode == 200) {
        await _loadSavedActivities();
        if (!mounted) return;

        BpmToast.show(
          context,
          type: BpmToastType.success,
          title: 'Guardado OK',
          message: 'Actividades agregadas correctamente',
        );

        setState(() => _selectedNodeIds.clear());
      } else {
        _toastError('Error al guardar: ${resp.statusCode} - ${resp.body}');
      }
    } catch (e) {
      _toastError('Error enviando actividades: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _deleteSavedActivity(SelectedActivity activity) async {
    try {
      final resp = await ApiClient().delete(
        '/api/selected-activities-admins/${activity.id}',
        auth: true,
      );

      if (resp.statusCode == 200 || resp.statusCode == 204) {
        setState(() {
          _savedActivities.removeWhere((a) => a.id == activity.id);
        });

        BpmToast.show(
          context,
          type: BpmToastType.success,
          title: 'Eliminado',
          message: 'Actividad eliminada correctamente',
        );
      } else {
        _toastError('Error eliminando: ${resp.statusCode}');
      }
    } catch (e) {
      _toastError('Error eliminando: $e');
    }
  }

  void _toastError(String msg) {
    if (!mounted) return;
    BpmToast.show(
      context,
      type: BpmToastType.error,
      title: 'Error',
      message: msg,
    );
  }

  // ================== Tree logic ==================

  List<ActivityNode> _getLeafNodes() {
    final leaves = <ActivityNode>[];

    void traverse(ActivityNode node) {
      if (node.isLeaf) {
        leaves.add(node);
      } else {
        for (final c in node.children) {
          traverse(c);
        }
      }
    }

    for (final n in _treeNodes) {
      traverse(n);
    }
    return leaves;
  }

  void _toggleNodeSelection(ActivityNode node, bool? selected) {
    final isSelected = selected ?? false;
    setState(() {
      if (isSelected) {
        if (node.isLeaf) _selectedNodeIds.add(node.id);
      } else {
        _selectedNodeIds.remove(node.id);
      }
    });
  }

  // Filtra el árbol por texto (sin romper estructura: si un hijo hace match, se conserva el padre)
  List<ActivityNode> _filteredTree(List<ActivityNode> nodes) {
    if (_search.isEmpty) return nodes;

    bool match(ActivityNode n) {
      final t = '${n.code} ${n.name}'.toLowerCase();
      return t.contains(_search);
    }

    ActivityNode? filterNode(ActivityNode n) {
      final filteredChildren = n.children
          .map(filterNode)
          .whereType<ActivityNode>()
          .toList();

      if (match(n) || filteredChildren.isNotEmpty) {
        return ActivityNode(
          id: n.id,
          code: n.code,
          name: n.name,
          level: n.level,
          children: filteredChildren,
        );
      }
      return null;
    }

    return nodes.map(filterNode).whereType<ActivityNode>().toList();
  }

  // ================== UI blocks ==================

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selection Activities - Administrative',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Selecciona las actividades que aplican para este colaborador.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _pill(
                icon: Icons.check_circle_outline,
                label: 'Seleccionadas',
                value: _savedActivities.length.toString(),
              ),
              const SizedBox(width: 8),
              _pill(
                icon: Icons.playlist_add_check,
                label: 'Por agregar',
                value: _selectedNodeIds.length.toString(),
                accent: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill({
    required IconData icon,
    required String label,
    required String value,
    Color? accent,
  }) {
    final c = accent ?? Colors.green;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: c.withOpacity(0.08),
          border: Border.all(color: c.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: c),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w900, color: c),
            ),
          ],
        ),
      ),
    );
  }

  Widget _staffBanner() {
    final s = widget.staffDisplay;
    if (s == null || s.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF2A3042),
      ),
      child: Row(
        children: [
          const Icon(Icons.badge_outlined, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              s,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _levelSelector() {
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
          Text('Nivel de Actividad', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _levels.any((x) => x.value == _selectedLevelId) ? _selectedLevelId : null,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.account_tree_outlined),
            ),
            items: _levels
                .map((item) => DropdownMenuItem<String>(
                      value: item.value,
                      child: Text(
                        (item.child as Text).data ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedLevelId = value);
              _loadTreeByLevel(value);
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Buscar actividad (código o nombre)…',
              isDense: true,
              border: const OutlineInputBorder(),
              suffixIcon: _search.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => _searchCtrl.clear(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _treeCard() {
    final filtered = _filteredTree(_treeNodes);

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
              Text('Árbol de actividades', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
              const Spacer(),
              TextButton.icon(
                onPressed: _selectedNodeIds.isEmpty ? null : () => setState(() => _selectedNodeIds.clear()),
                icon: const Icon(Icons.layers_clear),
                label: const Text('Limpiar'),
              )
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 320,
            child: _isLoadingTree
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay coincidencias.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    : ListView(
                        padding: EdgeInsets.zero,
                        children: filtered.map(_treeNodeWidget).toList(),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _treeNodeWidget(ActivityNode node) {
    if (node.children.isEmpty) {
      final checked = _selectedNodeIds.contains(node.id);

      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: checked ? Colors.blue.withOpacity(0.06) : Colors.transparent,
          border: Border.all(color: checked ? Colors.blue.withOpacity(0.25) : Colors.black.withOpacity(0.05)),
        ),
        child: CheckboxListTile(
          value: checked,
          onChanged: (val) => _toggleNodeSelection(node, val),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          title: Text(
            node.name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            node.code,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 6),
        childrenPadding: const EdgeInsets.only(left: 10, right: 6, bottom: 6),
        title: Text(
          node.name,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          node.code,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        children: node.children.map(_treeNodeWidget).toList(),
      ),
    );
  }

  Widget _savedHeader() {
    return Row(
      children: [
        Text(
          'Actividades seleccionadas',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.green.withOpacity(0.10),
          ),
          child: Text(
            '${_savedActivities.length}',
            style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.green),
          ),
        ),
      ],
    );
  }

  Widget _savedList() {
    if (_isLoadingSaved) {
      return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()));
    }
    if (_savedActivities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 10),
        child: Text(
          'Aún no hay actividades seleccionadas.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _savedActivities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final a = _savedActivities[index];

        return Dismissible(
          key: ValueKey(a.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.red),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Eliminar actividad'),
                    content: Text('¿Eliminar "${a.code} - ${a.name}"?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                      ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
                    ],
                  ),
                ) ??
                false;
          },
          onDismissed: (_) => _deleteSavedActivity(a),
          child: _savedCard(a),
        );
      },
    );
  }

  Widget _savedCard(SelectedActivity a) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(blurRadius: 10, offset: const Offset(0, 6), color: Colors.black.withOpacity(0.05)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: Colors.blue.withOpacity(0.10),
              border: Border.all(color: Colors.blue.withOpacity(0.18)),
            ),
            child: Text(
              a.code,
              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blue, fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              a.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const Icon(Icons.swipe_left_outlined, color: Colors.black38),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    final count = _selectedNodeIds.length;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black.withOpacity(0.06))),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: count == 0 || _isSending ? null : () => setState(() => _selectedNodeIds.clear()),
                icon: const Icon(Icons.layers_clear),
                label: const Text('Limpiar'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: count == 0 || _isSending ? null : _sendSelectedActivities,
                icon: _isSending
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: Text(count == 0 ? 'Agregar' : 'Agregar ($count)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================== Build ==================

  @override
  Widget build(BuildContext context) {
    return BpmScaffold(
      companyName: _companyName,
      userName: _userName,
      displayName: _displayName,
      drawer: BpmSideMenu(
        userName: _userName,
        companyName: _companyName,
        displayName: _displayName,
      ),
      bottom: _bottomBar(),
      body: Container(
        color: const Color(0xFFF4F5F7),
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadLevels();
            await _loadSavedActivities();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            children: [
              _header(),
              const SizedBox(height: 12),
              _staffBanner(),
              _levelSelector(),
              const SizedBox(height: 12),
              _treeCard(),
              const SizedBox(height: 14),
              _savedHeader(),
              const SizedBox(height: 10),
              _savedList(),
            ],
          ),
        ),
      ),
    );
  }
}
