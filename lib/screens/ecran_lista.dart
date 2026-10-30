// lib/screens/ecran_lista.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/manastire.dart';
import '../services/date_service.dart';
import '../services/locatie_service.dart';
import '../services/jurnal_service.dart';
import '../widgets/card_manastire.dart';
import 'ecran_detalii.dart';
import 'ecran_harta.dart';

enum FiltruVizitat { toate, nevizitate, vizitate }
enum ModLocatie { gps, personalizata }

class EcranLista extends StatefulWidget {
  const EcranLista({super.key});

  @override
  State<EcranLista> createState() => _EcranListaState();
}

class _EcranListaState extends State<EcranLista> {
  List<Manastire> _toate = [];
  List<Manastire> _afisate = [];
  Set<int> _vizitate = {};
  Position? _pozitieGps;
  bool _incarcare = true;
  String? _eroare;

  final _searchController = TextEditingController();
  String _cautare = '';
  FiltruVizitat _filtruVizitat = FiltruVizitat.toate;
  int _limita = 20;
  int _totalFiltrat = 0;

  ModLocatie _modLocatie = ModLocatie.gps;
  double? _latCustom;
  double? _lonCustom;
  String _numeCustom = '';

  // Lista de locații salvate
  List<Map<String, dynamic>> _locatiiSalvate = [];

