import 'package:flutter/material.dart';

/// A pickable glyph. [key] is what gets stored on the task, so it must stay
/// stable once shipped.
@immutable
class TaskIconEntry {
  const TaskIconEntry({
    required this.key,
    required this.icon,
    required this.category,
    this.keywords = const <String>[],
  });

  final String key;
  final IconData icon;
  final TaskIconCategory category;

  /// Turkish and English fragments that suggest this glyph from a title.
  final List<String> keywords;
}

enum TaskIconCategory {
  general,
  work,
  health,
  food,
  home,
  learning,
  social,
  travel,
  leisure,
  money,
}

/// The icon library behind the planned composer: suggestions while typing,
/// browsable categories, and a search field.
class TaskIconCatalog {
  const TaskIconCatalog._();

  static const fallbackKey = 'check';

  static const entries = <TaskIconEntry>[
    // General
    TaskIconEntry(
      key: 'check',
      icon: Icons.check_rounded,
      category: TaskIconCategory.general,
      keywords: ['görev', 'task', 'yap', 'todo'],
    ),
    TaskIconEntry(
      key: 'star',
      icon: Icons.star_rounded,
      category: TaskIconCategory.general,
      keywords: ['önemli', 'important', 'favori'],
    ),
    TaskIconEntry(
      key: 'flag',
      icon: Icons.flag_rounded,
      category: TaskIconCategory.general,
      keywords: ['hedef', 'goal', 'milestone'],
    ),
    TaskIconEntry(
      key: 'bolt',
      icon: Icons.bolt_rounded,
      category: TaskIconCategory.general,
      keywords: ['enerji', 'energy', 'hızlı'],
    ),
    TaskIconEntry(
      key: 'alarm',
      icon: Icons.alarm_rounded,
      category: TaskIconCategory.general,
      keywords: ['alarm', 'uyan', 'wake', 'kalk'],
    ),
    TaskIconEntry(
      key: 'timer',
      icon: Icons.timer_outlined,
      category: TaskIconCategory.general,
      keywords: ['süre', 'timer', 'pomodoro', 'odak', 'focus'],
    ),
    TaskIconEntry(
      key: 'repeat',
      icon: Icons.repeat_rounded,
      category: TaskIconCategory.general,
      keywords: ['rutin', 'routine', 'tekrar', 'habit', 'alışkanlık'],
    ),
    TaskIconEntry(
      key: 'checklist',
      icon: Icons.checklist_rounded,
      category: TaskIconCategory.general,
      keywords: ['liste', 'list', 'plan'],
    ),
    TaskIconEntry(
      key: 'bell',
      icon: Icons.notifications_active_rounded,
      category: TaskIconCategory.general,
      keywords: ['hatırlat', 'reminder', 'bildirim'],
    ),
    TaskIconEntry(
      key: 'sun',
      icon: Icons.wb_sunny_rounded,
      category: TaskIconCategory.general,
      // Time-of-day words are weak signals, so this entry sticks to the
      // literal sun: "Sabah koşusu" should still resolve to the run glyph.
      keywords: ['güneş', 'sunny', 'gün ışığı'],
    ),
    TaskIconEntry(
      key: 'moon',
      icon: Icons.bedtime_rounded,
      category: TaskIconCategory.general,
      keywords: ['uyku', 'sleep', 'gece', 'night', 'yat'],
    ),
    TaskIconEntry(
      key: 'pin',
      icon: Icons.push_pin_rounded,
      category: TaskIconCategory.general,
      keywords: ['sabit', 'pin', 'yer'],
    ),

    // Work
    TaskIconEntry(
      key: 'work',
      icon: Icons.work_rounded,
      category: TaskIconCategory.work,
      keywords: ['iş', 'work', 'ofis', 'office', 'mesai'],
    ),
    TaskIconEntry(
      key: 'meeting',
      icon: Icons.videocam_rounded,
      category: TaskIconCategory.work,
      keywords: ['toplantı', 'meeting', 'zoom', 'teams', 'görüşme'],
    ),
    TaskIconEntry(
      key: 'presentation',
      icon: Icons.co_present_rounded,
      category: TaskIconCategory.work,
      keywords: ['sunum', 'presentation', 'demo', 'pitch'],
    ),
    TaskIconEntry(
      key: 'call',
      icon: Icons.call_rounded,
      category: TaskIconCategory.work,
      keywords: ['ara', 'call', 'telefon', 'phone'],
    ),
    TaskIconEntry(
      key: 'mail',
      icon: Icons.mail_rounded,
      category: TaskIconCategory.work,
      keywords: ['mail', 'eposta', 'e-posta', 'inbox', 'mesaj'],
    ),
    TaskIconEntry(
      key: 'code',
      icon: Icons.code_rounded,
      category: TaskIconCategory.work,
      keywords: ['kod', 'code', 'deploy', 'bug', 'refactor', 'commit'],
    ),
    TaskIconEntry(
      key: 'design',
      icon: Icons.brush_rounded,
      category: TaskIconCategory.work,
      keywords: ['tasarım', 'design', 'figma', 'çizim'],
    ),
    TaskIconEntry(
      key: 'document',
      icon: Icons.description_rounded,
      category: TaskIconCategory.work,
      keywords: ['rapor', 'report', 'belge', 'doküman', 'yaz', 'write'],
    ),
    TaskIconEntry(
      key: 'chart',
      icon: Icons.insights_rounded,
      category: TaskIconCategory.work,
      keywords: ['analiz', 'analytics', 'rakam', 'metrik', 'grafik'],
    ),
    TaskIconEntry(
      key: 'briefcase',
      icon: Icons.business_center_rounded,
      category: TaskIconCategory.work,
      keywords: ['müşteri', 'client', 'satış', 'sales'],
    ),
    TaskIconEntry(
      key: 'print',
      icon: Icons.print_rounded,
      category: TaskIconCategory.work,
      keywords: ['yazdır', 'print', 'çıktı'],
    ),
    TaskIconEntry(
      key: 'idea',
      icon: Icons.lightbulb_rounded,
      category: TaskIconCategory.work,
      keywords: ['fikir', 'idea', 'beyin', 'brainstorm'],
    ),

    // Health & sport
    TaskIconEntry(
      key: 'gym',
      icon: Icons.fitness_center_rounded,
      category: TaskIconCategory.health,
      keywords: ['gym', 'spor', 'workout', 'antren', 'ağırlık'],
    ),
    TaskIconEntry(
      key: 'run',
      icon: Icons.directions_run_rounded,
      category: TaskIconCategory.health,
      keywords: ['koş', 'run', 'jog', 'maraton'],
    ),
    TaskIconEntry(
      key: 'walk',
      icon: Icons.directions_walk_rounded,
      category: TaskIconCategory.health,
      keywords: ['yürüyüş', 'walk', 'adım'],
    ),
    TaskIconEntry(
      key: 'yoga',
      icon: Icons.self_improvement_rounded,
      category: TaskIconCategory.health,
      keywords: ['yoga', 'medit', 'nefes', 'mindful', 'esneme', 'stretch'],
    ),
    TaskIconEntry(
      key: 'bike',
      icon: Icons.directions_bike_rounded,
      category: TaskIconCategory.health,
      keywords: ['bisiklet', 'bike', 'pedal'],
    ),
    TaskIconEntry(
      key: 'swim',
      icon: Icons.pool_rounded,
      category: TaskIconCategory.health,
      keywords: ['yüzme', 'swim', 'havuz'],
    ),
    TaskIconEntry(
      key: 'football',
      icon: Icons.sports_soccer_rounded,
      category: TaskIconCategory.health,
      keywords: ['futbol', 'maç', 'soccer', 'halı saha'],
    ),
    TaskIconEntry(
      key: 'basketball',
      icon: Icons.sports_basketball_rounded,
      category: TaskIconCategory.health,
      keywords: ['basketbol', 'basketball', 'pota'],
    ),
    TaskIconEntry(
      key: 'medication',
      icon: Icons.medication_rounded,
      category: TaskIconCategory.health,
      keywords: ['ilaç', 'medic', 'vitamin', 'hap'],
    ),
    TaskIconEntry(
      key: 'doctor',
      icon: Icons.local_hospital_rounded,
      category: TaskIconCategory.health,
      keywords: ['doktor', 'doctor', 'hastane', 'randevu', 'diş'],
    ),
    TaskIconEntry(
      key: 'heart',
      icon: Icons.favorite_rounded,
      category: TaskIconCategory.health,
      keywords: ['sağlık', 'health', 'kalp', 'nabız'],
    ),
    TaskIconEntry(
      key: 'water',
      icon: Icons.water_drop_rounded,
      category: TaskIconCategory.health,
      keywords: ['su', 'water', 'hidra', 'iç'],
    ),
    TaskIconEntry(
      key: 'shower',
      icon: Icons.shower_rounded,
      category: TaskIconCategory.health,
      keywords: ['duş', 'shower', 'banyo', 'bath'],
    ),
    TaskIconEntry(
      key: 'spa',
      icon: Icons.spa_rounded,
      category: TaskIconCategory.health,
      keywords: ['bakım', 'spa', 'cilt', 'masaj'],
    ),

    // Food
    TaskIconEntry(
      key: 'breakfast',
      icon: Icons.egg_alt_rounded,
      category: TaskIconCategory.food,
      keywords: ['kahvaltı', 'breakfast', 'yumurta'],
    ),
    TaskIconEntry(
      key: 'meal',
      icon: Icons.restaurant_rounded,
      category: TaskIconCategory.food,
      keywords: ['yemek', 'lunch', 'dinner', 'öğle', 'akşam yem'],
    ),
    TaskIconEntry(
      key: 'coffee',
      icon: Icons.local_cafe_rounded,
      category: TaskIconCategory.food,
      keywords: ['kahve', 'coffee', 'çay', 'tea', 'mola'],
    ),
    TaskIconEntry(
      key: 'groceries',
      icon: Icons.shopping_cart_rounded,
      category: TaskIconCategory.food,
      keywords: ['market', 'alışveriş', 'shopping', 'bakkal', 'grocer'],
    ),
    TaskIconEntry(
      key: 'cook',
      icon: Icons.soup_kitchen_rounded,
      category: TaskIconCategory.food,
      keywords: ['pişir', 'cook', 'mutfak', 'tarif'],
    ),
    TaskIconEntry(
      key: 'cake',
      icon: Icons.cake_rounded,
      category: TaskIconCategory.food,
      keywords: ['doğum günü', 'birthday', 'pasta', 'kutlama'],
    ),
    TaskIconEntry(
      key: 'bar',
      icon: Icons.local_bar_rounded,
      category: TaskIconCategory.food,
      keywords: ['bar', 'içki', 'kokteyl', 'drink'],
    ),

    // Home
    TaskIconEntry(
      key: 'home',
      icon: Icons.home_rounded,
      category: TaskIconCategory.home,
      keywords: ['ev', 'home', 'eve'],
    ),
    TaskIconEntry(
      key: 'cleaning',
      icon: Icons.cleaning_services_rounded,
      category: TaskIconCategory.home,
      keywords: ['temizlik', 'clean', 'toparla', 'süpür'],
    ),
    TaskIconEntry(
      key: 'laundry',
      icon: Icons.local_laundry_service_rounded,
      category: TaskIconCategory.home,
      keywords: ['çamaşır', 'laundry', 'ütü'],
    ),
    TaskIconEntry(
      key: 'dishes',
      icon: Icons.countertops_rounded,
      category: TaskIconCategory.home,
      keywords: ['bulaşık', 'dishes', 'mutfak temiz'],
    ),
    TaskIconEntry(
      key: 'trash',
      icon: Icons.delete_rounded,
      category: TaskIconCategory.home,
      keywords: ['çöp', 'trash', 'atık'],
    ),
    TaskIconEntry(
      key: 'plant',
      icon: Icons.local_florist_rounded,
      category: TaskIconCategory.home,
      keywords: ['çiçek', 'bahçe', 'plant', 'sula', 'garden'],
    ),
    TaskIconEntry(
      key: 'pet',
      icon: Icons.pets_rounded,
      category: TaskIconCategory.home,
      keywords: ['köpek', 'kedi', 'dog', 'cat', 'pet', 'mama'],
    ),
    TaskIconEntry(
      key: 'repair',
      icon: Icons.handyman_rounded,
      category: TaskIconCategory.home,
      keywords: ['tamir', 'repair', 'montaj', 'usta'],
    ),
    TaskIconEntry(
      key: 'baby',
      icon: Icons.child_friendly_rounded,
      category: TaskIconCategory.home,
      keywords: ['bebek', 'baby', 'çocuk', 'kreş'],
    ),

    // Learning
    TaskIconEntry(
      key: 'study',
      icon: Icons.school_rounded,
      category: TaskIconCategory.learning,
      keywords: ['ders', 'study', 'okul', 'school', 'sınav', 'ödev'],
    ),
    TaskIconEntry(
      key: 'book',
      icon: Icons.menu_book_rounded,
      category: TaskIconCategory.learning,
      keywords: ['oku', 'read', 'kitap', 'book', 'makale'],
    ),
    TaskIconEntry(
      key: 'language',
      icon: Icons.translate_rounded,
      category: TaskIconCategory.learning,
      keywords: ['dil', 'language', 'ingilizce', 'kelime'],
    ),
    TaskIconEntry(
      key: 'course',
      icon: Icons.play_lesson_rounded,
      category: TaskIconCategory.learning,
      keywords: ['kurs', 'course', 'eğitim', 'video ders'],
    ),
    TaskIconEntry(
      key: 'notes',
      icon: Icons.edit_note_rounded,
      category: TaskIconCategory.learning,
      keywords: ['not', 'note', 'günlük', 'journal'],
    ),
    TaskIconEntry(
      key: 'science',
      icon: Icons.science_rounded,
      category: TaskIconCategory.learning,
      keywords: ['lab', 'deney', 'science', 'araştırma'],
    ),

    // Social
    TaskIconEntry(
      key: 'friends',
      icon: Icons.groups_rounded,
      category: TaskIconCategory.social,
      keywords: ['arkadaş', 'friend', 'buluş', 'aile', 'family'],
    ),
    TaskIconEntry(
      key: 'date',
      icon: Icons.favorite_border_rounded,
      category: TaskIconCategory.social,
      keywords: ['randevu', 'date', 'sevgili', 'eş'],
    ),
    TaskIconEntry(
      key: 'party',
      icon: Icons.celebration_rounded,
      category: TaskIconCategory.social,
      keywords: ['parti', 'party', 'kutlama', 'davet'],
    ),
    TaskIconEntry(
      key: 'gift',
      icon: Icons.card_giftcard_rounded,
      category: TaskIconCategory.social,
      keywords: ['hediye', 'gift', 'sürpriz'],
    ),
    TaskIconEntry(
      key: 'chat',
      icon: Icons.forum_rounded,
      category: TaskIconCategory.social,
      keywords: ['sohbet', 'chat', 'mesajlaş', 'konuş'],
    ),

    // Travel
    TaskIconEntry(
      key: 'flight',
      icon: Icons.flight_rounded,
      category: TaskIconCategory.travel,
      keywords: ['uçak', 'flight', 'havalimanı', 'seyahat', 'travel'],
    ),
    TaskIconEntry(
      key: 'car',
      icon: Icons.directions_car_rounded,
      category: TaskIconCategory.travel,
      keywords: ['araba', 'drive', 'sür', 'yol', 'benzin'],
    ),
    TaskIconEntry(
      key: 'bus',
      icon: Icons.directions_bus_rounded,
      category: TaskIconCategory.travel,
      keywords: ['otobüs', 'bus', 'metro', 'toplu taşıma'],
    ),
    TaskIconEntry(
      key: 'train',
      icon: Icons.train_rounded,
      category: TaskIconCategory.travel,
      keywords: ['tren', 'train', 'gar'],
    ),
    TaskIconEntry(
      key: 'hotel',
      icon: Icons.hotel_rounded,
      category: TaskIconCategory.travel,
      keywords: ['otel', 'hotel', 'konaklama', 'tatil', 'vacation'],
    ),
    TaskIconEntry(
      key: 'beach',
      icon: Icons.beach_access_rounded,
      category: TaskIconCategory.travel,
      keywords: ['plaj', 'beach', 'deniz', 'sahil'],
    ),
    TaskIconEntry(
      key: 'map',
      icon: Icons.map_rounded,
      category: TaskIconCategory.travel,
      keywords: ['harita', 'map', 'rota', 'gezi'],
    ),

    // Leisure
    TaskIconEntry(
      key: 'music',
      icon: Icons.music_note_rounded,
      category: TaskIconCategory.leisure,
      keywords: ['müzik', 'music', 'gitar', 'piyano', 'şarkı'],
    ),
    TaskIconEntry(
      key: 'movie',
      icon: Icons.movie_rounded,
      category: TaskIconCategory.leisure,
      keywords: ['film', 'movie', 'dizi', 'series', 'sinema'],
    ),
    TaskIconEntry(
      key: 'game',
      icon: Icons.sports_esports_rounded,
      category: TaskIconCategory.leisure,
      keywords: ['oyun', 'game', 'konsol'],
    ),
    TaskIconEntry(
      key: 'photo',
      icon: Icons.photo_camera_rounded,
      category: TaskIconCategory.leisure,
      keywords: ['fotoğraf', 'photo', 'çekim', 'kamera'],
    ),
    TaskIconEntry(
      key: 'podcast',
      icon: Icons.podcasts_rounded,
      category: TaskIconCategory.leisure,
      keywords: ['podcast', 'yayın', 'radyo'],
    ),
    TaskIconEntry(
      key: 'tv',
      icon: Icons.tv_rounded,
      category: TaskIconCategory.leisure,
      keywords: ['tv', 'televizyon', 'izle', 'watch'],
    ),
    TaskIconEntry(
      key: 'paint',
      icon: Icons.palette_rounded,
      category: TaskIconCategory.leisure,
      keywords: ['resim', 'boya', 'paint', 'hobi'],
    ),

    // Money
    TaskIconEntry(
      key: 'payment',
      icon: Icons.payments_rounded,
      category: TaskIconCategory.money,
      keywords: ['fatura', 'bill', 'öde', 'pay', 'kira'],
    ),
    TaskIconEntry(
      key: 'bank',
      icon: Icons.account_balance_rounded,
      category: TaskIconCategory.money,
      keywords: ['banka', 'bank', 'vergi', 'tax', 'kredi'],
    ),
    TaskIconEntry(
      key: 'savings',
      icon: Icons.savings_rounded,
      category: TaskIconCategory.money,
      keywords: ['birikim', 'savings', 'bütçe', 'budget'],
    ),
    TaskIconEntry(
      key: 'shop',
      icon: Icons.local_mall_rounded,
      category: TaskIconCategory.money,
      keywords: ['sipariş', 'order', 'kargo', 'satın al'],
    ),
  ];

