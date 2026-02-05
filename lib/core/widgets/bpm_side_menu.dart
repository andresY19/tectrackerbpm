import 'package:flutter/material.dart';
import 'package:tectrackerbpm/core/api/api_client.dart';

class BpmSideMenu extends StatelessWidget {
  final String? userName;
  final String? companyName;
  final String? displayName;

  // Opcional: badges (si luego quieres mostrar contadores)
  final int manualBadge;
  final int autoBadge;

  const BpmSideMenu({
    Key? key,
    this.userName,
    this.companyName,
    this.displayName,
    this.manualBadge = 0,
    this.autoBadge = 0,
  }) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    await ApiClient().clearToken();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _navigate(BuildContext context, String routeName) {
    Navigator.pop(context); // cerrar drawer
    if (ModalRoute.of(context)?.settings.name == routeName) return;
    Navigator.pushReplacementNamed(context, routeName);
  }

  bool _isActive(BuildContext context, String routeName) {
    return ModalRoute.of(context)?.settings.name == routeName;
  }

  @override
  Widget build(BuildContext context) {
    final displayUser = (userName ?? 'Usuario').trim();
    final displayCompany = (companyName ?? 'TEC-BPM').trim();
    final dn = (displayName ?? displayUser).trim();
    final initial = dn.isNotEmpty ? dn[0].toUpperCase() : 'U';

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _Header(
              displayUser: displayUser,
              displayCompany: displayCompany,
              initial: initial,
              onProfile: () => _navigate(context, '/profile'),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                children: [
                  _SectionLabel(title: 'NAVEGACIÓN'),
                  const SizedBox(height: 8),

                  _NavTile(
                    active: _isActive(context, '/home') || _isActive(context, '/menu'),
                    icon: Icons.dashboard_outlined,
                    title: 'Inicio',
                    subtitle: 'Resumen y accesos rápidos',
                    onTap: () => _navigate(context, '/home'),
                  ),

                  const SizedBox(height: 14),
                  _SectionLabel(title: 'PRODUCTIVIDAD'),
                  const SizedBox(height: 8),

                  _CollapsibleSection(
                    icon: Icons.assignment_turned_in_outlined,
                    title: 'Productividad manual',
                    subtitle: 'Registro de tiempos manual',
                    initiallyExpanded: _isActive(context, '/manual-menu') ||
                        _isActive(context, '/selected-activities') ||
                        _isActive(context, '/admin-daily') ||
                        _isActive(context, '/admin-unique'),
                    badge: manualBadge,
                    children: [
                      _SubTile(
                        active: _isActive(context, '/manual-menu'),
                        title: 'Menú manual',
                        icon: Icons.grid_view_outlined,
                        onTap: () => _navigate(context, '/manual-menu'),
                      ),
                      _SubTile(
                        active: _isActive(context, '/selected-activities'),
                        title: 'Actividades',
                        icon: Icons.checklist_outlined,
                        onTap: () => _navigate(context, '/selected-activities'),
                      ),
                      _SubTile(
                        active: _isActive(context, '/admin-daily'),
                        title: 'Admin Daily',
                        icon: Icons.calendar_month_outlined,
                        onTap: () => _navigate(context, '/admin-daily'),
                      ),
                      _SubTile(
                        active: _isActive(context, '/admin-unique'),
                        title: 'Admin Unique',
                        icon: Icons.tune_outlined,
                        onTap: () => _navigate(context, '/admin-unique'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  _CollapsibleSection(
                    icon: Icons.location_on_outlined,
                    title: 'Productividad automática',
                    subtitle: 'Fuentes automáticas de datos',
                    initiallyExpanded:
                        _isActive(context, '/auto-menu') || _isActive(context, '/send-location'),
                    badge: autoBadge,
                    children: [
                      _SubTile(
                        active: _isActive(context, '/auto-menu'),
                        title: 'Menú automático',
                        icon: Icons.grid_view_outlined,
                        onTap: () => _navigate(context, '/auto-menu'),
                      ),
                      _SubTile(
                        active: _isActive(context, '/send-location'),
                        title: 'Enviar ubicación',
                        icon: Icons.my_location_outlined,
                        onTap: () => _navigate(context, '/send-location'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  _SectionLabel(title: 'CUENTA'),
                  const SizedBox(height: 8),

                  _NavTile(
                    active: _isActive(context, '/profile'),
                    icon: Icons.person_outline,
                    title: 'Perfil',
                    subtitle: 'Datos del usuario',
                    onTap: () => _navigate(context, '/profile'),
                  ),
                  _NavTile(
                    active: _isActive(context, '/change-password'),
                    icon: Icons.lock_outline,
                    title: 'Cambiar contraseña',
                    subtitle: 'Actualiza tus credenciales',
                    onTap: () => _navigate(context, '/change-password'),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: _LogoutButton(
                onTap: () => _logout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== Header =====================

class _Header extends StatelessWidget {
  const _Header({
    required this.displayUser,
    required this.displayCompany,
    required this.initial,
    required this.onProfile,
  });

  final String displayUser;
  final String displayCompany;
  final String initial;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.20),
            Colors.blue.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withOpacity(0.12),
              border: Border.all(color: Colors.blue.withOpacity(0.20)),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayUser,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  displayCompany,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _MiniChip(icon: Icons.verified_user_outlined, text: 'Activo'),
                    _MiniChip(icon: Icons.security_outlined, text: 'JWT'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Ver perfil',
            onPressed: onProfile,
            icon: const Icon(Icons.arrow_forward_ios, size: 18),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withOpacity(0.75),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black54),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

// ===================== Tiles =====================

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        letterSpacing: 0.8,
        color: Colors.black54,
        fontWeight: FontWeight.w900,
        fontSize: 12,
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.active,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool active;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: active ? Colors.blue.withOpacity(0.10) : Colors.white,
          border: Border.all(
            color: active ? Colors.blue.withOpacity(0.30) : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: active ? Colors.blue : Colors.black54),
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
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: active ? Colors.blue : Colors.black38,
            ),
          ],
        ),
      ),
    );
  }
}

class _CollapsibleSection extends StatelessWidget {
  const _CollapsibleSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
    this.initiallyExpanded = false,
    this.badge = 0,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool initiallyExpanded;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        leading: Icon(icon, color: Colors.black54),
        title: Row(
          children: [
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
            if (badge > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.red.withOpacity(0.10),
                  border: Border.all(color: Colors.red.withOpacity(0.25)),
                ),
                child: Text(
                  badge.toString(),
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
          ],
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
        children: children,
      ),
    );
  }
}

class _SubTile extends StatelessWidget {
  const _SubTile({
    required this.active,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final bool active;
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: active ? Colors.blue.withOpacity(0.08) : Colors.black.withOpacity(0.02),
          border: Border.all(
            color: active ? Colors.blue.withOpacity(0.20) : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: active ? Colors.blue : Colors.black54),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w800, color: active ? Colors.blue : Colors.black87),
              ),
            ),
            Icon(Icons.chevron_right, color: active ? Colors.blue : Colors.black38),
          ],
        ),
      ),
    );
  }
}

// ===================== Logout button =====================

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.red.withOpacity(0.08),
          border: Border.all(color: Colors.red.withOpacity(0.25)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.exit_to_app, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
