import 'package:flutter/material.dart';
import 'package:tectrackerbpm/core/api/api_client.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tectrackerbpm/core/widgets/bpm_toast.dart';
import 'package:tectrackerbpm/features/auth/presentation/change_password_screen.dart';

// Auth
import 'package:tectrackerbpm/features/auth/presentation/login_screen.dart';

// Home / menús
import 'package:tectrackerbpm/features/home/presentation/home_screen.dart';
import 'package:tectrackerbpm/features/home/presentation/manual_menu_screen.dart';
import 'package:tectrackerbpm/features/home/presentation/auto_menu_screen.dart';
import 'package:tectrackerbpm/features/home/presentation/profile_screen.dart';

// Productividad manual
import 'package:tectrackerbpm/features/manual_productivity/presentation/selected_activities_screen.dart';
import 'package:tectrackerbpm/features/manual_productivity/presentation/admin_daily_screen.dart';
import 'package:tectrackerbpm/features/manual_productivity/presentation/admin_unique_screen.dart';

// Productividad automática
import 'package:tectrackerbpm/features/auto_productivity/presentation/send_location_screen.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// 👇 NUEVO
import 'package:tectrackerbpm/core/services/notification_service.dart';
import 'package:tectrackerbpm/features/notifications/presentation/notifications_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Aquí podrías loguear o procesar data si lo necesitas
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await initializeDateFormatting('es_CO', null);

  await ApiClient().loadAuthResult();

  runApp(const BpmApp());
}

class BpmApp extends StatefulWidget {
  const BpmApp({Key? key}) : super(key: key);

  @override
  State<BpmApp> createState() => _BpmAppState();
}

class _BpmAppState extends State<BpmApp> {
  @override
  void initState() {
    super.initState();
    _initPushNotifications();
    _listenPushEvents();
  }

  Future<void> _initPushNotifications() async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging.getToken();
    print("✅ FCM TOKEN: $token");

    // TODO: enviar token al backend si quieres
  }

  void _listenPushEvents() {
    // Cuando llega en foreground (app abierta)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 Push en foreground: ${message.notification?.title}");
      print("📦 Data: ${message.data}");

      // ✅ Guardar la notificación en el servicio (lista + contador)
      NotificationService.instance.addNotification(
        title: message.notification?.title ?? 'Notificación',
        body: message.notification?.body ?? '',
        data: message.data,
      );

      // ✅ Mostrar feedback rápido con SnackBar (simple, sin Overlay raro)
      final ctx = rootNavigatorKey.currentContext;
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(
              message.notification?.body ??
                  message.notification?.title ??
                  'Nueva notificación',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        debugPrint('⚠️ No context disponible para SnackBar');
      }
    });

    // Cuando el usuario toca la notificación y abre la app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("👉 Abrió desde push: ${message.data}");
      _handlePushNavigation(message.data);
    });
  }

  void _handlePushNavigation(Map<String, dynamic> data) {
    final screen = data['screen']?.toString();
    if (screen == null || screen.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = rootNavigatorKey.currentState;
      if (nav == null) return;

      if (screen == 'admin-daily') {
        // 👇 nuevo método, NO reset()
        NotificationService.instance.resetCounter();
        nav.pushNamed('/admin-daily');
      } else {
        nav.pushNamed('/$screen');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasToken = (ApiClient().token?.isNotEmpty ?? false);

    return MaterialApp(
      title: 'BPM Productividad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      navigatorKey: rootNavigatorKey,
      initialRoute: hasToken ? '/home' : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/menu': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/manual-menu': (context) => const ManualMenuScreen(),
        '/auto-menu': (context) => const AutoMenuScreen(),
        '/selected-activities': (context) => const SelectedActivitiesScreen(),
        '/admin-daily': (context) => const AdminDailyScreen(),
        '/admin-unique': (context) => const AdminUniqueScreen(),
        '/send-location': (context) => const SendLocationScreen(),
        '/change-password': (context) => const ChangePasswordScreen(),
        '/notifications': (context) => const NotificationsScreen(),
      },
    );
  }
}
