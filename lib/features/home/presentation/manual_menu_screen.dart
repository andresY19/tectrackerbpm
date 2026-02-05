// features/manual/manual_menu_screen.dart
import 'package:flutter/material.dart';
import 'package:tectrackerbpm/core/api/api_client.dart';
import 'package:tectrackerbpm/core/widgets/bpm_scaffold.dart';
import 'package:tectrackerbpm/core/widgets/bpm_side_menu.dart';

class ManualMenuScreen extends StatefulWidget {
  const ManualMenuScreen({Key? key}) : super(key: key);

  @override
  State<ManualMenuScreen> createState() => _ManualMenuScreenState();
}

class _ManualMenuScreenState extends State<ManualMenuScreen> {
  String _companyName = 'TEC-BPM';
  String _userName = 'Usuario';
  String _displayName = '1';

  @override
  void initState() {
    super.initState();
    _loadAuthData();
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

  void _goSelectedActivities(BuildContext context) {
    Navigator.pushNamed(context, '/selected-activities');
  }

  void _goAdminDaily(BuildContext context) {
    Navigator.pushNamed(context, '/admin-daily');
  }

  void _goAdminUnique(BuildContext context) {
    Navigator.pushNamed(context, '/admin-unique');
  }

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
        child: Column(
          children: [
            // Header tipo HomeScreen
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Productividad manual',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Gestiona las actividades y toma de tiempos manuales.',
                    style: TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            // Contenido en tarjetas, similar al Home
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Column(
                  children: [
                    // Tarjeta: Selección de actividades
                    Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _goSelectedActivities(context),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF50A5F1),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: const Icon(
                                  Icons.list_alt_outlined,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Selección de actividades',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Define y administra las actividades que se usarán '
                                      'en la toma de tiempos.',
                                      style: TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Tarjeta: Toma de tiempos - Daily
                    Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _goAdminDaily(context),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF34C38F),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: const Icon(
                                  Icons.today_outlined,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Toma de tiempos - Daily',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Registra los tiempos diarios de los colaboradores '
                                      'por actividad.',
                                      style: TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Tarjeta: Toma de tiempos - Unique
                    Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _goAdminUnique(context),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFF1B44C),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: const Icon(
                                  Icons.timelapse_outlined,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Toma de tiempos - Unique',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Registra tiempos únicos para actividades o casos '
                                      'puntuales.',
                                      style: TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Tarjeta de contexto / ayuda
                    Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(top: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'En este módulo administras toda la configuración y captura '
                          'de tiempos manuales de tu compañía. Puedes comenzar '
                          'configurando actividades y luego usar Daily o Unique '
                          'según la necesidad operativa.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
