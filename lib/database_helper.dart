import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'word.dart';

class DatabaseHelper {
  static const _databaseName = "WordsDB.db";
  static const _databaseVersion = 1;
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
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        word TEXT NOT NULL,
        category TEXT NOT NULL,
        hint TEXT NOT NULL
      )
      ''');
  }

  Future<int> insert(Word word) async {
    Database db = await instance.database;
    return await db.insert(table, word.toMap());
  }

  Future<List<Word>> getAllWords() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(table);
    return List.generate(maps.length, (i) {
      return Word.fromMap(maps[i]);
    });
  }
}
