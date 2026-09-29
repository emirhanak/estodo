import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../firebase_options.dart';
import '../constants/app_constants.dart';

class Bootstrap {
  const Bootstrap._();

  static Future<SharedPreferences> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    final results = await Future.wait([
      Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).then((_) {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      }),
      Hive.initFlutter().then((_) => Future.wait([
            Hive.openBox(AppConstants.tasksBox),
            Hive.openBox(AppConstants.listsBox),
            Hive.openBox(AppConstants.groupsBox),
            Hive.openBox(AppConstants.settingsBox),
          ])),
      initializeDateFormatting(),
      SharedPreferences.getInstance(),
    ]);

    return results[3] as SharedPreferences;
  }
}
