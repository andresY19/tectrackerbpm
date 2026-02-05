import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tectrackerbpm/core/api/api_client.dart';
import 'package:tectrackerbpm/core/widgets/bpm_scaffold.dart';
import 'package:tectrackerbpm/core/widgets/bpm_side_menu.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _companyName = 'Software Musoft';
  String _userName = 'Usuario';
  String _roleName = '';
  String _lastName = '';
  String _identification = '';
  String _email = '';
  String _address = '';
  String _numberContact = '';
  String? _profilePictureUrl;
  String _displayName = '1';

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    setState(() => _loading = true);

    final auth = await ApiClient().loadAuthResult();
    if (!mounted) return;

    setState(() {
      _companyName = auth?.company ?? 'Software Musoft';
      _userName = auth?.userName ?? 'Usuario';
      _displayName = auth?.identification ?? '1';

      // Ojo: tú estás usando userName como identification en tu ejemplo.
      // Si tu AuthResult tiene identification real, cámbialo aquí.
      _identification = auth?.identification ?? '';
      _email = auth?.email ?? '';

      // Estos vendrán de una API futura:
      _roleName = _roleName; // placeholder
      _lastName = _lastName;
      _address = _address;
      _numberContact = _numberContact;
      _profilePictureUrl = _profilePictureUrl;

      _loading = false;
    });
  }

  String get _fullName {
    final a = _userName.trim();
    final b = _lastName.trim();
    final s = ('$a $b').trim();
    return s.isEmpty ? 'Usuario' : s;
  }

  Future<void> _copy(String label, String value) async {
    if (value.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value.trim()));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copiado')),
    );
  }

  void _openEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 6,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              Text(
                'Editar perfil',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Aquí puedes conectar luego tu API para actualizar datos.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Listo'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= UI helpers =================

  Widget _heroHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 7),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _avatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _identification,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // _chip(
                        //   icon: Icons.verified_user_outlined,
                        //   label: _roleName.trim().isEmpty ? 'Rol: (pendiente)' : _roleName,
                        //   color: Colors.blue,
                        // ),
                        _chip(
                          icon: Icons.email_outlined,
                          label: _email.trim().isEmpty ? 'Sin email' : _email,
                          color: Colors.green,
                          onTap: () => _copy('Email', _email),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
            ],
          ),

          const SizedBox(height: 12),

          // Acciones rápidas
          Row(
            children: [
              Expanded(
                child: _actionCard(
                  icon: Icons.badge_outlined,
                  title: 'ID',
                  subtitle: _userName.isEmpty ? '-' : _userName,
                  onTap: () => _copy('ID', _userName),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionCard(
                  icon: Icons.refresh,
                  title: 'Actualizar',
                  subtitle: _loading ? 'Cargando…' : 'Refrescar datos',
                  onTap: _loading ? null : _loadAuthData,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatar() {
    // Si luego manejas URL real: usa Image.network con errorBuilder
    final initials = _fullName.isNotEmpty ? _fullName.substring(0, 1).toUpperCase() : 'U';

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue.withOpacity(0.12),
        border: Border.all(color: Colors.blue.withOpacity(0.20)),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.blue),
        ),
      ),
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w800, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black.withOpacity(0.02),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.blue.withOpacity(0.10),
              ),
              child: Icon(icon, color: Colors.blue),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.05),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.black54),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onCopy,
  }) {
    final showCopy = onCopy != null && value.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withOpacity(0.02),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  value.trim().isEmpty ? '-' : value,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          if (showCopy)
            IconButton(
              tooltip: 'Copiar',
              onPressed: onCopy,
              icon: const Icon(Icons.copy, size: 18),
            ),
        ],
      ),
    );
  }

  // ================= Build =================

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
      body: Container(
        color: const Color(0xFFF4F5F7),
        child: RefreshIndicator(
          onRefresh: _loadAuthData,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              _heroHeader(context),

              _sectionCard(
                title: 'Identidad',
                icon: Icons.person_outline,
                children: [
                  _infoTile(
                    icon: Icons.account_circle_outlined,
                    label: 'Usuario',
                    value: _userName,
                    onCopy: () => _copy('Usuario', _userName),
                  ),
                  
                  _infoTile(
                    icon: Icons.perm_identity,
                    label: 'Nombre',
                    value: _identification,
                  ),
                  // _infoTile(
                  //   icon: Icons.badge_outlined,
                  //   label: 'Rol',
                  //   value: _roleName,
                  // ),
                ],
              ),

              _sectionCard(
                title: 'Contacto',
                icon: Icons.contact_mail_outlined,
                children: [
                  _infoTile(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: _email,
                    onCopy: () => _copy('Email', _email),
                  ),
                  _infoTile(
                    icon: Icons.phone_outlined,
                    label: 'Número de contacto',
                    value: _numberContact,
                    onCopy: () => _copy('Contacto', _numberContact),
                  ),
                ],
              ),

              _sectionCard(
                title: 'Dirección',
                icon: Icons.location_on_outlined,
                children: [
                  _infoTile(
                    icon: Icons.home_outlined,
                    label: 'Dirección',
                    value: _address,
                    onCopy: () => _copy('Dirección', _address),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