  static final Map<String, TaskIconEntry> _byKey = {
    for (final entry in entries) entry.key: entry,
  };

  static IconData resolve(String? key) =>
      (_byKey[key] ?? _byKey[fallbackKey]!).icon;

  static TaskIconEntry? entryFor(String? key) =>
      key == null ? null : _byKey[key];

  static List<TaskIconEntry> byCategory(TaskIconCategory category) =>
      entries.where((entry) => entry.category == category).toList();

  static final _wordChars = RegExp(r'[\wçğıöşüâîû]');

  /// Keys whose keywords appear in [title], best match first.
  ///
  /// A keyword that stands as its own word outranks one that merely hides
  /// inside another ("tea" in "team meeting" must not win over "meeting").
  static List<String> suggestKeys(String title, {int max = 6}) {
    final text = title.toLowerCase().trim();
    if (text.isEmpty) return const <String>[];
    final scored = <String, int>{};
    for (final entry in entries) {
      for (final keyword in entry.keywords) {
        final index = text.indexOf(keyword);
        if (index < 0) continue;
        final before = index == 0 ? '' : text[index - 1];
        final afterIndex = index + keyword.length;
        final after = afterIndex >= text.length ? '' : text[afterIndex];
        final standalone =
            !_wordChars.hasMatch(before) && !_wordChars.hasMatch(after);
        final score = keyword.length * 2 + (standalone ? 5 : 0);
        scored[entry.key] = (scored[entry.key] ?? 0) + score;
      }
    }
    final keys = scored.keys.toList()
      ..sort((a, b) => scored[b]!.compareTo(scored[a]!));
    return keys.take(max).toList();
  }

  /// Free-text search across keys and keywords for the picker's search field.
  static List<TaskIconEntry> search(String query) {
    final text = query.toLowerCase().trim();
    if (text.isEmpty) return entries;
    return entries
        .where((entry) =>
            entry.key.contains(text) ||
            entry.keywords.any((keyword) => keyword.contains(text)))
        .toList();
  }
}
