// lib/screens/ecran_detalii.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/manastire.dart';
import '../services/jurnal_service.dart';

class EcranDetalii extends StatefulWidget {
  final Manastire manastire;
  final bool vizitat;
  final double? origineLat;
  final double? origineLon;
  final String? origineNume;

  const EcranDetalii({
    super.key,
    required this.manastire,
    required this.vizitat,
    this.origineLat,
    this.origineLon,
    this.origineNume,
  });

  @override
  State<EcranDetalii> createState() => _EcranDetaliiState();
}

class _EcranDetaliiState extends State<EcranDetalii> {
  InregistrareJurnal? _jurnal;
  bool _incarcare = true;
  final _notiteController = TextEditingController();
  final _hramController = TextEditingController();
  final _vietuitoriController = TextEditingController();
  DateTime _dataSelectata = DateTime.now();
  bool _vizitat = false;
  bool _salvare = false;

  @override
  void initState() {
    super.initState();
    _vizitat = widget.vizitat;
    _incarcaJurnal();
  }

  @override
  void dispose() {
    _notiteController.dispose();
    _hramController.dispose();
    _vietuitoriController.dispose();
    super.dispose();
  }

  Future<void> _incarcaJurnal() async {
    final jurnal = await JurnalService.getJurnal(widget.manastire.id);
    setState(() {
      _jurnal = jurnal;
      if (jurnal != null) {
        _notiteController.text = jurnal.notite;
        _dataSelectata = jurnal.dataVizita;
        _vizitat = jurnal.vizitat;
        _hramController.text = jurnal.hramCustom ?? widget.manastire.hram;
        _vietuitoriController.text = jurnal.vietuitoriCustom != null
            ? '${jurnal.vietuitoriCustom}'
            : widget.manastire.vietuitori != null
                ? '${widget.manastire.vietuitori}'
                : '';
      } else {
        _hramController.text = widget.manastire.hram;
        _vietuitoriController.text = widget.manastire.vietuitori != null
            ? '${widget.manastire.vietuitori}'
            : '';
      }
      _incarcare = false;
    });
  }

