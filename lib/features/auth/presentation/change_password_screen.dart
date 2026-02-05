import 'package:flutter/material.dart';
import 'package:tectrackerbpm/core/api/api_client.dart';
import 'package:tectrackerbpm/core/widgets/bpm_scaffold.dart';
import 'package:tectrackerbpm/core/widgets/bpm_side_menu.dart';
import 'package:tectrackerbpm/core/widgets/bpm_toast.dart';
import 'package:tectrackerbpm/features/auth/data/change_password_api';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _api = ChangePasswordApi();

  // Header
  String _companyName = 'TEC-BPM';
  String _userName = 'Usuario';

  final _formKey = GlobalKey<FormState>();

  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _saving = false;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void initState() {
    super.initState();
    _loadAuthData();
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAuthData() async {
    final auth = await ApiClient().loadAuthResult();
    if (!mounted) return;
    setState(() {
      _companyName = auth?.company ?? 'TEC-BPM';
      _userName = auth?.userName ?? 'Usuario';
    });
  }

  int _passwordScore(String s) {
    // score 0..4 (simple)
    int score = 0;
    if (s.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(s)) score++;
    if (RegExp(r'[0-9]').hasMatch(s)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(s)) score++;
    return score;
  }

  String _strengthLabel(int score) {
    switch (score) {
      case 0:
      case 1:
        return 'Débil';
      case 2:
        return 'Media';
      case 3:
        return 'Fuerte';
      default:
        return 'Muy fuerte';
    }
  }

  Color _strengthColor(int score) {
    if (score <= 1) return Colors.red;
    if (score == 2) return Colors.orange;
    if (score == 3) return Colors.green;
    return Colors.blue;
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null) return;

    if (!form.validate()) {
      BpmToast.show(
        context,
        type: BpmToastType.warning,
        title: 'Revisa los campos',
        message: 'Hay validaciones pendientes.',
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await _api.changePassword(
        newPassword: _newCtrl.text.trim(),
      );

      if (!mounted) return;
      _currentCtrl.clear();
      _newCtrl.clear();
      _confirmCtrl.clear();

      BpmToast.show(
        context,
        type: BpmToastType.success,
        title: 'Listo',
        message: 'Contraseña actualizada correctamente.',
      );
    } catch (e) {
      if (!mounted) return;
      BpmToast.show(
        context,
        type: BpmToastType.error,
        title: 'No se pudo cambiar',
        message: e.toString(),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = _passwordScore(_newCtrl.text);
    final strengthLabel = _strengthLabel(score);
    final strengthColor = _strengthColor(score);

    return BpmScaffold(
      companyName: _companyName,
      userName: _userName,
      drawer: BpmSideMenu(
        userName: _userName,
        companyName: _companyName,
        displayName: _userName,
      ),
      body: Container(
        color: const Color(0xFFF4F5F7),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
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
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.blue.withOpacity(0.10),
                      border: Border.all(color: Colors.blue.withOpacity(0.20)),
                    ),
                    child: const Icon(Icons.lock_reset_outlined, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Cambiar contraseña',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Actualiza tu contraseña de forma segura.',
                          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Form card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white,
                border: Border.all(color: Colors.black.withOpacity(0.06)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // TextFormField(
                    //   controller: _currentCtrl,
                    //   obscureText: !_showCurrent,
                    //   enabled: !_saving,
                    //   decoration: InputDecoration(
                    //     labelText: 'Contraseña actual',
                    //     prefixIcon: const Icon(Icons.lock_outline),
                    //     border: const OutlineInputBorder(),
                    //     isDense: true,
                    //     suffixIcon: IconButton(
                    //       onPressed: () => setState(() => _showCurrent = !_showCurrent),
                    //       icon: Icon(_showCurrent ? Icons.visibility_off : Icons.visibility),
                    //     ),
                    //   ),
                    //   validator: (v) {
                    //     if (v == null || v.trim().isEmpty) return 'Ingresa tu contraseña actual';
                    //     return null;
                    //   },
                    // ),
                    // const SizedBox(height: 12),

                    TextFormField(
                      controller: _newCtrl,
                      obscureText: !_showNew,
                      enabled: !_saving,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Nueva contraseña',
                        prefixIcon: const Icon(Icons.key_outlined),
                        border: const OutlineInputBorder(),
                        isDense: true,
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _showNew = !_showNew),
                          icon: Icon(_showNew ? Icons.visibility_off : Icons.visibility),
                        ),
                      ),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return 'Ingresa la nueva contraseña';
                        if (s.length < 8) return 'Mínimo 8 caracteres';
                        return null;
                      },
                    ),

                    const SizedBox(height: 10),

                    // Strength indicator
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: (score / 4).clamp(0, 1),
                              minHeight: 10,
                              backgroundColor: Colors.black.withOpacity(0.06),
                              valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          strengthLabel,
                          style: TextStyle(
                            color: strengthColor,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: !_showConfirm,
                      enabled: !_saving,
                      decoration: InputDecoration(
                        labelText: 'Confirmar nueva contraseña',
                        prefixIcon: const Icon(Icons.verified_outlined),
                        border: const OutlineInputBorder(),
                        isDense: true,
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _showConfirm = !_showConfirm),
                          icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility),
                        ),
                      ),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return 'Confirma la nueva contraseña';
                        if (s != _newCtrl.text.trim()) return 'No coincide con la nueva contraseña';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _submit,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Actualizar contraseña'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Tips card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.blue.withOpacity(0.06),
                border: Border.all(color: Colors.blue.withOpacity(0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Sugerencias',
                      style: TextStyle(fontWeight: FontWeight.w900)),
                  SizedBox(height: 8),
                  _TipRow(text: 'Usa mínimo 8 caracteres.'),
                  _TipRow(text: 'Combina mayúsculas, números y símbolos.'),
                  _TipRow(text: 'Evita usar tu nombre o cédula.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 18, color: Colors.blue),
          SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}