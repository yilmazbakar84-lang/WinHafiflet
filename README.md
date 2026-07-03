# WinHafiflet 

🛠️ WinHafiflet: Gelişmiş Windows Temizlik ve Kurulum SistemiWinHafiflet, Windows 10 ve Windows 11 işletim sistemlerini ilk kurulumdan sonra (Clean Install) veya günlük kullanımda en yüksek performans, gizlilik ve verimlilik seviyesine ulaştırmak için geliştirilmiş tam otomasyonlu bir sistem yapılandırma, hafifletme ve optimizasyon betiğidir (PowerShell Script).Gereksiz arka plan servislerinin, Microsoft'a veri gönderen telemetri araçlarının ve sisteme gömülü gelen (bloatware) üçüncü parti reklam uygulamalarının sistemi yormasını engellerken; bir geliştirici veya oyuncunun ihtiyacı olan temel yazılımları ve sistem kütüphanelerini tek tıkla entegre eder.

🎯 Neyi Hedefler?Maksimum Kaynak Tasarrufu: RAM ve CPU kullanımını doğrudan etkileyen gereksiz Windows servislerini ve arka plan işlemlerini kapatarak sistem gecikmesini (latency) düşürür.Gelişmiş Gizlilik (Privacy): İşletim sisteminin arka planda kullanıcı verilerini, arama alışkanlıklarını ve sistem günlüklerini Microsoft sunucularına raporlamasını (Telemetri) engeller.Sıfır Kurulum Kolaylığı (Unattended Setup): Bilgisayarı formatladıktan sonra saatlerce tarayıcı, kod editörü, arşiv yöneticisi ve sürücü kütüphanelerini (DirectX, Visual C++) arama derdini ortadan kaldırır; her şeyi arka planda, sessiz modda kendi kurur.Kişiselleştirilmiş Estetik: Tek bir wallpaper.png görseliyle hem masaüstünü hem de inatçı Windows kilit ekranı önbelleğini aynı anda senkronize ederek temiz bir masaüstü deneyimi sunar. 

✨ Öne Çıkan Özellikler

🔒 Gizlilik ve Performans: Telemetri servislerini, arkaplan veri toplamalarını ve Başlat menüsündeki Bing arama motorunu tamamen kapatır. 

🧹 Bloatware Temizliği: Candy Crush, TikTok, Disney+ gibi Windows ile gömülü gelen gereksiz üçüncü parti uygulamaları sistemden ve kullanıcı profillerinden arındırır.

🎨 Kişiselleştirme: Klasör içerisindeki wallpaper.png dosyasını hem masaüstü arka planı hem de kilit ekranı görseli olarak otomatik atar ve Windows kilit ekranı önbelleğini sıfırlayarak anında günceller. 

⚙️ Servis Optimizasyonu: Arka planda RAM ve CPU tüketen 29 adet kritik olmayan sistem servisini devre dışı bırakır.

📦 Otomatik Paket Yönetimi: Eğer sistemde yoksa WinGet aracını otomatik kurur; ardından tarayıcı, terminal araçları, oyun ve programlar için zorunlu olan runtime paketlerini (DirectX, Visual C++, .NET) sessiz modda yükler. 

                  ".config 
"Move the file to the user folder" (Dosyayı kullanıcı klasörüne taşıyın)

"Place the file inside the user folder" (Dosyayı kullanıcı klasörünün içine yerleştirin)



🗂️ Teknik Analiz ve Mimari DetaylarWinHafiflet mimarisi birbirini takip eden ve sistem kararlılığını bozmayacak şekilde optimize edilmiş 6 ana katmandan oluşur:Yönetici Yetki Katmanı (Privilege Check): Scriptin sistem kayıt defterine (Registry) ve System32 servislerine güvenle müdahale edebilmesi için WindowsPrincipal sınıfını kullanarak yönetici haklarını doğrular ve yetkisiz çalıştırmaları güvenli şekilde sonlandırır.  Sistem ve Arama Optimizasyonu (UI & Search Tweak): Başlat menüsünü yavaşlatan Bing web arama entegrasyonunu ve Cortana politikalarını lokal grup ilkeleri üzerinden kapatır. Windows 11'in yerleşik reklam panellerini ve uygulama öneri motorlarını devre dışı bırakır.  Gelişmiş Görsel Senkronizasyon (Wallpaper Core): Masaüstü arka planını işletim sistemini yeniden başlatmaya gerek kalmadan User32.dll API'si (SystemParametersInfo) üzerinden anında günceller. Kilit ekranındaki Windows Spotlight (Öne Çıkanlar) kilitlenmelerini aşmak için SystemProtectedUserData altındaki sistem önbellek yollarına doğrudan müdahale ederek görsel bütünlüğü sağlar.  Servis Filtreleme (Service Debloating): Sistemin açılış hızını ve disk optimizasyonunu artırmak amacıyla DiagTrack (Telemetri), SysMain (Superfetch), Hata Raporlama (WerSvc) ve kullanılmayan Xbox/Harita servisleri dahil 29 kritik olmayan servisi durdurur ve başlangıç türlerini devre dışı bırakır.  Gömülü Uygulama Arındırma (AppX Debloater): Windows ile hazır gelen ancak diskte ve RAM'de yer kaplayan sponsorlu uygulamaları (Candy Crush, TikTok, Disney+ vb.) iki aşamalı bir mimariyle temizler. Uygulamayı hem aktif kullanıcı profilinden kaldırır (Remove-AppxPackage) hem de sisteme yeni eklenecek kullanıcılar için imajdan tamamen arındırır (Remove-AppxProvisionedPackage).  Gelişmiş Paket ve Runtime Dağıtımı (WinGet Deployment): Sistemde modern paket yöneticisi WinGet'in varlığını sorgular; eksiklik durumunda Microsoft sunucularından VCLibs ve UI.Xaml altyapı paketlerini çekerek kurulumu tamamlar. Ardından geliştirici araçları (VS Code, Python), sistem araçları (Windows Terminal, Wintoys, NanaZip) ve sistemin oyun/program çalıştırma 
kararlılığını sağlayan tüm Visual C++ Tümleşik Paketlerini (Redist AIO), DirectX ve .NET Çalışma Zamanı kütüphanelerini sessiz ve parametrik olarak sisteme yükler. 

🚀 Nasıl Kullanılır?Bu repository'deki kodları bilgisayarınıza indirin (ZIP olarak indirebilir veya git clone yapabilirsiniz).Klasörün içerisine arka plan yapmak istediğiniz resmi atın ve adını wallpaper.png yapın.  Başlat menüsüne sağ tıklayarak Terminal (Yönetici) veya PowerShell (Yönetici) seçeneğini açın.  Scriptin bulunduğu klasörün dizinine geçiş yapın (Örn: cd C:\Users\Kullanici\Downloads\WinHafiflet).Aşağıdaki komutu yapıştırın ve Enter tuşuna basın:PowerShellSet-ExecutionPolicy Bypass -Scope Process -Force; .\ws.ps1

⚠️ Not: Tüm değişikliklerin sisteme tam olarak oturması ve servislerin durdurulması için işlem bittikten sonra bilgisayarınızı yeniden başlatmayı unutmayın!  
