import 'package:pay_pos/services/db/db.dart';
import 'package:pay_pos/services/db/app/communities.dart';
import 'package:sqflite/sqflite.dart';

class AppDBService extends DBService {
  static final AppDBService _instance = AppDBService._internal();

  factory AppDBService() {
    return _instance;
  }

  AppDBService._internal();

  late CommunityTable communities;

  @override
  Future<Database> openDB(String path) async {
    final options = OpenDatabaseOptions(
      onConfigure: (db) async {
        communities = CommunityTable(db);
      },
      onCreate: (db, version) async {
        await communities.create(db);
        return;
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await communities.migrate(db, oldVersion, newVersion);
        return;
      },
      version: 1,
    );

    final db = await databaseFactory.openDatabase(
      path,
      options: options,
    );

    return db;
  }
  
}
