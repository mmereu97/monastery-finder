// lib/screens/ecran_harta.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/manastire.dart';
import 'ecran_detalii.dart';

class EcranHarta extends StatefulWidget {
  final List<Manastire> manastiri;
  final Set<int> vizitate;

  const EcranHarta({
    super.key,
    required this.manastiri,
    required this.vizitate,
  });

  @override
  State<EcranHarta> createState() => _EcranHartaState();
}

class _EcranHartaState extends State<EcranHarta> {
  final _minController = TextEditingController();
  int _min = 0;

  // Doar mănăstirile plasabile pe hartă, peste pragul de viețuitori.
  // Cu prag 0 se afișează toate cele cu GPS; cu prag > 0 dispar cele
  // fără număr cunoscut de viețuitori (null).
  List<Manastire> get _vizibile {
    return widget.manastiri.where((m) {
      if (!m.areGps) return false;
      if (_min == 0) return true;
      return m.vietuitori != null && m.vietuitori! >= _min;
    }).toList();
  }

  @override
  void dispose() {
    _minController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vizibile = _vizibile;
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        title: const Text('Hartă mănăstiri',
            style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _baraFiltru(vizibile.length),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: const LatLng(45.94, 24.97), // centrul aprox. al României
                initialZoom: 6.4,
                minZoom: 5,
                maxZoom: 18,
                // Pan + zoom, dar fără rotație — nordul rămâne mereu sus.
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  // OSM cere un User-Agent valid — pune applicationId-ul tău real.
                  userAgentPackageName: 'com.mereu.manastiri_pelerini',
                ),
                MarkerLayer(markers: vizibile.map(_marker).toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Marker _marker(Manastire m) {
    final esteMaici = m.tip == 'maici';
    return Marker(
      point: LatLng(m.lat!, m.lon!),
      width: 30,
      height: 30,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EcranDetalii(
              manastire: m,
              vizitat: widget.vizitate.contains(m.id),
            ),
          ),
        ),
        child: Center(
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: esteMaici
                  ? const Color(0xFFEF9F27)
                  : const Color(0xFF1E88E5),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _baraFiltru(int nrAfisate) {
    return Container(
      color: const Color(0xFF1A2D3D),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          const Text('Minim viețuitori:',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: TextField(
              controller: _minController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: const TextStyle(color: Colors.white30),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFF0D1B2A),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF1E88E5)),
                ),
              ),
              onChanged: (v) =>
                  setState(() => _min = int.tryParse(v.trim()) ?? 0),
            ),
          ),
          const Spacer(),
          Text('$nrAfisate afișate',
              style: const TextStyle(color: Color(0xFF90CAF9), fontSize: 13)),
        ],
      ),
    );
  }
}
