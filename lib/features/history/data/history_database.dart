import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'scan_record_model.dart';

class HistoryDatabase {
  static final HistoryDatabase instance = HistoryDatabase._init();
  static Database? _database;

  HistoryDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('history.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        value TEXT NOT NULL,
        note TEXT
      )
    ''');
  }

  Future<int> create(ScanRecord record) async {
    final db = await database;
    return await db.insert('history', record.toMap());
  }

  Future<List<ScanRecord>> readAllHistory() async {
    final db = await database;
    final orderBy = 'timestamp DESC';
    final result = await db.query('history', orderBy: orderBy);
    return result.map((json) => ScanRecord.fromMap(json)).toList();
  }

  Future<int> delete(int id) async {
    final db = await database;
    return await db.delete('history', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearAll() async {
    final db = await database;
    return await db.delete('history');
  }
}
