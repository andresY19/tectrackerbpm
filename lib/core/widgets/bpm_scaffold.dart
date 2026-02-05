import 'package:flutter/material.dart';
import 'package:tectrackerbpm/core/services/notification_service.dart';
import 'package:tectrackerbpm/core/widgets/bpm_app_bar.dart';
import 'package:tectrackerbpm/core/api/api_client.dart';

class BpmScaffold extends StatefulWidget {
  final String? companyName;
  final String? userName;
  final String? displayName;

  final Widget body;
  final Widget? bottom;
  final Widget? drawer;

  // Acciones del AppBar que *puedes* sobreescribir si quieres
  final VoidCallback? onProfilePressed;
  final VoidCallback? onChangePasswordPressed;
  final VoidCallback? onLogoutPressed;

  const BpmScaffold({
    Key? key,
    this.companyName,
    this.userName,
    this.displayName,
    required this.body,
    this.bottom,
    this.drawer,
    this.onProfilePressed,
    this.onChangePasswordPressed,
    this.onLogoutPressed,
  }) : super(key: key);

  @override
  State<BpmScaffold> createState() => _BpmScaffoldState();
}

class _BpmScaffoldState extends State<BpmScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _defaultLogout() async {
    await ApiClient().clearToken();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _openNotifications() {
    Navigator.of(context).pushNamed('/notifications');
  }

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;

    return Scaffold(
      key: _scaffoldKey,

      // Drawer que se va a abrir con el botón de menú del AppBar
      drawer: widget.drawer,

      // ✅ AppBar envuelto en PreferredSize (para que cumpla el tipo PreferredSizeWidget)
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ValueListenableBuilder<int>(
          valueListenable: NotificationService.instance.counter,
          builder: (context, count, _) {
            return BpmAppBar(
              companyName: widget.companyName,
              userName: widget.userName,
              displayName: widget.displayName,

              // Notificaciones
              notificationCount: count,
              onNotificationsPressed: _openNotifications,

              // Botón menú – abre el drawer
              onMenuPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },

              // Acciones centralizadas (si no se pasan callbacks, usamos estos defaults)
              onProfilePressed: widget.onProfilePressed ??
                  () {
                    Navigator.pushNamed(context, '/profile');
                  },
              onChangePasswordPressed: widget.onChangePasswordPressed ??
                  () {
                    Navigator.pushNamed(context, '/change-password');
                  },
              onLogoutPressed: widget.onLogoutPressed ?? _defaultLogout,
            );
          },
        ),
      ),

      body: Column(
        children: [
          // Contenido principal de la pantalla que usa BpmScaffold
          Expanded(
            child: widget.body,
          ),

          if (widget.bottom != null) widget.bottom!,

          // 🔹 Footer protegido por SafeArea para no quedar debajo de los botones del SO
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: const Border(
                  top: BorderSide(color: Colors.grey, width: 0.5),
                ),
              ),
              child: Text(
                '$year © Design & Develop by TECSER S.A.S',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
