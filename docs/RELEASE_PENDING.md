# Yayın sonrası yapılacaklar

`fix/sync-and-hardening` dalındaki değişikliklerden, uygulamanın yeni sürümü
yayınlandıktan **sonra** yapılması gereken adımlar ve ertelenen işler.

## Yapıldı

- [x] Firestore kuralları deploy edildi (6 Ekim 2026). Mevcut sürümle uyumlu:
  sadece kullanılmayan `feedback`, `mail` ve paylaşım yazma yetkileri kapandı,
  görev alanlarına boyut sınırı eklendi.

## Yayından sonra

### 1. Geri bildirim worker'ını deploy et

Yeni worker, isteklerde Firebase giriş token'ı (`Authorization: Bearer ...`)
istiyor. Token'ı gönderen ilk sürüm bu dalla gelen sürüm. Yayından önce deploy
edilirse eski sürümlerin geri bildirimleri `401` alır.

- [ ] Yeni sürüm mağazada yayınlandı.
- [ ] Kullanıcıların çoğu yeni sürüme geçti.
- [ ] Worker deploy edildi. Komut `cloudflare-worker` klasöründen çalışmalı;
  proje kökünden çalıştırılırsa Wrangler `functions/` klasörünü Cloudflare
  Pages projesi sanıp hata verir.

  ```bash
  cd cloudflare-worker
  npx wrangler deploy
  ```

- [ ] `RESEND_API_KEY` secret'ı tanımlı (daha önce eklendiyse gerekmez):
  `npx wrangler secret put RESEND_API_KEY`
- [ ] Deploy sonrası uygulamadan bir test geri bildirimi gönderilip e-postanın
  geldiği doğrulandı.

Not: `wrangler.toml` içindeki `[[ratelimits]]` bağlamaları hesapta
desteklenmezse deploy hata verir. O durumda bu bloklar kaldırılabilir; worker
bağlama yoksa sınırlamayı atlayacak şekilde yazıldı.

### 2. Yayın öncesi kontrol

- [ ] iOS build alındı ve cihazda denendi (bu dalda sadece Android debug build
  doğrulandı; Firebase native SDK'ları güncellendi).
- [ ] Liste silme, My Day devri ve liste oluşturma internetsizken denendi;
  bağlantı gelince sunucuya senkronize olduğu görüldü.
- [ ] Ayarlar > geri bildirim gönderme denendi.

## Ertelenen işler

- [ ] **Test kapsamı:** %56. Hedef %80. Açık kalanlar çoğunlukla UI ekranları ve
  `firebase_auth_repository.dart` (Firebase sahte paketleri gerekiyor).
- [ ] **Major paket güncellemeleri:** `equatable 3`, `file_picker 13`,
  `flutter_local_notifications 22`. API değişiklikleri var, cihazda test
  edilmeli.
- [ ] **Gereksiz klasörler:** `functions/` (sadece 70MB `node_modules`, kaynak
  yok) ve kökteki `node_modules` git'te değil. `functions/` silinirse Wrangler
  karışıklığı da biter.
- [ ] **Saat kayması:** Düzenlemeler artık düzenlenen sürümden her zaman yeni
  sayılıyor, ama çakışma çözümü hâlâ cihaz saatine dayanıyor. Kalıcı çözüm
  sunucu zaman damgası (`FieldValue.serverTimestamp()`) kullanmak.
- [ ] **Paylaşım:** Liste paylaşımı uygulanmamış; ilgili kod kaldırıldı.
  Eklenecekse kurallar ve veri modeli baştan tasarlanmalı.
