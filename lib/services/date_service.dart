// lib/services/date_service.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/manastire.dart';

class DateService {
  static List<Manastire>? _cache;

  static Future<List<Manastire>> incarcaManastiri() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/manastiri.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    final lista = (data['manastiri'] as List)
        .map((e) => Manastire.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = lista;
    return lista;
  }

  /// Formula Haversine — distanța în km între două coordonate GPS
  static double distantaKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  /// Unghi față de Nord (0° = Nord, 90° = Est, 180° = Sud, 270° = Vest)
  static double unghi(double lat1, double lon1, double lat2, double lon2) {
    final dLon = _rad(lon2 - lon1);
    final y = sin(dLon) * cos(_rad(lat2));
    final x = cos(_rad(lat1)) * sin(_rad(lat2)) -
        sin(_rad(lat1)) * cos(_rad(lat2)) * cos(dLon);
    return (degrees(atan2(y, x)) + 360) % 360;
  }

  static double _rad(double deg) => deg * pi / 180;
  static double degrees(double rad) => rad * 180 / pi;

  /// Sortează lista după distanță față de poziția curentă
  static List<Manastire> sorteazaDupaDistanta({
    required List<Manastire> lista,
    required double latUser,
    required double lonUser,
  }) {
    for (final m in lista) {
      if (m.areGps) {
        m.distantaKm = distantaKm(latUser, lonUser, m.lat!, m.lon!);
        m.unghi = unghi(latUser, lonUser, m.lat!, m.lon!);
      } else {
        m.distantaKm = null;
        m.unghi = null;
      }
    }
    final cuGps = lista.where((m) => m.areGps).toList()
      ..sort((a, b) => a.distantaKm!.compareTo(b.distantaKm!));
    final faraGps = lista.where((m) => !m.areGps).toList();
    return [...cuGps, ...faraGps];
  }
}
