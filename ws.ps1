# Yönetici yetkisi kontrolü
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Lütfen bu scripti YÖNETÝCÝ OLARAK çalýþtýrýn!"
    Exit
}

Write-Host "=== Geliþmiþ Windows Temizlik, Özelleþtirme ve Kurulum Sistemi Baþlatýlýyor ===" -ForegroundColor Cyan

# ----------------------------------------------------
# 1. ADIM: TELEMETRÝ, REKLAM, GÖREV ÇUBUÐU VE SEARCH AYARLARI
# ----------------------------------------------------
Write-Host "`n[1/6] Telemetri, Saat Ayarlarý ve Geliþmiþ Arama Yapýlandýrýlýyor..." -ForegroundColor Yellow

# Görev Çubuðundaki Saatin Saniyeleri Göstermesini Saðlar
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSecondsInSystemClock" -Value 1 -ErrorAction SilentlyContinue

# Baþlat menüsündeki Bing aramalarýný, reklamlarý ve web sonuçlarýný tamamen kapatýr
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BindingInStart" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEnabled" -Value 0 -ErrorAction SilentlyContinue

# Cortana ve Web Arama Politikalarýný Devre Dýþý Býrakma
if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search")) {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows" -Name "Windows Search" -Force -ErrorAction SilentlyContinue
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "DisableWebSearch" -Value 1 -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "ConnectedSearchUseWeb" -Value 0 -ErrorAction SilentlyContinue

# ----------------------------------------------------
# 2. ADIM: KLASÖR ÝÇÝNDEKÝ YEREL DUVAR KAÐIDINI AYARLAMA
# ----------------------------------------------------
Write-Host "`n[2/6] Klasör Ýçindeki Yerel Duvar Kaðýdý ve Kilit Ekraný Ayarlanýyor..." -ForegroundColor Yellow

# Scriptin çalýþtýðý klasördeki "wallpaper.png" dosyasýný hedef alýyoruz
$WallpaperPath = Join-Path -Path $PSScriptRoot -ChildPath "wallpaper.png"

if (Test-Path $WallpaperPath) {
    # Masaüstü Arka Planýný Ayarla (C# User32 API çaðrýsý yardýmýyla anýnda yeniler)
    $code = @'
    using System.Runtime.InteropServices;
    public class Wallpaper {
        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    }
'@
    Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue
    [Wallpaper]::SystemParametersInfo(0x0014, 0, $WallpaperPath, 0x01 -bor 0x02) | Out-Null
    Write-Host "Masaüstü duvar kaðýdý klasördeki resimle baþarýyla deðiþtirildi." -ForegroundColor Green

    # Kilit Ekraný Arka Planýný Ayarla (Sistem Genelinde Politika Olarak)
    if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows" -Name "Personalization" -Force -ErrorAction SilentlyContinue
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name "LockScreenImage" -Value $WallpaperPath -ErrorAction SilentlyContinue
    
    # Dinamik kilit ekraný içeriklerini kapat, sabit görsele zorla
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "RotatingLockScreenEnabled" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WallPaper" -Value $WallpaperPath -ErrorAction SilentlyContinue
    Write-Host "Kilit ekraný görseli klasördeki resimle baþarýyla deðiþtirildi." -ForegroundColor Green
} else {
    Write-Warning "Klasör içinde 'wallpaper.png' adýnda bir resim bulunamadý! Bu adým atlanýyor."
    Write-Warning "Lütfen kullanmak istediðiniz resmi script ile ayný klasöre koyup adýný 'wallpaper.png' yapýn."
}

# ----------------------------------------------------
# 3. ADIM: BELÝRTÝLEN TÜM SERVÝSLERÝ DEVRE DIÞI BIRAKMA
# ----------------------------------------------------
Write-Host "`n[3/6] Ýstenen Tüm Kritik Servisler DEVRE DIÞI Býrakýlýyor..." -ForegroundColor Yellow

