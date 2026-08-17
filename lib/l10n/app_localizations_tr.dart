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
}
