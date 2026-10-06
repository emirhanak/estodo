# Kullanıcı gözünden test — 6 Ekim 2026

Android emülatörde (Pixel 7, misafir hesap) Planlanmış, Görevler, menü ve
görev oluşturma akışları denendi.

## Beğenilecekler

- Doğal dil ile görev ekleme çok iyi: "Kosu 1 saat yarin 08:00" yazınca tarih,
  saat ve süre doğru ayrıştırıldı ve öneri kartı gösterildi.
- Composer'ın 2. adımı net: tarih, hatırlatıcı, saat çarkı, süre çipleri,
  tekrar/önemli tek ekranda.
- Planlanmış zaman çizelgesi (kapsüller, "60 dk boş" aralıkları) Structured
  hissini veriyor; üst satır artık ferah, hafta şeridi gerektiğinde açılıyor.
- Görevler listesi sade ve Microsoft To Do'ya tanıdık.
- Menüde senkron durumu ("Bulutla eşitlendi") güven veriyor.

## Beğenilmeyecekler

| # | Sorun | Durum |
|---|---|---|
| 1 | Başka güne görev eklenince ekran bugünde kalıyor, geri bildirim yok; görev kayboldu sanılıyor. | Yapılacak: composer kaydedince o güne geç + "7 Eki'ye eklendi" bildirimi. |
| 2 | Bugün için saat geçmiş olsa da "07:00 için ekle" öneriliyor. | **Düzeltildi:** bugün için öneri şimdiki saatten sonraki ilk çeyreğe kayıyor. |
| 3 | Başka güne geçince "Bugün" butonu başlığı "7 Eki..." diye kesiyor. | **Düzeltildi:** telefonda "Bugün" artık ikon buton. |
| 4 | Özet cümlesi akıcı değil: "1 görevin 0 tanesi tamam". | Yapılacak: "0/1 tamamlandı". |
| 5 | Görevler listesinde saatli görev sadece "Yarın" gösteriyor, saat yok. | Yapılacak: "Yarın 08:00". |
| 6 | Türkçe arayüzde "İyi günler, Guest" ve menüde "Guest". | Yapılacak: "Misafir" olarak yerelleştir. |
| 7 | Menüde ikonlar solda ama yazılar ortalanmış; dağınık görünüyor. | Yapılacak: yazıları sola hizala. |
| 8 | "Kosu" için su damlası ikonu seçildi; ikon tahmini Türkçe karaktersiz kelimelerde zayıf. | Yapılacak: ikon eşleştirmede ş/s, ı/i gibi harfleri normalize et. |
| 9 | Hatırlatıcı varsayılan "yok"; saatli plan için 10 dk önce varsayılan daha faydalı olabilir. | Değerlendirilecek. |
