import 'package:flutter/material.dart';

import '../../domain/entities/task_priority.dart';
import '../../domain/entities/todo_task.dart';

/// Maps a task to a glyph so the planned timeline can render Structured-style
/// icon capsules without adding an icon field to the data model.
class TaskIcons {
  const TaskIcons._();

  static const _rules = <_IconRule>[
    _IconRule(Icons.fitness_center_rounded,
        ['gym', 'spor', 'workout', 'antren', 'fitness', 'ağırlık']),
    _IconRule(Icons.directions_run_rounded,
        ['koş', 'run', 'jog', 'yürüyüş', 'walk', 'maraton']),
    _IconRule(Icons.self_improvement_rounded,
        ['yoga', 'medit', 'nefes', 'mindful', 'stretch', 'esneme']),
    _IconRule(Icons.videocam_rounded,
        ['toplantı', 'meeting', 'zoom', 'teams', 'sunum', 'presentation']),
    _IconRule(
        Icons.call_rounded, ['ara ', 'call', 'telefon', 'phone', 'görüşme']),
    _IconRule(Icons.mail_outline_rounded,
        ['mail', 'eposta', 'e-posta', 'inbox', 'mesaj']),
    _IconRule(Icons.shopping_cart_rounded,
        ['market', 'alışveriş', 'shopping', 'grocer', 'bakkal']),
    _IconRule(
        Icons.local_cafe_rounded, ['kahve', 'coffee', 'çay', 'tea', 'mola']),
    _IconRule(Icons.restaurant_rounded,
        ['yemek', 'kahvaltı', 'lunch', 'dinner', 'breakfast', 'akşam yem']),
    _IconRule(
        Icons.menu_book_rounded, ['oku', 'read', 'kitap', 'book', 'makale']),
    _IconRule(Icons.school_rounded,
        ['ders', 'study', 'okul', 'school', 'sınav', 'exam', 'ödev']),
    _IconRule(Icons.code_rounded,
        ['kod', 'code', 'deploy', 'bug', 'refactor', 'commit', 'pr ']),
    _IconRule(Icons.edit_note_rounded,
        ['yaz', 'write', 'not', 'note', 'rapor', 'report', 'blog']),
    _IconRule(Icons.medication_rounded, ['ilaç', 'medic', 'vitamin', 'hap']),
    _IconRule(Icons.favorite_rounded,
        ['doktor', 'doctor', 'sağlık', 'health', 'hastane', 'diş']),
    _IconRule(Icons.flight_rounded,
        ['uçak', 'flight', 'seyahat', 'travel', 'tatil', 'vacation']),
    _IconRule(Icons.directions_car_rounded,
        ['araba', 'drive', 'sür', 'yol', 'servis', 'benzin']),
    _IconRule(Icons.cleaning_services_rounded,
        ['temizlik', 'clean', 'çamaşır', 'laundry', 'bulaşık', 'toparla']),
    _IconRule(Icons.payments_rounded,
        ['fatura', 'bill', 'öde', 'pay', 'kira', 'bank', 'vergi', 'tax']),
    _IconRule(Icons.water_drop_rounded, ['su iç', 'water', 'hidra']),
    _IconRule(Icons.bedtime_rounded, ['uyku', 'sleep', 'uyan', 'wake', 'yat']),
    _IconRule(Icons.music_note_rounded, ['müzik', 'music', 'gitar', 'piyano']),
    _IconRule(
        Icons.movie_rounded, ['film', 'movie', 'dizi', 'series', 'sinema']),
    _IconRule(Icons.sports_esports_rounded, ['oyun', 'game', 'konsol']),
    _IconRule(
        Icons.cake_rounded, ['doğum günü', 'birthday', 'yıldönümü', 'anniv']),
    _IconRule(Icons.shower_rounded, ['duş', 'shower', 'banyo', 'bath']),
    _IconRule(Icons.pets_rounded, ['köpek', 'kedi', 'dog', 'cat', 'pet']),
    _IconRule(
        Icons.local_florist_rounded, ['çiçek', 'bahçe', 'plant', 'garden']),
    _IconRule(Icons.groups_rounded,
        ['aile', 'family', 'arkadaş', 'friend', 'buluş', 'meet up']),
  ];

  /// Best-effort icon for [task], derived from its title, then its priority.
  static IconData forTask(TodoTask task) {
    final title = task.title.toLowerCase();
    for (final rule in _rules) {
      for (final keyword in rule.keywords) {
        if (title.contains(keyword)) return rule.icon;
      }
    }
    if (task.recurrence != null) return Icons.repeat_rounded;
    if (task.isImportant) return Icons.star_rounded;
    return switch (task.priority) {
      TaskPriority.high => Icons.priority_high_rounded,
      TaskPriority.medium => Icons.check_rounded,
      TaskPriority.low => Icons.remove_rounded,
    };
  }
}

class _IconRule {
  const _IconRule(this.icon, this.keywords);

  final IconData icon;
  final List<String> keywords;
}
