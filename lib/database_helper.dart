import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'word.dart';

class DatabaseHelper {
  static const _databaseName = "WordsDB.db";
  static const _databaseVersion = 3;  // Increment version for new table
  static const table = 'words';
  static const userTable = 'user_data';

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

    await db.execute('''
      CREATE TABLE $userTable (
        id INTEGER PRIMARY KEY,
        can_shuffle INTEGER NOT NULL DEFAULT 1,
        can_hint INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Insert initial user data
    await db.insert(userTable, {
      'id': 1,
      'can_shuffle': 1,
      'can_hint': 1,
    });
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Drop the old table and create a new one
      await db.execute('DROP TABLE IF EXISTS $table');
      await _onCreate(db, newVersion);
    } else if (oldVersion < 3) {
      // Create user_data table if upgrading from older version
      await db.execute('''
        CREATE TABLE $userTable (
          id INTEGER PRIMARY KEY,
          can_shuffle INTEGER NOT NULL DEFAULT 1,
          can_hint INTEGER NOT NULL DEFAULT 1
        )
      ''');

      // Insert initial user data
      await db.insert(userTable, {
        'id': 1,
        'can_shuffle': 1,
        'can_hint': 1,
      });
    }
  }

  Future<void> clearTable() async {
    Database db = await instance.database;
    await db.delete(table);
  }

  Future<bool> wordExists(String word) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> result = await db.query(
      table,
      where: 'word = ?',
      whereArgs: [word],
    );
    return result.isNotEmpty;
  }

  Future<void> insertWordIfNotExists(Word word) async {
    if (!await wordExists(word.word)) {
      await insertWord(word);
    }
  }

  Future<void> insertWord(Word word) async {
    Database db = await instance.database;
    await db.insert(
      table,
      word.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> insertWords(List<Word> words) async {
    for (var word in words) {
      await insertWordIfNotExists(word);
    }
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
      whereArgs: [word],
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

  Future<int> getUnusedWordCount() async {
    Database db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table WHERE used = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getWordCount() async {
    Database db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // User data methods
  Future<bool> canUseHint() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query(
      userTable,
      where: 'id = ?',
      whereArgs: [1],
    );
    return result.first['can_hint'] == 1;
  }

  Future<bool> canUseShuffle() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query(
      userTable,
      where: 'id = ?',
      whereArgs: [1],
    );
    return result.first['can_shuffle'] == 1;
  }

  Future<void> useHint() async {
    Database db = await instance.database;
    await db.update(
      userTable,
      {'can_hint': 0},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<void> useShuffle() async {
    Database db = await instance.database;
    await db.update(
      userTable,
      {'can_shuffle': 0},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<void> resetHint() async {
    Database db = await instance.database;
    await db.update(
      userTable,
      {'can_hint': 1},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<void> resetShuffle() async {
    Database db = await instance.database;
    await db.update(
      userTable,
      {'can_shuffle': 1},
      where: 'id = ?',
      whereArgs: [1],
    );
  }
}
