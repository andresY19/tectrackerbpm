import 'package:flutter/material.dart';
import 'package:tectrackerbpm/core/services/notification_service.dart';

class BpmAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? companyName;
  final String? userName;
  final String? displayName;

  final VoidCallback? onMenuPressed;
  final VoidCallback? onProfilePressed;
  final VoidCallback? onChangePasswordPressed;
  final VoidCallback? onLogoutPressed;
  final VoidCallback? onNotificationsPressed;

  const BpmAppBar({
    Key? key,
    this.companyName,
    this.userName,
    this.displayName,
    this.onMenuPressed,
    this.onProfilePressed,
    this.onChangePasswordPressed,
    this.onLogoutPressed,
    this.onNotificationsPressed, required int notificationCount,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: kToolbarHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              /// ☰ MENÚ
              IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Menú',
                onPressed: onMenuPressed,
              ),

              const SizedBox(width: 6),

              /// LOGO
              Image.asset(
                'assets/images/LogoTecBPM.png',
                height: 30,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.business,
                  color: Colors.blue,
                  size: 30,
                ),
              ),

              const SizedBox(width: 8),

              /// NOMBRE COMPAÑÍA
              Expanded(
                child: Text(
                  companyName ?? 'BPM',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),

              /// 🔔 NOTIFICACIONES (badge reactivo)
              ValueListenableBuilder<int>(
                valueListenable: NotificationService.instance.counter,
                builder: (context, count, _) {
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none),
                        tooltip: 'Notificaciones',
                        onPressed: onNotificationsPressed,
                      ),
                      if (count > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              count > 9 ? '9+' : '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

              /// 👤 USUARIO
              PopupMenuButton<_UserMenuAction>(
                tooltip: userName ?? 'Usuario',
                offset: const Offset(0, 40),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue,
                      child: Text(
                        (displayName?.isNotEmpty ?? false)
                            ? displayName![0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
                onSelected: (action) {
                  switch (action) {
                    case _UserMenuAction.profile:
                      onProfilePressed?.call();
                      break;
                    case _UserMenuAction.changePassword:
                      onChangePasswordPressed?.call();
                      break;
                    case _UserMenuAction.logout:
                      onLogoutPressed?.call();
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _UserMenuAction.profile,
                    child: ListTile(
                      leading: Icon(Icons.person),
                      title: Text('Perfil'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _UserMenuAction.changePassword,
                    child: ListTile(
                      leading: Icon(Icons.lock),
                      title: Text('Cambiar clave'),
                    ),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: _UserMenuAction.logout,
                    child: ListTile(
                      leading: Icon(
                        Icons.power_settings_new,
                        color: Colors.red,
                      ),
                      title: Text(
                        'Cerrar sesión',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
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

enum _UserMenuAction {
  profile,
  changePassword,
  logout,
}
