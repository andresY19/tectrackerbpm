import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:tectrackerbpm/features/auto_productivity/data/models/send_location_request.dart';
import '../data/send_location_api.dart';

class SendLocationScreen extends StatefulWidget {
  const SendLocationScreen({Key? key}) : super(key: key);

  @override
  State<SendLocationScreen> createState() => _SendLocationScreenState();
}

class _SendLocationScreenState extends State<SendLocationScreen> {
  final _api = SendLocationApi();
  final MapController _mapController = MapController();

  bool _sending = false;
  bool _loadingLocation = false;
  String? _status;
  Position? _lastPosition;

  Future<bool> _ensurePermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      setState(() => _status = 'Activa los servicios de ubicación (GPS).');
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      setState(() => _status = 'Permiso de ubicación denegado.');
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _status = 'Permiso denegado permanentemente. Habilítalo en Ajustes.');
      return false;
    }

    return true;
  }

  Future<void> _loadCurrentLocation({bool showStatus = true}) async {
    setState(() {
      _loadingLocation = true;
      if (showStatus) _status = null;
    });

    try {
      final ok = await _ensurePermission();
      if (!ok) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );

      setState(() {
        _lastPosition = pos;
        if (showStatus) _status = 'Ubicación lista.';
      });

      final center = LatLng(pos.latitude, pos.longitude);
      _mapController.move(center, 16);
    } catch (e) {
      setState(() => _status = 'No se pudo obtener la ubicación: $e');
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Future<void> _sendLocation() async {
    setState(() {
      _sending = true;
      _status = null;
    });

    try {
      if (_lastPosition == null) {
        await _loadCurrentLocation(showStatus: false);
      }

      final pos = _lastPosition;
      if (pos == null) {
        setState(() => _status = 'No hay ubicación disponible para enviar.');
        return;
      }

      final req = SendLocationRequest(
        latitude: pos.latitude,
        longitude: pos.longitude,
        timestamp: DateTime.now().toUtc(),
      );

      await _api.sendLocation(req);

      if (!mounted) return;
      setState(() => _status = 'Ubicación enviada ✅');
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Error al enviar ubicación: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation(showStatus: false);
  }

  @override
  Widget build(BuildContext context) {
    final pos = _lastPosition;
    final center = pos == null ? const LatLng(4.7110, -74.0721) : LatLng(pos.latitude, pos.longitude);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enviar ubicación'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: (_loadingLocation || _sending) ? null : () => _loadCurrentLocation(),
            icon: const Icon(Icons.my_location),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: pos == null ? 11 : 16,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.tectrackerbpm', // pon tu package real
                    ),
                    if (pos != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(pos.latitude, pos.longitude),
                            width: 48,
                            height: 48,
                            child: const Icon(Icons.location_on, size: 40),
                          ),
                        ],
                      ),
                  ],
                ),

                // Card superior con info
                Positioned(
                  left: 12,
                  right: 12,
                  top: 12,
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(_loadingLocation ? Icons.gps_not_fixed : Icons.gps_fixed),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Ubicación actual', style: TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                if (pos == null)
                                  Text(
                                    _loadingLocation ? 'Obteniendo ubicación...' : 'Aún no disponible',
                                    style: const TextStyle(color: Colors.black54),
                                  )
                                else
                                  Text(
                                    'Lat: ${pos.latitude.toStringAsFixed(6)} • Lon: ${pos.longitude.toStringAsFixed(6)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (pos != null)
                                  Text(
                                    'Precisión: ${pos.accuracy.toStringAsFixed(0)} m',
                                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                                  ),
                                if (_status != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    _status!,
                                    style: TextStyle(
                                      color: _status!.toLowerCase().contains('error') ? Colors.red : Colors.blue,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Botón flotante enviar
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: (_loadingLocation || _sending) ? null : () => _loadCurrentLocation(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Actualizar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: (_loadingLocation || _sending) ? null : _sendLocation,
                            icon: _sending
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.send),
                            label: Text(_sending ? 'Enviando...' : 'Enviar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
