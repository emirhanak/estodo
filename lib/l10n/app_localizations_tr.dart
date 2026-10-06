// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'estodo';

  @override
  String get myDay => 'Günüm';

  @override
  String get important => 'Önemli';

  @override
  String get planned => 'Planlanmış';

  @override
  String get tasks => 'Görevler';

  @override
  String get completed => 'Tamamlandı';

  @override
  String get search => 'Ara';

  @override
  String get settings => 'Ayarlar';

  @override
  String get lists => 'Listeler';

  @override
  String get newList => 'Yeni liste';

  @override
  String get listUnavailable => 'Liste kullanılamıyor';

  @override
  String get selectAnotherList => 'Kenar menüden başka bir liste seçin.';

  @override
  String get renameList => 'Listeyi yeniden adlandır';

  @override
  String get deleteList => 'Listeyi sil';

  @override
  String get deleteListConfirmTitle => 'Liste silinsin mi?';

  @override
  String deleteListConfirmBody(String name) {
    return '\"$name\" listesindeki görevler Görevler listesine taşınacak.';
  }

  @override
  String get listName => 'Liste adı';

  @override
  String get addTask => 'Görev ekle';

  @override
  String get newTask => 'Yeni görev';

  @override
  String get taskName => 'Görev adı';

  @override
  String get taskNameRequired => 'Görev adı boş bırakılamaz.';

  @override
  String get addNote => 'Not ekle';

  @override
  String get addStep => 'Madde ekle';

  @override
  String get upcomingPlans => 'Yaklaşan planlarım';

  @override
  String get remindMe => 'Bana hatırlat';

  @override
  String get reminder => 'Hatırlatıcı';

  @override
  String get addDueDate => 'Son tarih ekle';

  @override
  String get startTime => 'Başlangıç zamanı';

  @override
  String get duration => 'Süre';

  @override
  String get allDay => 'Tüm gün';

  @override
  String durationMinutes(Object minutes) {
    return '$minutes dakika';
  }

  @override
  String get customDuration => 'Özel süre';

  @override
  String get minutes => 'dakika';

  @override
  String get composerTitleHint => 'Ne planlıyorsun?';

  @override
  String get composerHabitHint => 'Hangi alışkanlık?';

  @override
  String get composerHabitBanner =>
      'Alışkanlıklar kendi kendine geri gelir. Ritmini seç, zaman çizelgesi sürdürsün.';

  @override
  String get composerNlpHint =>
      '“1 saat yoga cuma 16:00” yaz — saat, gün ve süre başlıktan okunur.';

  @override
  String get composerContinue => 'Devam';

  @override
  String get composerCreateTask => 'Oluştur';

  @override
  String get composerCreateHabit => 'Oluştur';

  @override
  String get composerKindTask => 'Plan';

  @override
  String get composerKindHabit => 'Alışkanlık';

  @override
  String get composerSuggestions => 'Öneriler';

  @override
  String get composerColorAndIcon => 'Renk ve simge';

  @override
  String get composerSearchIcons => 'Simge ara';

  @override
  String get composerCategoryAll => 'Tümü';

  @override
  String get composerCategoryGeneral => 'Genel';

  @override
  String get composerCategoryWork => 'İş';

  @override
  String get composerCategoryHealth => 'Sağlık';

  @override
  String get composerCategoryFood => 'Yemek';

  @override
  String get composerCategoryHome => 'Ev';

  @override
  String get composerCategoryLearning => 'Öğrenme';

  @override
  String get composerCategorySocial => 'Sosyal';

  @override
  String get composerCategoryTravel => 'Seyahat';

  @override
  String get composerCategoryLeisure => 'Keyif';

  @override
  String get composerCategoryMoney => 'Para';

  @override
  String get composerTime => 'Saat';

  @override
  String get composerDuration => 'Süre';

  @override
  String get composerReminder => 'Hatırlatıcı';

  @override
  String get composerAddTime => 'Saat ekle';

  @override
  String get composerRepeat => 'Tekrar';

  @override
  String get composerRepeatOnce => 'Bir kez';

  @override
  String get composerRepeatDaily => 'Günlük';

  @override
  String get composerRepeatWeekly => 'Haftalık';

  @override
  String get composerRepeatMonthly => 'Aylık';

  @override
  String get composerRepeatWeekdays => 'Hafta içi';

  @override
  String get composerRepeatYearly => 'Yıllık';

  @override
  String get composerRepeatStart => 'Başlangıç';

  @override
  String get composerSetEndDate => 'Bitiş tarihi ekle';

  @override
  String get composerRepeatForever => 'Süresiz tekrar eder.';

  @override
  String get composerRemove => 'Kaldır';

  @override
  String get composerReminderNone => 'Hatırlatma yok';

  @override
  String get composerReminderOnTime => 'Tam saatinde';

  @override
  String get composerSubtaskHint => 'Alt görev ekle';

  @override
  String get composerNotesHint => 'Not, bağlantı veya telefon numarası…';

  @override
  String get composerHoursUnit => 'sa';

  @override
  String get composerMinutesUnit => 'dk';

  @override
  String composerEveryDays(int count) {
    return '$count günde bir';
  }

  @override
  String composerEveryWeeks(int count) {
    return '$count haftada bir';
  }

  @override
  String composerEveryMonths(int count) {
    return '$count ayda bir';
  }

  @override
  String composerRepeatUntil(String date) {
    return '$date tarihine kadar';
  }

  @override
  String composerReminderBefore(int minutes) {
    return '$minutes dk önce';
  }

  @override
  String composerInDays(int days) {
    return '$days gün sonra';
  }

  @override
  String composerDaysAgo(int days) {
    return '$days gün önce';
  }

  @override
  String get plannedDayEmpty => 'Bu gün için plan yok';

  @override
  String get plannedDayView => 'Gün';

  @override
  String get plannedWeekView => 'Hafta';

  @override
  String get plannedMonthView => 'Ay';

  @override
  String get guestName => 'Misafir';

  @override
  String plannedSavedOn(String day) {
    return '$day gününe eklendi';
  }

  @override
  String get plannedDayShort => 'G';

  @override
  String get plannedWeekShort => 'H';

  @override
  String get plannedMonthShort => 'A';

  @override
  String get plannedShowWeek => 'Haftayı göster';

  @override
  String get plannedHideWeek => 'Haftayı gizle';

  @override
  String get plannedToday => 'Bugün';

  @override
  String get plannedMoreActions => 'Planlama işlemleri';

  @override
  String get plannedSmartPlan => 'Akıllı planla';

  @override
  String plannedSmartPlanConfirm(int count) {
    return 'Bu gündeki $count saatsiz görev en uygun boşluklara yerleştirilsin mi? Önemli ve yüksek öncelikli görevler önce planlanır.';
  }

  @override
  String get plannedApplyPlan => 'Planı uygula';

  @override
  String plannedSmartPlanDone(int count) {
    return '$count görev akıllı planlandı.';
  }

  @override
  String get plannedNothingToPlan =>
      'Bu günde planlanacak saatsiz görev veya yeterli boş zaman yok.';

  @override
  String get plannedImportCalendar => 'Takvim içe aktar (.ics)';

  @override
  String get plannedImport => 'İçe aktar';

  @override
  String plannedImportConfirm(int count) {
    return '$count takvim etkinliği görev olarak içe aktarılsın mı?';
  }

  @override
  String plannedImportDone(int count) {
    return '$count takvim etkinliği içe aktarıldı.';
  }

  @override
  String get plannedImportInvalid => 'Bir iCalendar (.ics) dosyası seç.';

  @override
  String get plannedImportEmpty => 'Bu takvimde geçerli etkinlik bulunamadı.';

  @override
  String get plannedImportFailed => 'Takvim içe aktarılamadı.';

  @override
  String get plannedNow => 'Şimdi';

  @override
  String get plannedTimeline => 'Zaman çizelgesi';

  @override
  String get plannedUnscheduled => 'Saati yok';

  @override
  String get plannedUnscheduledHint =>
      'Zaman çizelgesine sürükle ya da + ile saat ver.';

  @override
  String get plannedEmptyDayTitle => 'Bu gün boş';

  @override
  String get plannedEmptyDayBody => 'İlk bloğu ekle, güne şeklini ver.';

  @override
  String get plannedEmptyWeek => 'Bu hafta planlanmış bir şey yok';

  @override
  String plannedMinutesShort(int minutes) {
    return '$minutes dk';
  }

  @override
  String plannedHoursShort(int hours) {
    return '$hours sa';
  }

  @override
  String plannedRemaining(int minutes) {
    return '$minutes dk kaldı';
  }

  @override
  String plannedFreeMinutes(int minutes) {
    return '$minutes dk boş';
  }

  @override
  String plannedAddAt(String time) {
    return '$time için ekle';
  }

  @override
  String plannedScheduledAt(String time) {
    return '$time olarak planlandı';
  }

  @override
  String plannedProgressSummary(int done, int total) {
    return '$done/$total tamamlandı';
  }

  @override
  String get plannedPickMonth => 'Tarih seç';

  @override
  String get plannedPreviousWeek => 'Önceki hafta';

  @override
  String get plannedNextWeek => 'Sonraki hafta';

  @override
  String get dueLabel => 'Son tarih';

  @override
  String get repeat => 'Tekrar';

  @override
  String get repeats => 'Tekrarlanıyor';

  @override
  String get list => 'Liste';

  @override
  String get priority => 'Öncelik';

  @override
  String get low => 'Düşük öncelik';

  @override
  String get medium => 'Orta öncelik';

  @override
  String get high => 'Yüksek öncelik';

  @override
  String get createTask => 'Görev oluştur';

  @override
  String get save => 'Kaydet';

  @override
  String get saveChanges => 'Değişiklikleri kaydet';

  @override
  String get cancel => 'Vazgeç';

  @override
  String get delete => 'Sil';

  @override
  String get deleteTask => 'Görevi sil';

  @override
  String get deleteTaskConfirmTitle => 'Görev silinsin mi?';

  @override
  String deleteTaskConfirmBody(String title) {
    return '\"$title\" kalıcı olarak silinsin mi?';
  }

  @override
  String get addToMyDay => 'Günüme ekle';

  @override
  String get addedToMyDay => 'Günüme eklendi';

  @override
  String get removeFromDay => 'Günümden çıkar';

  @override
  String get complete => 'Tamamla';

  @override
  String get undo => 'Geri al';

  @override
  String get markImportant => 'Önemli olarak işaretle';

  @override
  String get removeImportance => 'Önem işaretini kaldır';

  @override
  String get starred => 'Önemli';

  @override
  String get createYourAccount => 'Hesabını oluştur';

  @override
  String get welcomeBack => 'Hoş geldin';

  @override
  String get loginTabTitle => 'Giriş yap';

  @override
  String get register => 'Kayıt ol';

  @override
  String get name => 'Ad';

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Şifre';

  @override
  String get createAccount => 'Hesap oluştur';

  @override
  String get signOut => 'Oturumu kapat';

  @override
  String get appearance => 'Görünüm';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get accentColor => 'Vurgu rengi';

  @override
  String get about => 'Hakkında';

  @override
  String get sync => 'Eşitleme';

  @override
  String get syncDescription => 'Bulut eşitlemesi açık';

  @override
  String get reportBug => 'Bug (Hata) bildir';

  @override
  String get reportBugTitle => 'Bir sorun mu buldun?';

  @override
  String get reportBugBody =>
      'Karşılaştığın sorunu yaz; estodo\'yu birlikte geliştirelim.';

  @override
  String get reportBugHint => 'Sorunu veya önerini yaz';

  @override
  String get sendFeedback => 'Gönder';

  @override
  String get feedbackThanksTitle => 'Geri bildiriminiz için teşekkür ederiz';

  @override
  String get feedbackThanksBody =>
      'Dönüşleriniz uygulamanın geliştirilmesine katkı sağlıyor.';

  @override
  String get feedbackEmpty => 'Lütfen sorunu veya önerini yaz.';

  @override
  String get feedbackError =>
      'Geri bildirim gönderilemedi. Lütfen tekrar dene.';

  @override
  String get comingSoon => 'Çok yakında…';

  @override
  String get futureFeaturesPrompt => 'Gelecek özellikler için tıklayınız';

  @override
  String get futureFeaturesTitle => 'Gelecek özellikler';

  @override
  String get suggest => 'Öner';

  @override
  String get aiTodoList => 'AI ile To Do list yapma';

  @override
  String get aiTodoListDescription =>
      'Gününü anlat; estodo görevlerini senin için hazırlasın.';

  @override
  String get featureSuggestionPrompt =>
      'Tıklayarak geliştirilmesinde geliştiriciye öneride bulunabilirsiniz';

  @override
  String get featureSuggestionTitle =>
      'estodo’yu geliştirmek için fikrin varsa öner butonuna tıklayabilirsin.';

  @override
  String get featureSuggestionHint => 'Nasıl çalışmasını isterdin?';

  @override
  String get featureSuggestionEmpty => 'Lütfen önerini yaz.';

  @override
  String get version => 'Sürüm';

  @override
  String get loading => 'Yükleniyor…';

  @override
  String get unavailable => 'Kullanılamıyor';

  @override
  String todaySubtitle(String date) {
    return '$date';
  }

  @override
  String get greetingMorning => 'Günaydın';

  @override
  String get greetingAfternoon => 'İyi günler';

  @override
  String get greetingEvening => 'İyi akşamlar';

  @override
  String get greetingNight => 'İyi geceler';

  @override
  String greetingFormat(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get suggestionsTitle => 'Öneriler';

  @override
  String suggestionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count öneri',
      one: '1 öneri',
    );
    return '$_temp0';
  }

  @override
  String get suggestionsHint =>
      'Bugüne planlamak isteyebileceğin geçmiş ve yaklaşan görevler.';

  @override
  String completedCount(int count) {
    return 'Tamamlandı  $count';
  }

  @override
  String get emptyMyDayTitle => 'Bugüne odaklan';

  @override
  String get emptyMyDayBody =>
      'Bugünün görevlerini buraya ekle; yarın otomatik sıfırlanır.';

  @override
  String get emptyImportantTitle => 'Önemli görev yok';

  @override
  String get emptyImportantBody =>
      'Önem verdiğin görevleri yıldızla; burada toplansınlar.';

  @override
  String get emptyPlannedTitle => 'Planlanmış bir şey yok';

  @override
  String get emptyPlannedBody => 'Bir göreve son tarih ekle, burada görünsün.';

  @override
  String get emptyTasksTitle => 'Gelen kutun temiz';

  @override
  String get emptyTasksBody => 'Başlamak için bir görev ekle.';

  @override
  String get emptyCompletedTitle => 'Henüz tamamlanan görev yok';

  @override
  String get emptyCompletedBody => 'Tamamladığın görevler burada toplanır.';

  @override
  String get emptyListTitle => 'Bu listede görev yok';

  @override
  String get emptyListBody => 'İlgili işleri bir arada tutmak için görev ekle.';

  @override
  String get emptySearchTitle => 'Her şeyde ara';

  @override
  String get emptySearchBody =>
      'Görevleri başlık, not veya liste adına göre bul.';

  @override
  String get noMatchesTitle => 'Eşleşme yok';

  @override
  String get noMatchesBody => 'Farklı bir başlık, not veya liste adı dene.';

  @override
  String get searchHint => 'Görev ve listelerde ara';

  @override
  String get offlineBanner =>
      'Çevrimdışısın. Değişiklikler bağlandığında eşitlenecek.';

  @override
  String get freqDaily => 'Her gün';

  @override
  String get freqWeekdays => 'Hafta içi';

  @override
  String get freqWeekly => 'Her hafta';

  @override
  String get freqMonthly => 'Her ay';

  @override
  String get freqYearly => 'Her yıl';

  @override
  String get sortBy => 'Sırala';

  @override
  String get sortManual => 'Kendi sıralamam';

  @override
  String get sortImportance => 'Önem';

  @override
  String get sortDueDate => 'Son tarih';

  @override
  String get sortAlphabetical => 'Alfabetik';

  @override
  String get sortCreationDate => 'Oluşturma tarihi';

  @override
  String get sortMyDay => 'Günüme eklendi';

  @override
  String get bucketEarlier => 'Geçmiş';

  @override
  String get bucketToday => 'Bugün';

  @override
  String get bucketTomorrow => 'Yarın';

  @override
  String get bucketThisWeek => 'Bu hafta';

  @override
  String get bucketLater => 'Daha sonra';

  @override
  String get today => 'Bugün';

  @override
  String get tomorrow => 'Yarın';

  @override
  String get yesterday => 'Dün';

  @override
  String selectedCount(int count) {
    return '$count seçili';
  }

  @override
  String get moveTo => 'Listeye taşı';

  @override
  String get clear => 'Temizle';

  @override
  String get close => 'Kapat';

  @override
  String get forgotPassword => 'Şifremi unuttum?';

  @override
  String get forgotPasswordTitle => 'Şifre sıfırla';

  @override
  String get forgotPasswordBody =>
      'E-postanı gir, sana sıfırlama bağlantısı gönderelim.';

  @override
  String get sendResetEmail => 'Sıfırlama e-postası gönder';

  @override
  String get passwordResetSent =>
      'Sıfırlama bağlantısı gönderildi. Gelen kutunu kontrol et.';

  @override
  String get deleteAccount => 'Hesabı sil';

  @override
  String get deleteAccountConfirmTitle => 'Hesap silinsin mi?';

  @override
  String get deleteAccountConfirmBody =>
      'Hesabın ve tüm görevlerin kalıcı olarak silinecek. Bu işlem geri alınamaz.';

  @override
  String get authErrorInvalidEmail => 'Geçerli bir e-posta adresi gir.';

  @override
  String get authErrorUserDisabled => 'Bu hesap devre dışı bırakılmış.';

  @override
  String get authErrorWrongPassword => 'E-posta veya şifre hatalı.';

  @override
  String get authErrorEmailInUse => 'Bu e-posta adresiyle zaten bir hesap var.';

  @override
  String get authErrorWeakPassword => 'Daha güçlü bir şifre kullan.';

  @override
  String get authErrorRecentLoginRequired =>
      'Hesabını silmeden önce çıkış yapıp tekrar giriş yap.';

  @override
  String get authErrorNetwork =>
      'Bağlantı kurulamadı. İnternet bağlantını kontrol edip tekrar dene.';

  @override
  String get authErrorTooManyRequests =>
      'Çok fazla deneme yapıldı. Biraz bekleyip tekrar dene.';

  @override
  String get authErrorGuestUnavailable =>
      'Misafir erişimi geçici olarak kullanılamıyor. Kısa süre sonra tekrar dene.';

  @override
  String get authErrorDefault => 'Kimlik doğrulama başarısız.';

  @override
  String get errorCouldNotLoadTasks => 'Görevler yüklenemedi';

  @override
  String get errorTryAgain => 'Bir şeyler ters gitti. Tekrar dene.';

  @override
  String streakDays(int count) {
    return '$count gün serisi';
  }

  @override
  String streakActive(int count) {
    return 'Seri devam ediyor: $count gün';
  }

  @override
  String get focusMode => 'Odak Modu';

  @override
  String get focusPomodoro => 'Pomodoro';

  @override
  String get focusShortBreak => 'Kısa Mola';

  @override
  String get focusLongBreak => 'Uzun Mola';

  @override
  String get focusCustom => 'Özel';

  @override
  String get focusTaskDuration => 'Görev Süresi';

  @override
  String get focusAdd5Min => '+5 dk';

  @override
  String get focusCompleteTask => 'Görevi Tamamla';

  @override
  String get focusSubtasks => 'Alt Görevler';

  @override
  String get focusSessionDone => 'Odaklanma seansı bitti! Harika iş çıkardın.';

  @override
  String get focusBreakDone => 'Mola bitti. Tekrar odaklanmaya hazır mısın?';

  @override
  String get focusStart => 'Başlat';

  @override
  String get focusPause => 'Duraklat';

  @override
  String get focusResume => 'Devam Et';

  @override
  String get focusReset => 'Sıfırla';

  @override
  String get oledBlack => 'OLED Saf Siyah';

  @override
  String get oledBlackDescription =>
      'OLED ekranlar ve pil tasarrufu için saf siyah (#000000) arka plan.';

  @override
  String get syncStatusSynced => 'Bulutla eşitlendi';

  @override
  String get syncStatusSyncing => 'Eşitleniyor...';

  @override
  String get syncStatusOffline => 'Çevrimdışı (cihazda kaydedildi)';

  @override
  String get syncNow => 'Şimdi eşitle';

  @override
  String syncStatusDetails(String time) {
    return 'Son eşitleme: $time. Tüm görevlerin ve listelerin bulutta güvende.';
  }

  @override
  String get syncStatusOfflineDetails =>
      'İnternet bağlantısı yok. Değişiklikler cihazında güvende, tekrar bağlandığında otomatik eşitlenecek.';

  @override
  String get tags => 'Etiketler';

  @override
  String get addTag => 'Etiket ekle';

  @override
  String get allTags => 'Tümü';

  @override
  String get filterByTag => 'Etikete göre filtrele';

  @override
  String get tagPlaceholder => 'Etiket adı';

  @override
  String get backupAndData => 'Yedekleme & Veri';

  @override
  String get exportData => 'Verileri Dışa Aktar (JSON)';

  @override
  String get importData => 'Yedekten İçe Aktar';

  @override
  String get backupCopied => 'Yedek panoya kopyalandı';

  @override
  String backupImportSuccess(int count) {
    return '$count görev başarıyla geri yüklendi';
  }

  @override
  String get backupInvalid => 'Geçersiz yedek JSON biçimi';

  @override
  String get importCalendarTitle => 'Takvim Etkinliklerini İçe Aktar';

  @override
  String get importCalendarSample => 'Bugüne Örnek Günlük Plan Ekle';

  @override
  String get importCalendarFile => '.ics Dosyası Yükle';

  @override
  String get importCalendarPaste => 'iCal (.ics) Metni Yapıştır';

  @override
  String calendarImportSuccess(int count) {
    return '$count etkinlik içe aktarıldı';
  }
}
