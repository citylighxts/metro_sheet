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
  static const int _dbVersion = 4;
  static const String _usersTable = 'users';
  static const String _sheetsTable = 'sheet_music';
  static const String _usersCollection = 'users';
  static const String _sheetsCollection = 'sheets';
  static Database? _database;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE $_sheetsTable DROP COLUMN time_signature');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE $_sheetsTable DROP COLUMN bpm');
        }
        if (oldVersion < 4) {
          // Create users table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $_usersTable (
              uid TEXT PRIMARY KEY,
              email TEXT NOT NULL,
              display_name TEXT,
              created_at TEXT NOT NULL
            )
          ''');
          // Add user_id foreign key column to sheet_music
          await db.execute(
            'ALTER TABLE $_sheetsTable ADD COLUMN user_id TEXT REFERENCES $_usersTable(uid)',
          );
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_usersTable (
        uid TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        display_name TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $_sheetsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT REFERENCES $_usersTable(uid),
        title TEXT NOT NULL,
        composer TEXT NOT NULL,
        image_path TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // ── Users ──────────────────────────────────────────────────────────────────

  Future<void> insertLocalUser(UserProfile user) async {
    final db = await database;
    await db.insert(
      _usersTable,
      user.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<UserProfile?> getLocalUser(String uid) async {
    final db = await database;
    final maps = await db.query(_usersTable, where: 'uid = ?', whereArgs: [uid]);
    if (maps.isNotEmpty) return UserProfile.fromSqliteMap(maps.first);
    return null;
  }

  // ── Sheet Music ────────────────────────────────────────────────────────────

  Future<List<SheetMusic>> getAllSheetMusic() async {
    final db = await database;
    final maps = await db.query(_sheetsTable, orderBy: 'created_at DESC');
    return maps.map((map) => SheetMusic.fromMap(map)).toList();
  }

  Future<SheetMusic?> getSheetMusicById(int id) async {
    final db = await database;
    final maps = await db.query(_sheetsTable, where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return SheetMusic.fromMap(maps.first);
    return null;
  }

  Future<int> getSheetMusicCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_sheetsTable');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int?> addSheetMusic(SheetMusic sheetMusic, String? uid, String? email) async {
    final db = await database;

    // Ensure user exists before inserting sheet (guards against race condition)
    if (uid != null) {
      final existing = await db.query(_usersTable, where: 'uid = ?', whereArgs: [uid]);
      if (existing.isEmpty) {
        await db.insert(
          _usersTable,
          {'uid': uid, 'email': email ?? '', 'created_at': DateTime.now().toIso8601String()},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }

    final map = sheetMusic.toMap();
    if (uid != null) map['user_id'] = uid;

    final id = await db.insert(
      _sheetsTable,
      map,
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
              'imagePath': sheetMusic.imagePath,
              'createdAt': sheetMusic.createdAt,
              'syncedAt': FieldValue.serverTimestamp(),
            });
      } catch (_) {
        // Firestore sync failure is non-fatal — local save succeeded
      }
    }
    return id;
  }

  Future<bool> updateSheetMusic(SheetMusic sheetMusic) async {
    final db = await database;
    final rowsAffected = await db.update(
      _sheetsTable,
      sheetMusic.toMap(),
      where: 'id = ?',
      whereArgs: [sheetMusic.id],
    );
    return rowsAffected > 0;
  }

  Future<bool> deleteSheetMusic(int id, DateTime createdAt, String? uid) async {
    final db = await database;
    final rowsAffected = await db.delete(_sheetsTable, where: 'id = ?', whereArgs: [id]);

    if (uid != null) {
      try {
        final snapshot = await _firestore
            .collection(_usersCollection)
            .doc(uid)
            .collection(_sheetsCollection)
            .where('createdAt', isEqualTo: createdAt)
            .get();
        for (final doc in snapshot.docs) {
          await doc.reference.delete();
        }
      } catch (_) {
        // Firestore delete failure is non-fatal — local delete succeeded
      }
    }
    return rowsAffected > 0;
  }

  // ── Firestore User Profile ─────────────────────────────────────────────────

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
      if (doc.exists) return UserProfile.fromFirestore(doc);
      return null;
    } catch (e) {
      throw 'Error getting user profile: $e';
    }
  }
}
