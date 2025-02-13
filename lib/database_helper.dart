import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'word.dart';

class DatabaseHelper {
  static const _databaseName = "WordsDB.db";
  static const _databaseVersion = 2;  // Increment version to trigger database upgrade
  static const table = 'words';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        word TEXT NOT NULL,
        category TEXT NOT NULL,
        hint TEXT NOT NULL,
        used INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Drop the old table and create a new one
      await db.execute('DROP TABLE IF EXISTS $table');
      await _onCreate(db, newVersion);
    }
  }

  Future<void> clearTable() async {
    Database db = await instance.database;
    await db.delete(table);
  }

  Future<int> insert(Word word) async {
    Database db = await instance.database;
    return await db.insert(
      table, 
      word.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  Future<List<Word>> getAllWords() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(table);
    return List.generate(maps.length, (i) {
      return Word.fromMap(maps[i]);
    });
  }

  Future<Word?> getUnusedWord() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      table,
      where: 'used = ?',
      whereArgs: [0],
      limit: 1,
      orderBy: 'RANDOM()'
    );
    
    if (maps.isEmpty) {
      // If all words are used, reset all words to unused
      await db.update(
        table,
        {'used': 0},
        where: '1 = 1'  // Updates all rows
      );
      return getUnusedWord();  // Try again
    }
    
    return Word.fromMap(maps.first);
  }

  Future<void> markWordAsUsed(String word) async {
    Database db = await instance.database;
    await db.update(
      table,
      {'used': 1},
      where: 'word = ?',
      whereArgs: [word]
    );
  }

  Future<void> resetAllWords() async {
    Database db = await instance.database;
    await db.update(
      table,
      {'used': 0},
      where: '1 = 1'  // Updates all rows
    );
  }

  Future<int> getWordCount() async {
    Database db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
