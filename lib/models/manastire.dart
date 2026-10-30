// lib/models/manastire.dart

class Manastire {
  final int id;
  final String nume;
  final String judet;
  final String tip;
  final String hram;
  final int? an;
  final String regiune;
  final String arhiepiscopie;
  final String mitropolie;
  final int? vietuitori;
  final double? lat;
  final double? lon;

  // Calculat la runtime
  double? distantaKm;
  double? unghi; // grade față de Nord, pentru săgeată

  Manastire({
    required this.id,
    required this.nume,
    required this.judet,
    required this.tip,
    required this.hram,
    this.an,
    required this.regiune,
    required this.arhiepiscopie,
    required this.mitropolie,
    this.vietuitori,
    this.lat,
    this.lon,
    this.distantaKm,
    this.unghi,
  });

  bool get areGps => lat != null && lon != null;

  factory Manastire.fromJson(Map<String, dynamic> j) => Manastire(
        id: j['id'] as int,
        nume: j['nume'] as String,
        judet: j['judet'] as String,
        tip: j['tip'] as String? ?? '',
        hram: j['hram'] as String? ?? '',
        an: j['an'] as int?,
        regiune: j['regiune'] as String? ?? '',
        arhiepiscopie: j['arhiepiscopie'] as String? ?? '',
        mitropolie: j['mitropolie'] as String? ?? '',
        vietuitori: j['vietuitori'] as int?,
        lat: (j['lat'] as num?)?.toDouble(),
        lon: (j['lon'] as num?)?.toDouble(),
      );
}