  // Chei SharedPreferences
  static const _kMod = 'loc_mod';
  static const _kActiv = 'loc_activ_index';
  static const _kLista = 'loc_lista';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _cautare = _searchController.text.trim().toLowerCase());
      _aplicaFiltre();
    });
    _initializeaza();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeaza() async {
    setState(() { _incarcare = true; _eroare = null; });
    try {
      final manastiri = await DateService.incarcaManastiri();
      final vizitate = await JurnalService.getIdVizitate();
      final pozitie = await LocatieService.getPozitie();
      await _incarcaLocatiePeristata();
      _toate = manastiri;
      _vizitate = vizitate;
      _pozitieGps = pozitie;
      _aplicaFiltre();
    } catch (e) {
      setState(() => _eroare = e.toString());
    } finally {
      setState(() => _incarcare = false);
    }
  }

  Future<void> _incarcaLocatiePeristata() async {
    final prefs = await SharedPreferences.getInstance();
    final mod = prefs.getString(_kMod);
    final listaJson = prefs.getStringList(_kLista) ?? [];
    final activIndex = prefs.getInt(_kActiv) ?? 0;

    final lista = listaJson.map((s) {
      final parts = s.split('|');
      if (parts.length < 3) return null;
      return {
        'lat': double.tryParse(parts[0]),
        'lon': double.tryParse(parts[1]),
        'nume': parts.sublist(2).join('|'),
      };
    }).whereType<Map<String, dynamic>>().toList();

    setState(() => _locatiiSalvate = lista);

    if (mod == 'personalizata' && lista.isNotEmpty) {
      final idx = activIndex.clamp(0, lista.length - 1);
      final loc = lista[idx];
      setState(() {
        _modLocatie = ModLocatie.personalizata;
        _latCustom = loc['lat'];
        _lonCustom = loc['lon'];
        _numeCustom = loc['nume'];
      });
    }
  }

  Future<void> _salveazaLista() async {
    final prefs = await SharedPreferences.getInstance();
    final listaJson = _locatiiSalvate
        .map((l) => '${l['lat']}|${l['lon']}|${l['nume']}')
        .toList();
    await prefs.setStringList(_kLista, listaJson);
  }

  Future<void> _activeazaLocatie(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final loc = _locatiiSalvate[index];
    await prefs.setInt(_kActiv, index);
    await prefs.setString(_kMod, 'personalizata');
    setState(() {
      _latCustom = loc['lat'];
      _lonCustom = loc['lon'];
      _numeCustom = loc['nume'];
      _modLocatie = ModLocatie.personalizata;
    });
    _aplicaFiltre();
  }

  Future<void> _salveazaLocatiePersonalizata() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMod, 'personalizata');
    await _salveazaLista();
  }

  Future<void> _comutaModGps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMod, 'gps');
  }

  Future<void> _stergeLocatie(int index) async {
    setState(() => _locatiiSalvate.removeAt(index));
    await _salveazaLista();
    if (_locatiiSalvate.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kMod, 'gps');
      setState(() {
        _modLocatie = ModLocatie.gps;
        _latCustom = null;
        _lonCustom = null;
        _numeCustom = '';
      });
      _aplicaFiltre();
    } else {
      await _activeazaLocatie(0);
    }
  }

  Future<void> _stergeLocatiePersonalizata() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLista);
    await prefs.remove(_kActiv);
    await prefs.setString(_kMod, 'gps');
    setState(() => _locatiiSalvate = []);
  }

  double? get _latActiva => _modLocatie == ModLocatie.gps
      ? _pozitieGps?.latitude
      : _latCustom;

  double? get _lonActiva => _modLocatie == ModLocatie.gps
      ? _pozitieGps?.longitude
      : _lonCustom;

  void _aplicaFiltre() {
    var lista = List<Manastire>.from(_toate);

    if (_cautare.isNotEmpty) {
      lista = lista.where((m) =>
          m.nume.toLowerCase().contains(_cautare) ||
          m.judet.toLowerCase().contains(_cautare) ||
          m.hram.toLowerCase().contains(_cautare)).toList();
    }

    if (_filtruVizitat == FiltruVizitat.nevizitate) {
      lista = lista.where((m) => !_vizitate.contains(m.id)).toList();
    } else if (_filtruVizitat == FiltruVizitat.vizitate) {
      lista = lista.where((m) => _vizitate.contains(m.id)).toList();
    }

    if (_latActiva != null && _lonActiva != null) {
      lista = DateService.sorteazaDupaDistanta(
        lista: lista,
        latUser: _latActiva!,
        lonUser: _lonActiva!,
      );
    }

    setState(() {
      _totalFiltrat = lista.length;
      _afisate = lista.take(_limita).toList();
    });
  }

  Future<void> _reincarcaVizitate() async {
    _vizitate = await JurnalService.getIdVizitate();
    _aplicaFiltre();
  }

  /// Parsează un string de forma "46.9759, 26.3815" sau "46.9759 26.3815"
  /// Returnează (lat, lon) sau null dacă e invalid
  (double, double)? _parseazaCoordonate(String input) {
    final s = input.trim().replaceAll(',', ' ');
    final parts = s.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length < 2) return null;
    final lat = double.tryParse(parts[0]);
    final lon = double.tryParse(parts[1]);
    if (lat == null || lon == null) return null;
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return null;
    return (lat, lon);
  }

  void _deschideDialogLocatie() {
    final coordCtrl = TextEditingController();
    final numeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF1A2D3D),
          title: const Text('Locații de planificare',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lista locatii salvate
                if (_locatiiSalvate.isNotEmpty) ...[
                  const Text('Locații salvate',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 6),
                  ...List.generate(_locatiiSalvate.length, (i) {
                    final loc = _locatiiSalvate[i];
                    final esteActiva = _modLocatie == ModLocatie.personalizata &&
                        _latCustom == loc['lat'] && _lonCustom == loc['lon'];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: esteActiva
                            ? const Color(0xFF1E3A5C)
                            : const Color(0xFF0D1B2A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: esteActiva
                              ? const Color(0xFF1E88E5)
                              : Colors.white12,
                          width: esteActiva ? 1 : 0.5,
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        leading: Icon(
                          esteActiva ? Icons.location_on : Icons.location_on_outlined,
                          color: esteActiva
                              ? const Color(0xFFFFB74D)
                              : Colors.white38,
                          size: 18,
                        ),
                        title: Text(
                          loc['nume'] as String,
                          style: TextStyle(
                            color: esteActiva ? Colors.white : Colors.white70,
                            fontSize: 13,
                            fontWeight: esteActiva
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        onTap: () async {
                          await _activeazaLocatie(i);
                          setDlgState(() {});
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.white30, size: 18),
                          onPressed: () async {
                            await _stergeLocatie(i);
                            setDlgState(() {});
                            if (_locatiiSalvate.isEmpty && ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                          },
                        ),
                      ),
                    );
                  }),
                  const Divider(color: Colors.white12),
                ],

                // Adaugă locație nouă
                const Text('Adaugă locație nouă',
                    style: TextStyle(color: Colors.white54, fontSize: 11)),
                const SizedBox(height: 6),
                const Text(
                  'Google Maps: tap lung → copiază coordonatele',
                  style: TextStyle(color: Colors.white30, fontSize: 11),
                ),
                const SizedBox(height: 8),
                _campTextClearable(
                  ctrl: coordCtrl,
                  hint: 'Coordonate (ex: 46.9759, 26.3815)',
                  keyboard: TextInputType.text,
                  onCleared: () => setDlgState(() {}),
                ),
                const SizedBox(height: 8),
                _campTextClearable(
                  ctrl: numeCtrl,
                  hint: 'Nume (ex: Hotel Ceahlău)',
                  keyboard: TextInputType.text,
                  onCleared: () => setDlgState(() {}),
                ),
                const SizedBox(height: 12),
                // Buton Adaugă în content — departe de tastatura
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final parsed = _parseazaCoordonate(coordCtrl.text);
                        if (parsed == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Coordonate invalide!'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        final (lat, lon) = parsed;
                        final nume = numeCtrl.text.trim().isEmpty
                            ? '$lat, $lon'
                            : numeCtrl.text.trim();
                        setState(() {
                          _locatiiSalvate.add({'lat': lat, 'lon': lon, 'nume': nume});
                          _latCustom = lat;
                          _lonCustom = lon;
                          _numeCustom = nume;
                          _modLocatie = ModLocatie.personalizata;
                        });
                        await _salveazaLocatiePersonalizata();
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setInt(_kActiv, _locatiiSalvate.length - 1);
                        _aplicaFiltre();
                        coordCtrl.clear();
                        numeCtrl.clear();
                        setDlgState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5)),
                      child: const Text('Adaugă'),
                    ),
                  ],
                ),
              ],
            ),
            ),
          ),
          actions: [
            if (_modLocatie == ModLocatie.personalizata)
              TextButton(
                onPressed: () async {
                  await _comutaModGps();
                  setState(() => _modLocatie = ModLocatie.gps);
                  _aplicaFiltre();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Folosește GPS',
                    style: TextStyle(color: Colors.orange)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Închide',
                  style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campTextClearable({
    required TextEditingController ctrl,
    required String hint,
    required TextInputType keyboard,
    required VoidCallback onCleared,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      onChanged: (_) => onCleared(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
        suffixIcon: ctrl.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.white38, size: 16),
                onPressed: () {
                  ctrl.clear();
                  onCleared();
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xFF0D1B2A),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _campText(
      TextEditingController ctrl, String hint, TextInputType keyboard) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF0D1B2A),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8, right: 4),
          child: FloatingActionButton(
            onPressed: _initializeaza,
            backgroundColor: const Color(0xFF1E88E5),
            tooltip: 'Reîncarcă GPS',
            child: const Icon(Icons.refresh, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    final esteCustom = _modLocatie == ModLocatie.personalizata;
    return AppBar(
      backgroundColor: const Color(0xFF0D1B2A),
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mănăstiri apropiate',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold)),
          Text(
            esteCustom
                ? '📍 $_numeCustom'
                : _pozitieGps != null
                    ? 'GPS activ'
                    : 'Fără GPS — activează locația',
            style: TextStyle(
              color: esteCustom
                  ? const Color(0xFFFFB74D)
                  : _pozitieGps != null
                      ? const Color(0xFF90CAF9)
                      : Colors.orange,
              fontSize: 11,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            esteCustom
                ? Icons.edit_location
                : Icons.add_location_alt_outlined,
            color: esteCustom ? const Color(0xFFFFB74D) : Colors.white,
          ),
          tooltip: esteCustom
              ? 'Modifică locația de planificare'
              : 'Setează locație de planificare',
          onPressed: _deschideDialogLocatie,
        ),
        IconButton(
          icon: Icon(
            Icons.my_location,
            color: !esteCustom && _pozitieGps != null
                ? const Color(0xFF1E88E5)
                : Colors.white,
          ),
          tooltip: 'Folosește GPS (păstrează locația salvată)',
          onPressed: () async {
            await _comutaModGps();
            setState(() => _modLocatie = ModLocatie.gps);
            _aplicaFiltre();
          },
        ),
        IconButton(
          icon: const Icon(Icons.map_outlined, color: Colors.white),
          tooltip: 'Hartă',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EcranHarta(
                manastiri: _toate,
                vizitate: _vizitate,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white),
          tooltip: 'Despre aplicație',
          onPressed: _arataDespre,
        ),
      ],
    );
  }

  void _arataDespre() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2D3D),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B2A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(Icons.church, color: Color(0xFFD4A84B), size: 36),
            ),
            const SizedBox(height: 14),
            const Text('Mănăstiri Pelerini',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('659 mănăstiri ortodoxe din România',
                style: TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Autor',
                      style: TextStyle(color: Colors.white38, fontSize: 11)),
                  SizedBox(height: 4),
                  Text('Mereu Mihai',
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                  SizedBox(height: 8),
                  Text('Contact',
                      style: TextStyle(color: Colors.white38, fontSize: 11)),
                  SizedBox(height: 4),
                  Text('mihaimereu97@gmail.com',
                      style: TextStyle(color: Color(0xFF90CAF9), fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Închide',
                style: TextStyle(color: Color(0xFF90CAF9))),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_incarcare) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF1E88E5)),
            SizedBox(height: 16),
            Text('Se obțin datele...',
                style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    if (_eroare != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(_eroare!, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _initializeaza,
                  child: const Text('Încearcă din nou')),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildFiltre(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _initializeaza,
            color: const Color(0xFF1E88E5),
            child: ListView.builder(
              itemCount: _afisate.length + 1,
              itemBuilder: (ctx, i) {
                if (i == _afisate.length) return _buildArataMaiMult();
                final m = _afisate[i];
                return CardManastire(
                  manastire: m,
                  vizitat: _vizitate.contains(m.id),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EcranDetalii(
                          manastire: m,
                          vizitat: _vizitate.contains(m.id),
                          origineLat: _modLocatie == ModLocatie.personalizata
                              ? _latCustom
                              : null,
                          origineLon: _modLocatie == ModLocatie.personalizata
                              ? _lonCustom
                              : null,
                          origineNume: _modLocatie == ModLocatie.personalizata
                              ? _numeCustom
                              : null,
                        ),
                      ),
                    );
                    _reincarcaVizitate();
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltre() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        children: [
          // Bara de căutare
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Caută după nume, județ sau hram...',
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
              suffixIcon: _cautare.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _cautare = '');
                        _aplicaFiltre();
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF1A2D3D),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Chipuri vizitat
          Row(
            children: [
              _chip('Toate', _filtruVizitat == FiltruVizitat.toate,
                  () => setState(() {
                        _filtruVizitat = FiltruVizitat.toate;
                        _aplicaFiltre();
                      })),
              const SizedBox(width: 6),
              _chip('Nevizitate', _filtruVizitat == FiltruVizitat.nevizitate,
                  () => setState(() {
                        _filtruVizitat = FiltruVizitat.nevizitate;
                        _aplicaFiltre();
                      })),
              const SizedBox(width: 6),
              _chip('Vizitate ✓', _filtruVizitat == FiltruVizitat.vizitate,
                  () => setState(() {
                        _filtruVizitat = FiltruVizitat.vizitate;
                        _aplicaFiltre();
                      })),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool activ, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: activ ? const Color(0xFF1E88E5) : const Color(0xFF1A2D3D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: activ ? const Color(0xFF1E88E5) : Colors.white24,
            width: 0.5,
          ),
        ),
        child: Text(label,
            style: TextStyle(
                color: activ ? Colors.white : Colors.white60,
                fontSize: 12)),
      ),
    );
  }

  Widget _buildArataMaiMult() {
    if (_afisate.length >= _totalFiltrat) return const SizedBox(height: 80);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextButton(
        onPressed: () =>
            setState(() { _limita += 20; _aplicaFiltre(); }),
        child: Text('Arată mai mult (${_afisate.length}/$_totalFiltrat)',
            style: const TextStyle(color: Color(0xFF90CAF9))),
      ),
    );
  }
}