  Future<void> _salveaza() async {
    setState(() => _salvare = true);
    await JurnalService.salveaza(InregistrareJurnal(
      id: _jurnal?.id,
      manastireId: widget.manastire.id,
      dataVizita: _dataSelectata,
      notite: _notiteController.text.trim(),
      vizitat: _vizitat,
      hramCustom: _hramController.text.trim().isNotEmpty
          ? _hramController.text.trim()
          : null,
      vietuitoriCustom: int.tryParse(_vietuitoriController.text.trim()),
    ));
    setState(() => _salvare = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Salvat!'),
          backgroundColor: Color(0xFF1E88E5),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deschideGoogleMaps() async {
    final m = widget.manastire;
    if (!m.areGps) return;

    final Uri uri;
    if (widget.origineLat != null && widget.origineLon != null) {
      // Mod hotel — traseu de la origine la mănăstire
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&origin=${widget.origineLat},${widget.origineLon}'
        '&destination=${m.lat},${m.lon}'
        '&travelmode=driving',
      );
    } else {
      // Mod GPS — navigare simplă de la locația curentă
      final geo = Uri.parse(
          'geo:${m.lat},${m.lon}?q=${m.lat},${m.lon}(${Uri.encodeComponent(m.nume)})');
      if (await canLaunchUrl(geo)) {
        await launchUrl(geo);
        return;
      }
      uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${m.lat},${m.lon}');
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _copiazaCoordonate() async {
    final m = widget.manastire;
    if (!m.areGps) return;
    await Clipboard.setData(ClipboardData(text: '${m.lat}, ${m.lon}'));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coordonate copiate în clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _selecteazaData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataSelectata,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF1E88E5),
            surface: Color(0xFF1A2D3D),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dataSelectata = picked);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.manastire;
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        title: Text(m.nume,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            overflow: TextOverflow.ellipsis),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _incarcare
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E88E5)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _cardInfoManastire(),
                const SizedBox(height: 12),
                _cardGps(),
                const SizedBox(height: 12),
                _cardJurnal(),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _salvare ? null : _salveaza,
                  icon: _salvare
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: const Text('Salvează jurnalul'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _cardInfoManastire() {
    final m = widget.manastire;
    final hramAfisat = _hramController.text.trim().isNotEmpty
        ? _hramController.text.trim()
        : m.hram;
    final vietuitoriAfisat = int.tryParse(_vietuitoriController.text.trim())
        ?? m.vietuitori;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(Icons.church, m.judet, bold: true),
          if (hramAfisat.isNotEmpty) _row(Icons.star_outline, hramAfisat),
          if (m.tip.isNotEmpty)
            _row(Icons.people_outline,
                m.tip == 'maici' ? 'Mănăstire de maici' : 'Mănăstire de călugări'),
          if (m.an != null)
            _row(Icons.calendar_today_outlined, 'Întemeiată în ${m.an}'),
          if (vietuitoriAfisat != null)
            _row(Icons.person_outline, '$vietuitoriAfisat viețuitori'),
          if (m.arhiepiscopie.isNotEmpty)
            _row(Icons.account_balance_outlined, m.arhiepiscopie),
          if (m.distantaKm != null)
            _row(Icons.near_me_outlined,
                '${m.distantaKm! < 10 ? m.distantaKm!.toStringAsFixed(1) : m.distantaKm!.toStringAsFixed(0)} km distanță'),
        ],
      ),
    );
  }

  Widget _cardGps() {
    final m = widget.manastire;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Locație',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (m.areGps) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${m.lat!.toStringAsFixed(6)}, ${m.lon!.toStringAsFixed(6)}',
                    style: const TextStyle(color: Color(0xFF90CAF9), fontSize: 13, fontFamily: 'monospace'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.white54, size: 18),
                  tooltip: 'Copiază coordonate',
                  onPressed: _copiazaCoordonate,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _deschideGoogleMaps,
                icon: const Icon(Icons.map_outlined, size: 18),
                label: Text(
                  widget.origineLat != null
                      ? 'Traseu de la ${widget.origineNume ?? 'locație salvată'}'
                      : 'Deschide în Google Maps',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF90CAF9),
                  side: const BorderSide(color: Color(0xFF90CAF9), width: 0.5),
                ),
              ),
            ),
          ] else
            const Text('Coordonate GPS indisponibile',
                style: TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _cardJurnal() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Jurnal personal',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // Marcaj vizitat
          Row(
            children: [
              Checkbox(
                value: _vizitat,
                onChanged: (v) => setState(() => _vizitat = v ?? false),
                activeColor: const Color(0xFF1E88E5),
                side: const BorderSide(color: Colors.white38),
              ),
              const Text('Am vizitat această mănăstire',
                  style: TextStyle(color: Colors.white70)),
            ],
          ),

          // Data vizitei
          if (_vizitat) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _selecteazaData,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1B2A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white54, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('d MMMM yyyy', 'ro_RO').format(_dataSelectata),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const Spacer(),
                    const Icon(Icons.edit, color: Colors.white30, size: 14),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Editare hram
          const Text('Hram',
              style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 4),
          TextField(
            controller: _hramController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecor('Hram mănăstire...'),
          ),
          const SizedBox(height: 10),

          // Editare viețuitori
          const Text('Număr viețuitori',
              style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 4),
          TextField(
            controller: _vietuitoriController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecor('Număr viețuitori...'),
          ),
          const SizedBox(height: 10),

          const Text('Notițe personale',
              style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 4),
          TextField(
            controller: _notiteController,
            maxLines: 5,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecor('Notițe personale despre această mănăstire...'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecor(String hint, {int? maxLines}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
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
    );
  }

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2D3D),
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      );

  Widget _row(IconData icon, String text, {bool bold = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF90CAF9), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: bold ? Colors.white : Colors.white70,
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      );
}
