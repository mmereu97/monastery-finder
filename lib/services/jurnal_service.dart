// lib/services/jurnal_service.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class InregistrareJurnal {
  final int? id;
  final int manastireId;
  final DateTime dataVizita;
  final String notite;
  final bool vizitat;
  final String? hramCustom;
  final int? vietuitoriCustom;

  InregistrareJurnal({
    this.id,
    required this.manastireId,
    required this.dataVizita,
    required this.notite,
    required this.vizitat,
    this.hramCustom,
    this.vietuitoriCustom,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'manastire_id': manastireId,
        'data_vizita': dataVizita.toIso8601String(),
        'notite': notite,
        'vizitat': vizitat ? 1 : 0,
        'hram_custom': hramCustom,
        'vietuitori_custom': vietuitoriCustom,
      };

  factory InregistrareJurnal.fromMap(Map<String, dynamic> m) =>
      InregistrareJurnal(
        id: m['id'] as int?,
        manastireId: m['manastire_id'] as int,
        dataVizita: DateTime.parse(m['data_vizita'] as String),
        notite: m['notite'] as String? ?? '',
        vizitat: (m['vizitat'] as int) == 1,
        hramCustom: m['hram_custom'] as String?,
        vietuitoriCustom: m['vietuitori_custom'] as int?,
      );
}

class JurnalService {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final cale = join(await getDatabasesPath(), 'jurnal_pelerini.db');
    return openDatabase(
      cale,
      version: 2,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE jurnal (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          manastire_id INTEGER NOT NULL,
          data_vizita TEXT NOT NULL,
          notite TEXT,
          vizitat INTEGER NOT NULL DEFAULT 0,
          hram_custom TEXT,
          vietuitori_custom INTEGER
        )
      '''),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE jurnal ADD COLUMN hram_custom TEXT');
          await db.execute('ALTER TABLE jurnal ADD COLUMN vietuitori_custom INTEGER');
        }
      },
    );
  }

  static Future<InregistrareJurnal?> getJurnal(int manastireId) async {
    final d = await db;
    final rows = await d.query('jurnal',
        where: 'manastire_id = ?', whereArgs: [manastireId], limit: 1);
    if (rows.isEmpty) return null;
    return InregistrareJurnal.fromMap(rows.first);
  }

  static Future<void> salveaza(InregistrareJurnal inreg) async {
    final d = await db;
    final existent = await getJurnal(inreg.manastireId);
    if (existent == null) {
      await d.insert('jurnal', inreg.toMap());
    } else {
      await d.update('jurnal', inreg.toMap(),
          where: 'manastire_id = ?', whereArgs: [inreg.manastireId]);
    }
  }

  static Future<Set<int>> getIdVizitate() async {
    final d = await db;
    final rows =
        await d.query('jurnal', where: 'vizitat = 1', columns: ['manastire_id']);
    return rows.map((r) => r['manastire_id'] as int).toSet();
  }
}
