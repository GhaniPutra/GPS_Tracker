import 'dart:async';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class StoredDevice {
  final String id;
  final String name;
  final double? lastLat;
  final double? lastLon;
  final int? lastSeen; // epoch millis

  StoredDevice({
    required this.id,
    required this.name,
    this.lastLat,
    this.lastLon,
    this.lastSeen,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'lastLat': lastLat,
      'lastLon': lastLon,
      'lastSeen': lastSeen,
    };
  }

  factory StoredDevice.fromMap(Map<String, Object?> m) => StoredDevice(
        id: m['id'] as String,
        name: (m['name'] as String?) ?? '',
        lastLat: (m['lastLat'] as num?)?.toDouble(),
        lastLon: (m['lastLon'] as num?)?.toDouble(),
        lastSeen: m['lastSeen'] as int?,
      );
}

class DeviceDatabase {
  DeviceDatabase._internal();
  static final DeviceDatabase instance = DeviceDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'devices.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE devices (
          id TEXT PRIMARY KEY,
          name TEXT,
          lastLat REAL,
          lastLon REAL,
          lastSeen INTEGER
        )
        ''');
      },
    );
  }

  Future<void> upsertDevice(StoredDevice d) async {
    final db = await database;
    await db.insert('devices', d.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<StoredDevice>> getAllDevices() async {
    final db = await database;
    final rows = await db.query('devices');
    return rows.map((r) => StoredDevice.fromMap(r)).toList();
  }

  Future<void> deleteDeviceById(String id) async {
    final db = await database;
    await db.delete('devices', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _db = null;
  }
}
