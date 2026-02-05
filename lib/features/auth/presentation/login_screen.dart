// lib/features/auth/presentation/login_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tectrackerbpm/features/auth/data/auth_api.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authApi = AuthApi();

  bool _loading = false;
  String? _loginMsg; // equivalente a loginmsg de la vista MVC

  late final int _bgIndex;

  @override
  void initState() {
    super.initState();
    // Simula el random de loginImageN.jpg que haces con jQuery
    _bgIndex = Random().nextInt(10); // 0..9
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _registerPushTokenAfterLogin() async {
    final messaging = FirebaseMessaging.instance;

    // Pedir permisos (Android 13+ / iOS)
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final fcmToken = await messaging.getToken();
    if (fcmToken == null || fcmToken.isEmpty) {
      debugPrint('⚠️ No se pudo obtener FCM token');
      return;
    }

    debugPrint('✅ FCM TOKEN para este usuario: $fcmToken');

    // Llamas a tu API para asociar el token al usuario logueado
    try {
      await _authApi.registerDeviceToken(fcmToken);
    } catch (e) {
      debugPrint('Error registrando device token: $e');
    }
  }

  Future<void> _doLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _loginMsg = null;
    });

    try {
      // En producción usarías:
      final user = _userController.text.trim();
      final pass = _passController.text.trim();
      // final user = "1035420500";
      // final pass = "1035420500AV";

      await _authApi.login(user, pass);

      // ✅ Si llegó aquí, el login fue exitoso y tu ApiClient ya tiene el token/JWT
      await _registerPushTokenAfterLogin(); // ⬅️ NUEVO

      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed('/menu');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loginMsg = 'Error al iniciar sesión: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar sesión: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive: en pantallas anchas -> 2 columnas, en móviles -> una sola columna
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          if (isWide) {
            // Diseño tipo desktop: imagen grande izquierda, panel derecho estrecho
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildLeftPanel(),
                ),
                SizedBox(
                  width: 380,
                  child: _buildRightPanel(),
                ),
              ],
            );
          } else {
            // Móvil: primero imagen arriba, luego el formulario
            return SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: 260,
                    child: _buildLeftPanel(),
                  ),
                  _buildRightPanel(padding: const EdgeInsets.all(24)),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildLeftPanel() {
    final bgPath = 'assets/images/login/loginImage$_bgIndex.jpg';

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(bgPath),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        // overlay tipo .bg-overlay
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.4),
              Colors.black.withOpacity(0.6),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'TEC-BPM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Gestión de productividad y tiempos administrativos.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
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

  Widget _buildRightPanel({EdgeInsets padding = const EdgeInsets.all(32)}) {
    final year = DateTime.now().year;

    return Container(
      color: Colors.white,
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Align(
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/LogoTecBPM.png',
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 32),
            // Mensaje de TempData["Loginmsg"] equivalente
            if (_loginMsg != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _loginMsg!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (_loginMsg != null) const SizedBox(height: 16),
            // Título
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Welcome',
                    style: TextStyle(
                      color: Color(0xFF556EE6), // similar a text-primary
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Sign in with your TEC-BPM account.',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Formulario
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _userController,
                    decoration: const InputDecoration(
                      labelText: 'Usuario',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Ingresa tu usuario';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Ingresa tu contraseña';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _doLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF556EE6),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Ingresar',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Footer
            Text(
              '© $year DEVELOPED BY TECSER S.A.S',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black45,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
