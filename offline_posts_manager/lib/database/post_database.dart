import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/post.dart';

/// Local SQLite access for posts. All I/O is async (see assignment discussion).
class PostDatabase {
  PostDatabase._();
  static final PostDatabase instance = PostDatabase._();

  static const _dbName = 'offline_posts.db';
  static const _dbVersion = 1;
  static const tablePosts = 'posts';

  Database? _database;

  bool get isOpen => _database != null && _database!.isOpen;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    return _open();
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    _database = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE $tablePosts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  created_at INTEGER NOT NULL
)
''');
      },
    );
    return _database!;
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
    }
    _database = null;
  }

  Future<List<Post>> getAllPosts() async {
    final db = await database;
    final rows = await db.query(tablePosts, orderBy: 'created_at DESC');
    final list = <Post>[];
    for (final row in rows) {
      final post = Post.tryFromMap(row);
      if (post != null) {
        list.add(post);
      }
    }
    return list;
  }

  Future<Post?> getPostById(int id) async {
    final db = await database;
    final rows = await db.query(
      tablePosts,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Post.tryFromMap(rows.first);
  }

  Future<int> insertPost(Post post) async {
    final db = await database;
    return db.insert(tablePosts, post.toMap());
  }

  Future<int> updatePost(Post post) async {
    final id = post.id;
    if (id == null) {
      throw ArgumentError('Post id is required for update');
    }
    final db = await database;
    return db.update(
      tablePosts,
      post.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletePost(int id) async {
    final db = await database;
    return db.delete(
      tablePosts,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
