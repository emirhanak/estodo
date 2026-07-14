import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../firebase_options.dart';
import '../constants/app_constants.dart';

class Bootstrap {
  const Bootstrap._();

  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    await Hive.initFlutter();
    await Hive.openBox(AppConstants.tasksBox);
    await Hive.openBox(AppConstants.listsBox);
    await Hive.openBox(AppConstants.groupsBox);
    await Hive.openBox(AppConstants.settingsBox);
    await initializeDateFormatting();
  }
}
