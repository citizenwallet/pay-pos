import 'package:pay_pos/services/db/db.dart';
import 'package:pay_pos/services/db/app/preference.dart';
import 'package:sqflite/sqflite.dart';

class AppDBService extends DBService {
  static final AppDBService _instance = AppDBService._internal();

  factory AppDBService() {
    return _instance;
  }

  AppDBService._internal();

  late PreferenceTable preferences;

  @override
  Future<Database> openDB(String path) async {
    final options = OpenDatabaseOptions(
      onConfigure: (db) async {
        preferences = PreferenceTable(db);
      },
      onCreate: (db, version) async {
        await preferences.create(db);
        return;
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await preferences.migrate(db, oldVersion, newVersion);
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