$DisabledServices = @(
    "DiagTrack", "dmwappushservice", "WSearch", "SysMain", "lfsvc", "CscService", 
    "PcaSvc", "shpcsvc", "DiagLog", "wdiSystemHost", "wdiServiceHost", "PhoneSvc", 
    "PimIndexMaintenanceSvc", "RemoteRegistry", "wisvc", "WbioSrvc", "NetTcpPortSharing", 
    "Wecsvc", "RasAuto", "RasMan", "XblAuthManager", "XblGameSave", "XboxNetApiSvc", 
    "MapsBroker", "WerSvc", "wercplsupport", "SensorService", "SensorDataService", "SensrSvc"
)

foreach ($Service in $DisabledServices) {
    if (Get-Service -Name $Service -ErrorAction SilentlyContinue) {
        Stop-Service -Name $Service -Force -ErrorAction SilentlyContinue
        Set-Service -Name $Service -StartupType Disabled
        Write-Host "DEVRE DIÞI YAPILDI: $Service" -ForegroundColor Red
    }
}

# ----------------------------------------------------
# 4. ADIM: GENÝÞLETÝLMÝÞ BLOATWARE TEMÝZLÝÐÝ
# ----------------------------------------------------
Write-Host "`n[4/6] Listelenen Bloatware ve Maðaza Uygulamalarý Siliniyor..." -ForegroundColor Yellow

$BloatwareList = @(
    "*Microsoft.3DBuilder*", "*Microsoft.549981C3F5F10*", "*Microsoft.Asphalt8Airborne*",
    "*Microsoft.BingFinance*", "*Microsoft.BingFoodAndDrink*", "*Microsoft.BingHealthAndFitness*",
    "*Microsoft.BingNews*", "*Microsoft.BingSports*", "*Microsoft.BingTranslator*",
    "*Microsoft.BingTravel*", "*Microsoft.BingWeather*", "*Microsoft.GetHelp*",
    "*Microsoft.Messaging*", "*Microsoft.Microsoft3DViewer*", "*Microsoft.MicrosoftOfficeHub*",
    "*Microsoft.MicrosoftSolitaireCollection*", "*Microsoft.MicrosoftStickyNotes*",
    "*Microsoft.MixedReality.Portal*", "*Microsoft.NetworkSpeedTest*", "*Microsoft.News*",
    "*Microsoft.Office.OneNote*", "*Microsoft.Office.Sway*", "*Microsoft.OneConnect*",
    "*Microsoft.Print3D*", "*Microsoft.SkypeApp*", "*Microsoft.Todos*",
    "*Microsoft.WindowsAlarms*", "*Microsoft.WindowsFeedbackHub*", "*Microsoft.WindowsMaps*",
    "*Microsoft.WindowsSoundRecorder*", "*Microsoft.ZuneVideo*", "*ACGMediaPlayer*",
    "*ActiproSoftwareLLC*", "*AdobeSystemsIncorporated.AdobePhotoshopExpress*",
    "*Amazon.com.Amazon*", "*Asphalt8Airborne*", "*AutodeskSketchBook*",
    "*CaesarsSlotsFreeCasino*", "*Clipchamp.Clipchamp*", "*COOKINGFEVER*",
    "*CyberLinkMediaSuiteEssentials*", "*DisneyMagicKingdoms*", "*Dolby*",
    "*DrawboardPDF*", "*Duolingo-LearnLanguagesforFree*", "*EclipseManager*",
    "*Facebook*", "*FarmVille2CountryEscape*", "*fitbit*", "*Flipboard*",
    "*HiddenCity*", "*HULULLC.HULUPLUS*", "*iHeartRadio*", "*king.com.BubbleWitch3Saga*",
    "*king.com.CandyCrushSaga*", "*king.com.CandyCrushSodaSaga*", "*LinkedInforWindows*",
    "*MarchofEmpires*", "*Netflix*", "*NYTCrossword*", "*OneCalendar*",
    "*PandoraMediaInc*", "*PhototasticCollage*", "*PicsArt-PhotoStudio*",
    "*Plex*", "*PolarrPhotoEditorAcademicEdition*", "*Royal Revolt*",
    "*Shazam*", "*Sidia.LiveWallpaper*", "*SlingTV*", "*Speed Test*",
    "*TuneInRadio*", "*Twitter*", "*Viber*", "*WinZipUniversal*",
    "*Wunderlist*", "*XING*", "*tiktok*"
)

