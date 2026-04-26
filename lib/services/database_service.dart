import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/sheet_music.dart';
import '../models/user_profile.dart';

final databaseServiceProvider = Provider((ref) {
  return DatabaseService();
});

class DatabaseService {
  static const String _dbName = 'metro_sheet.db';
  static const int _dbVersion = 2;
  static const String _tableName = 'sheet_music';
  static Database? _database;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String get _usersCollection => 'users';
  String get _sheetsCollection => 'sheets';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createTable,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE $_tableName DROP COLUMN time_signature');
        }
      },
    );
  }

  Future<void> _createTable(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        composer TEXT NOT NULL,
        bpm INTEGER NOT NULL,
        image_path TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
      ''');
  }

  Future<List<SheetMusic>> getAllSheetMusic() async {
    final db = await database;
    final maps = await db.query(_tableName, orderBy: 'created_at DESC');
    return maps.map((map) => SheetMusic.fromMap(map)).toList();
  }

  Future<SheetMusic?> getSheetMusicById(int id) async {
    final db = await database;
    final maps = await db.query(_tableName, where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return SheetMusic.fromMap(maps.first);
    }
    return null;
  }

  Future<int> getSheetMusicCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int?> addSheetMusic(SheetMusic sheetMusic, String? uid) async {
    final db = await database;
    final id = await db.insert(
      _tableName,
      sheetMusic.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (uid != null) {
      try {
        await _firestore
            .collection(_usersCollection)
            .doc(uid)
            .collection(_sheetsCollection)
            .add({
              'title': sheetMusic.title,
              'composer': sheetMusic.composer,
              'bpm': sheetMusic.bpm,
              'imagePath': sheetMusic.imagePath,
              'createdAt': sheetMusic.createdAt,
              'syncedAt': FieldValue.serverTimestamp(),
            });
      } catch (e) {
        print('Warning: Failed to sync to remote db: $e');
      }
    }
    return id;
  }

  Future<bool> updateSheetMusic(SheetMusic sheetMusic) async {
    final db = await database;
    final rowsAffected = await db.update(
      _tableName,
      sheetMusic.toMap(),
      where: 'id = ?',
      whereArgs: [sheetMusic.id],
    );
    return rowsAffected > 0;
  }

  Future<bool> deleteSheetMusic(int id, DateTime createdAt, String? uid) async {
    final db = await database;
    final rowsAffected = await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
    
    if (uid != null) {
      try {
        final snapshot = await _firestore
            .collection(_usersCollection)
            .doc(uid)
            .collection(_sheetsCollection)
            .where('createdAt', isEqualTo: createdAt)
            .get();

        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        print('Warning: Failed to delete from remote db: $e');
      }
    }
    return rowsAffected > 0;
  }

  Future<void> upsertUserProfile(UserProfile userProfile) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userProfile.uid)
          .set(userProfile.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw 'Error saving user profile: $e';
    }
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw 'Error getting user profile: $e';
    }
  }
}