foreach ($App in $BloatwareList) {
    Get-AppxPackage -Name $App -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online | Where-Object {$_.PackageName -like $App} | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}
Write-Host "Bloatware listesindeki tüm uygulamalar temizlendi." -ForegroundColor Green

# ----------------------------------------------------
# 5. ADIM: WINGET VAR MI KONTROL ET VE BAÞLAT
# ----------------------------------------------------
Write-Host "`n[5/6] WinGet Varlýk Kontrolü Yapýlýyor..." -ForegroundColor Yellow

$WingetCheck = Get-Command winget -ErrorAction SilentlyContinue

if (-not $WingetCheck) {
    Write-Warning "WinGet sistemde bulunamadý! Microsoft App Installer indirilip kuruluyor..."
    
    $dir = "$env:TEMP\winget-init"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    
    $vclibs = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
    $xaml = "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx"
    $wingetpkg = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    
    # Ýndirme iþlemlerinde TLS 1.2 protokol saðlamasý
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $vclibs -OutFile "$dir\vclibs.appx" -ErrorAction SilentlyContinue
    Invoke-WebRequest -Uri $xaml -OutFile "$dir\xaml.appx" -ErrorAction SilentlyContinue
    Invoke-WebRequest -Uri $wingetpkg -OutFile "$dir\winget.msixbundle" -ErrorAction SilentlyContinue
    
    Add-AppxPackage -Path "$dir\vclibs.appx" -ErrorAction SilentlyContinue
    Add-AppxPackage -Path "$dir\xaml.appx" -ErrorAction SilentlyContinue
    Add-AppxPackage -Path "$dir\winget.msixbundle" -ErrorAction SilentlyContinue
    
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}
Write-Host "WinGet kontrolü baþarýyla tamamlandý." -ForegroundColor Green

# ----------------------------------------------------
# 6. ADIM: OTOMATÝK UYGULAMA VE RUNTIME YÜKLEME (WINGET)
# ----------------------------------------------------
Write-Host "`n[6/6] Ýstediðin Uygulamalar, Windows Terminal ve Çalýþma Zamaný Paketleri Yükleniyor..." -ForegroundColor Yellow

$apps = @(
    "Microsoft.WindowsTerminal", "Fastfetch-Cli.Fastfetch", "Starship.Starship", "CharlesMilette.TranslucentTB", 
    "Helium.Helium", "Brave.Brave", "Discord.Discord", "Microsoft.VisualStudioCode", 
    "Python.Python.3.12", "VideoLAN.VLC", "Mojang.MinecraftLauncher", "M2Team.NanaZip", "VitorMendes.Wintoys",
    "Microsoft.DirectX", "Abbodi1406.vcredist-aio", "Microsoft.XNAFramework", "Microsoft.DotNet.DesktopRuntime.8"
)

foreach ($app in $apps) {
    Write-Host "Attempting to install: $app" -ForegroundColor Yellow
    winget install --id $app --silent --accept-package-agreements --accept-source-agreements --upgrade
}

Write-Host "`n=== Tüm Ýþlemler Baþarýyla Tamamlandý! ===" -ForegroundColor Green
Write-Host "Sistemin tamamen hafiflemesi ve deðiþikliklerin tam oturmasý için bilgisayarý YENÝDEN BAÞLATMAYI unutma!" -ForegroundColor Cyan