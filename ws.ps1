# Yonetici yetkisi kontrolu

$Banner = @"

 __        __ _       _   _       __ _      _      _
 \ \      / /(_)_ __  | | | | __ / _(_) ___ | | ___| |_
  \ \ /\ / / | | '_ \ | |_| |/ _|| |_| |/ _ \| |/ _ \ __|
   \ V  V /  | | | | ||  _  | (_)|  _| |  __/| |  __/ |_
    \_/\_/   |_|_| |_||_| |_|\__||_| |_|\___||_|\___|\__|

           WinHafiflet - Windows Temizlik & Kurulum Araci
           https://github.com/yilmazbakar84-lang/WinHafiflet
"@

Write-Host $Banner -ForegroundColor Magenta

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Lutfen bu scripti YONETICI OLARAK calistirin!"
    Exit
}

Write-Host "=== Gelismis Windows Temizlik, Ozellestirme ve Kurulum Sistemi Baslatiliyor ===" -ForegroundColor Cyan

# ----------------------------------------------------
# 1. ADIM: TELEMETRI, REKLAM, GOREV CUBUGU VE SEARCH AYARLARI
# ----------------------------------------------------
Write-Host "`n[1/16] Telemetri, Saat Ayarlari ve Gelismis Arama Yapilandiriliyor..." -ForegroundColor Yellow

Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSecondsInSystemClock" -Value 1 -ErrorAction SilentlyContinue

Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BindingInStart" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEnabled" -Value 0 -ErrorAction SilentlyContinue

if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search")) {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows" -Name "Windows Search" -Force -ErrorAction SilentlyContinue | Out-Null
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "DisableWebSearch" -Value 1 -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "ConnectedSearchUseWeb" -Value 0 -ErrorAction SilentlyContinue

# ----------------------------------------------------
# 2. ADIM: KLASOR ICINDEKI YEREL DUVAR KAGIDINI AYARLAMA
# ----------------------------------------------------
Write-Host "`n[2/16] Klasor Icindeki Yerel Duvar Kagidi ve Kilit Ekrani Ayarlaniyor..." -ForegroundColor Yellow

# FIX: $PSScriptRoot, script "iex" ile (dosyaya kaydedilmeden) calistirilirsa bos kalir.
# Bu durumda script klasorunu mevcut calisma dizinine dusuruyoruz ki hata vermesin.
$ScriptFolder = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$WallpaperPath = Join-Path -Path $ScriptFolder -ChildPath "wallpaper.png"

if (Test-Path $WallpaperPath) {
    $code = @'
    using System.Runtime.InteropServices;
    public class Wallpaper {
        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    }
'@
    # FIX: Add-Type ayni oturumda ikinci kez cagrilirsa "type already exists" hatasi verir.
    # Tip zaten tanimliysa yeniden tanimlamayi atliyoruz.
    if (-not ("Wallpaper" -as [type])) {
        Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue
    }
    [Wallpaper]::SystemParametersInfo(0x0014, 0, $WallpaperPath, 0x01 -bor 0x02) | Out-Null
    Write-Host "Masaustu duvar kagidi klasordeki resimle basariyla degistirildi." -ForegroundColor Green

    if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows" -Name "Personalization" -Force -ErrorAction SilentlyContinue | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name "LockScreenImage" -Value $WallpaperPath -ErrorAction SilentlyContinue

    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "RotatingLockScreenEnabled" -Value 0 -ErrorAction SilentlyContinue
    # NOT: Bu satir aslinda masaustu duvar kagidi anahtarini tekrar yaziyor (kilit ekranini etkilemez),
    # orijinal script'te de oyleydi; zararsiz ama yaniltici oldugu icin burada birakildi, dokunulmadi.
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WallPaper" -Value $WallpaperPath -ErrorAction SilentlyContinue
    Write-Host "Kilit ekrani politikasi klasordeki resimle ayarlandi (Local Group Policy ile uygulanmazsa gpupdate /force gerekebilir)." -ForegroundColor Green
} else {
    Write-Warning "Klasor icinde 'wallpaper.png' adinda bir resim bulunamadi! Bu adim atlaniyor."
    Write-Warning "Lutfen kullanmak istediginiz resmi script ile ayni klasore koyup adini 'wallpaper.png' yapin."
}

# ----------------------------------------------------
# 3. ADIM: BELIRTILEN TUM SERVISLERI DEVRE DISI BIRAKMA
# ----------------------------------------------------
Write-Host "`n[3/16] Istenen Tum Kritik Servisler DEVRE DISI Birakiliyor..." -ForegroundColor Yellow

$DisabledServices = @(
    "DiagTrack", "dmwappushservice", "WSearch", "SysMain", "lfsvc", "CscService",
    "PcaSvc", "DiagLog", "wdiSystemHost", "wdiServiceHost", "PhoneSvc",
    "PimIndexMaintenanceSvc", "RemoteRegistry", "wisvc", "WbioSrvc", "NetTcpPortSharing",
    "Wecsvc", "RasAuto", "RasMan", "XblAuthManager", "XblGameSave", "XboxNetApiSvc",
    "MapsBroker", "WerSvc", "wercplsupport", "SensorService", "SensorDataService", "SensrSvc"
)
# NOT: Orijinal listede yer alan "shpcsvc" gecerli bir Windows servis adi degil (muhtemelen
# "ShellHWDetection" kastedilmisti), bu yuzden listeden cikarildi.

foreach ($Service in $DisabledServices) {
    if (Get-Service -Name $Service -ErrorAction SilentlyContinue) {
        Stop-Service -Name $Service -Force -ErrorAction SilentlyContinue
        # FIX: Bazi servisler korumali oldugu icin Set-Service yine de hata firlatabilir,
        # -ErrorAction SilentlyContinue eklendi.
        Set-Service -Name $Service -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "DEVRE DISI YAPILDI: $Service" -ForegroundColor Red
    }
}

# ----------------------------------------------------
# 4. ADIM: GENISLETILMIS BLOATWARE TEMIZLIGI
# ----------------------------------------------------
Write-Host "`n[4/16] Listelenen Bloatware ve Magaza Uygulamalari Siliniyor..." -ForegroundColor Yellow

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
    Get-AppxPackage -Name $App -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.PackageName -like $App } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}
Write-Host "Bloatware listesindeki tum uygulamalar temizlendi." -ForegroundColor Green

# ----------------------------------------------------
# 5. ADIM: WINGET VAR MI KONTROL ET VE BASLAT
# ----------------------------------------------------
Write-Host "`n[5/16] WinGet Varlik Kontrolu Yapiliyor..." -ForegroundColor Yellow

$WingetCheck = Get-Command winget -ErrorAction SilentlyContinue

if (-not $WingetCheck) {
    Write-Warning "WinGet sistemde bulunamadi! Microsoft App Installer indirilip kuruluyor..."

    $dir = "$env:TEMP\winget-init"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null

    $vclibs = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
    $xaml = "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx"
    $wingetpkg = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $vclibs -OutFile "$dir\vclibs.appx" -ErrorAction SilentlyContinue
    Invoke-WebRequest -Uri $xaml -OutFile "$dir\xaml.appx" -ErrorAction SilentlyContinue
    Invoke-WebRequest -Uri $wingetpkg -OutFile "$dir\winget.msixbundle" -ErrorAction SilentlyContinue

    Add-AppxPackage -Path "$dir\vclibs.appx" -ErrorAction SilentlyContinue
    Add-AppxPackage -Path "$dir\xaml.appx" -ErrorAction SilentlyContinue
    Add-AppxPackage -Path "$dir\winget.msixbundle" -ErrorAction SilentlyContinue

    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

    # FIX: winget'i az once kurduktan sonra Get-Command genelde PATH guncellenmeden onu goremez.
    $WingetCheck = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $WingetCheck) {
        Write-Warning "WinGet kuruldu ama bu oturumda hemen algilanamadi. 6. adim atlanabilir; gerekirse PowerShell'i yeniden acip scripti tekrar calistirin."
    }
}
Write-Host "WinGet kontrolu tamamlandi." -ForegroundColor Green

# ----------------------------------------------------
# 6. ADIM: OTOMATIK UYGULAMA VE RUNTIME YUKLEME (WINGET)
# ----------------------------------------------------
Write-Host "`n[6/16] Istedigin Uygulamalar, Windows Terminal ve Calisma Zamani Paketleri Yukleniyor..." -ForegroundColor Yellow

if (Get-Command winget -ErrorAction SilentlyContinue) {
    $apps = @(
        "Microsoft.WindowsTerminal", "Fastfetch-Cli.Fastfetch", "Starship.Starship", "CharlesMilette.TranslucentTB",
        "ImputNet.Helium", "Brave.Brave", "Discord.Discord", "Microsoft.VisualStudioCode",
        "Python.Python.3.12", "VideoLAN.VLC", "Mojang.MinecraftLauncher", "M2Team.NanaZip",
        "Microsoft.DirectX", "abbodi1406.vcredist", "Microsoft.XNARedist", "Microsoft.DotNet.DesktopRuntime.8",
        "th-ch.YouTubeMusic", "9P8LTPGCBZXD", "Anthropic.Claude"
        "WhatsApp.WhatsApp", "Suwayomi.Suwayomi-Server", "Notepad++.Notepad++", "AltSnap.AltSnap"
    )

    foreach ($app in $apps) {
        Write-Host "Kurulmaya calisiliyor: $app" -ForegroundColor Yellow
        if ($app -eq "9P8LTPGCBZXD") {
            winget install --id $app -e --source msstore --silent --accept-package-agreements --accept-source-agreements
        } else {
            winget install --id $app -e --silent --accept-package-agreements --accept-source-agreements
        }
    }
} else {
    Write-Warning "WinGet bulunamadigi icin 6. adim (uygulama kurulumu) atlandi."
}

# ----------------------------------------------------
# 7. ADIM: WINDOWS DEFENDER'I DEVRE DISI BIRAKMA (BEST-EFFORT)
# ----------------------------------------------------
Write-Host "`n[7/16] Windows Defender Devre Disi Birakilmaya Calisiliyor..." -ForegroundColor Yellow
Write-Host "NOT: Defender'i tamamen 'silmek' mumkun degil, sadece devre disi birakilabilir." -ForegroundColor DarkYellow
Write-Host "Tamper Protection (Kurcalamaya Karsi Koruma) aciksa bu adim hicbir ise yaramaz." -ForegroundColor DarkYellow

try {
    $tamperState = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features" -Name "TamperProtection" -ErrorAction SilentlyContinue

    if ($tamperState -and $tamperState.TamperProtection -eq 5) {
        Write-Warning "Tamper Protection ACIK gorunuyor. Windows Ayarlari > Gizlilik ve Guvenlik > Windows Guvenligi > Virus ve Tehdit Korumasi > Ayarlari Yonet kismindan elle kapatman gerekiyor. Bu adim atlaniyor."
    } else {
        if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender")) {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft" -Name "Windows Defender" -Force -ErrorAction Stop | Out-Null
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 1 -Type DWord -ErrorAction Stop
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiVirus" -Value 1 -Type DWord -ErrorAction Stop

        Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction Stop
        Set-MpPreference -DisableIOAVProtection $true -ErrorAction Stop
        Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction Stop

        Stop-Service -Name WinDefend -Force -ErrorAction SilentlyContinue
        Set-Service -Name WinDefend -StartupType Disabled -ErrorAction SilentlyContinue

        Write-Host "Windows Defender devre disi birakildi (yeniden baslatma sonrasi Windows tekrar acabilir)." -ForegroundColor Green
    }
} catch {
    Write-Warning "Defender devre disi birakilamadi, muhtemelen Tamper Protection acik ya da sistem tarafindan engellendi. Bu adim atlanip devam ediliyor."
}

# ----------------------------------------------------
# 8. ADIM: MICROSOFT EDGE'I KALDIRMA (BEST-EFFORT)
# ----------------------------------------------------
Write-Host "`n[8/16] Microsoft Edge Kaldirilmaya Calisiliyor..." -ForegroundColor Yellow
Write-Host "NOT: Edge kaldirma resmi olarak desteklenmez, Windows Update onu geri yukleyebilir." -ForegroundColor DarkYellow

try {
    $edgeBase = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application"
    if (-not (Test-Path $edgeBase)) {
        $edgeBase = "$env:ProgramFiles\Microsoft\Edge\Application"
    }

    if (Test-Path $edgeBase) {
        $edgeVersionFolder = Get-ChildItem -Path $edgeBase -Directory -ErrorAction Stop |
            Where-Object { $_.Name -match '^\d+\.\d+\.\d+\.\d+$' } |
            Sort-Object { [version]$_.Name } -Descending |
            Select-Object -First 1

        if ($edgeVersionFolder) {
            $setupPath = Join-Path $edgeVersionFolder.FullName "Installer\setup.exe"
            if (Test-Path $setupPath) {
                Start-Process -FilePath $setupPath -ArgumentList "--uninstall --system-level --verbose-logging --force-uninstall" -Wait -ErrorAction Stop
                Write-Host "Microsoft Edge kaldirma komutu calistirildi." -ForegroundColor Green
            } else {
                throw "setup.exe bulunamadi: $setupPath"
            }
        } else {
            throw "Edge surum klasoru bulunamadi."
        }
    } else {
        throw "Edge kurulum klasoru bulunamadi: $edgeBase"
    }
} catch {
    Write-Warning "Microsoft Edge kaldirilamadi ($($_.Exception.Message)). Bu adim atlanip devam ediliyor."
}

# ----------------------------------------------------
# 9. ADIM: EK GIZLILIK VE TELEMETRI AYARLARI
# ----------------------------------------------------
Write-Host "`n[9/16] Ek Gizlilik, Konum ve Tanilama Ayarlari Uygulaniyor..." -ForegroundColor Yellow

function Set-RegValue {
    param($Path, $Name, $Value, $Type = "DWord")
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null
    }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -ErrorAction SilentlyContinue
}

# Etkinlik Gecmisi (Activity Feed / Timeline)
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableActivityFeed" 0
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" 0
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "UploadUserActivities" 0

# Tuketici ozellikleri ve gorev cubugu "End Task"
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" 1
Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" "TaskbarEndTask" 1

# Konum, sensor ve harita otomatik guncelleme izinleri
Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" "Value" "Deny" "String"
Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" "SensorPermissionState" 0
Set-RegValue "HKLM:\SYSTEM\Maps" "AutoUpdateEnabled" 0

# Reklam kimligi, kisisellestirilmis deneyimler ve el yazisi/konusma toplama
Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0
Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" "TailoredExperiencesWithDiagnosticDataEnabled" 0
Set-RegValue "HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy" "HasAccepted" 0
Set-RegValue "HKCU:\Software\Microsoft\Input\TIPC" "Enabled" 0
Set-RegValue "HKCU:\Software\Microsoft\InputPersonalization" "RestrictImplicitInkCollection" 1
Set-RegValue "HKCU:\Software\Microsoft\InputPersonalization" "RestrictImplicitTextCollection" 1
Set-RegValue "HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore" "HarvestContacts" 0
Set-RegValue "HKCU:\Software\Microsoft\Personalization\Settings" "AcceptedPrivacyPolicy" 0

# Telemetri seviyesi ve program izleme / SIUF anketleri
Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" 0
Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackProgs" 0
Set-RegValue "HKCU:\Software\Microsoft\Siuf\Rules" "NumberOfSIUFInPeriod" 0

Write-Host "Ek gizlilik ve telemetri ayarlari uygulandi." -ForegroundColor Green

# ----------------------------------------------------
# 10. ADIM: BITLOCKER'I DEVRE DISI BIRAKMA (BEST-EFFORT)
# ----------------------------------------------------
Write-Host "`n[10/16] BitLocker Sur/Kapa Devre Disi Birakiliyor..." -ForegroundColor Yellow

try {
    $bitlockerVolume = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction Stop
    if ($bitlockerVolume.ProtectionStatus -eq "On") {
        Disable-BitLocker -MountPoint $env:SystemDrive -ErrorAction Stop
        Write-Host "BitLocker $($env:SystemDrive) icin devre disi birakildi (sifre cozme islemi arka planda devam edebilir)." -ForegroundColor Green
    } else {
        Write-Host "BitLocker zaten kapali gorunuyor, islem yapilmadi." -ForegroundColor Green
    }
} catch {
    Write-Warning "BitLocker durumu okunamadi veya devre disi birakilamadi (modul bulunmuyor olabilir). Bu adim atlanip devam ediliyor."
}
Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker" "PreventDeviceEncryption" 1

# ----------------------------------------------------
# 11. ADIM: WINDOWS AI / COPILOT VE NOTEPAD AI OZELLIKLERINI KAPATMA
# ----------------------------------------------------
Write-Host "`n[11/16] Windows AI Bilesenleri (Copilot vb.) ve Notepad AI Ozellikleri Kapatiliyor..." -ForegroundColor Yellow

Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" "SettingsPageVisibility" "hide:aicomponents" "String"
Set-RegValue "HKLM:\SOFTWARE\Policies\WindowsNotepad" "DisableAIFeatures" 1
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1

try {
    Get-AppxPackage -Name "*Microsoft.Windows.Ai.Copilot*" -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
} catch {
    Write-Warning "Copilot uygulama paketi kaldirilamadi, bu adim atlaniyor."
}
Write-Host "Windows AI / Copilot ayarlari uygulandi." -ForegroundColor Green

# ----------------------------------------------------
# 12. ADIM: EK BLOATWARE VE UYGULAMA KALDIRMA (Xbox, Teams, Paint vb.)
# ----------------------------------------------------
Write-Host "`n[12/16] Ek Sistem Uygulamalari (Xbox, Teams, Feedback Hub vb.) Kaldiriliyor..." -ForegroundColor Yellow

$ExtraAppxList = @(
    "Microsoft.WindowsFeedbackHub", "Microsoft.BingNews", "Microsoft.BingSearch", "Microsoft.BingWeather",
    "Clipchamp.Clipchamp", "Microsoft.Todos", "Microsoft.PowerAutomateDesktop",
    "Microsoft.MicrosoftSolitaireCollection", "Microsoft.WindowsSoundRecorder", "Microsoft.MicrosoftStickyNotes",
    "Microsoft.Windows.DevHome", "Microsoft.OutlookForWindows", "Microsoft.WindowsAlarms",
    "Microsoft.StartExperiencesApp", "Microsoft.GetHelp", "Microsoft.ZuneMusic",
    "MicrosoftCorporationII.QuickAssist", "MSTeams",
    "Microsoft.XboxIdentityProvider", "Microsoft.XboxSpeechToTextOverlay", "Microsoft.GamingApp",
    "Microsoft.Xbox.TCUI", "Microsoft.XboxGamingOverlay"
)

foreach ($App in $ExtraAppxList) {
    Write-Host "Kaldiriliyor: $App" -ForegroundColor Red
    Get-AppxPackage -Name $App -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.PackageName -like "*$App*" } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}
Write-Host "Ek uygulama temizligi tamamlandi." -ForegroundColor Green

# ----------------------------------------------------
# 13. ADIM: ARAYUZ VE GORUNUM INCE AYARLARI (Performans / Sadelik)
# ----------------------------------------------------
Write-Host "`n[13/16] Gorsel Efektler, Gorev Cubugu ve 'Bu Bilgisayar' Klasorleri Duzenleniyor..." -ForegroundColor Yellow

Set-RegValue "HKCU:\Control Panel\Desktop" "DragFullWindows" 0 "String"
Set-RegValue "HKCU:\Control Panel\Desktop" "MenuShowDelay" 200 "String"
Set-RegValue "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" 0 "String"
Set-RegValue "HKCU:\Control Panel\Keyboard" "KeyboardDelay" 0
Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ListviewAlphaSelect" 0
Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ListviewShadow" 0
Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations" 0
Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 3
Set-RegValue "HKCU:\Software\Microsoft\Windows\DWM" "EnableAeroPeek" 0

Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarMn" 0
Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowTaskViewButton" 0
Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "SearchboxTaskbarMode" 0

Set-RegValue "HKCU:\Software\Classes\CLSID\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}" "System.IsPinnedToNameSpaceTree" 0
Set-RegValue "HKCU:\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}" "System.IsPinnedToNameSpaceTree" 0
Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "LaunchTo" 1

Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" 0

Write-Host "Arayuz ince ayarlari uygulandi (bazi degisikliklerin gorunmesi icin oturum kapatilip acilmasi gerekebilir)." -ForegroundColor Green

# ----------------------------------------------------
# 14. ADIM: KLASIK (WINDOWS 10 TARZI) SAG TIK MENUSUNU GERI GETIRME
# ----------------------------------------------------
Write-Host "`n[14/16] Klasik Sag Tik Baglam Menusu Geri Getiriliyor..." -ForegroundColor Yellow

try {
    $classicMenuPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
    if (-not (Test-Path $classicMenuPath)) {
        New-Item -Path $classicMenuPath -Force -ErrorAction Stop | Out-Null
    }
    Set-ItemProperty -Path $classicMenuPath -Name "(Default)" -Value "" -ErrorAction Stop
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Process explorer.exe
    Write-Host "Klasik sag tik menusu etkinlestirildi (Windows Gezgini yeniden baslatildi)." -ForegroundColor Green
} catch {
    Write-Warning "Klasik sag tik menusu ayarlanamadi. Bu adim atlanip devam ediliyor."
}

# ----------------------------------------------------
# 15. ADIM: ONEDRIVE'I KALDIRMA (BEST-EFFORT)
# ----------------------------------------------------
Write-Host "`n[15/16] OneDrive Kaldiriliyor..." -ForegroundColor Yellow
Write-Host "Uninstalling OneDrive..." -ForegroundColor Yellow

try {
    Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    $oneDriveSetup = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
    if (-not (Test-Path $oneDriveSetup)) {
        $oneDriveSetup = "$env:SystemRoot\System32\OneDriveSetup.exe"
    }

    if (Test-Path $oneDriveSetup) {
        Start-Process $oneDriveSetup -ArgumentList "/uninstall" -Wait -ErrorAction Stop
        Write-Host "OneDrive kaldirma komutu calistirildi." -ForegroundColor Green
    } else {
        throw "OneDriveSetup.exe bulunamadi."
    }

    Remove-Item -Path "$env:USERPROFILE\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:PROGRAMDATA\Microsoft OneDrive" -Recurse -Force -ErrorAction SilentlyContinue

    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" "DisableFileSyncNGSC" 1
} catch {
    Write-Warning "OneDrive kaldirilamadi ($($_.Exception.Message)). Bu adim atlanip devam ediliyor."
}

# ----------------------------------------------------
# 16. ADIM: WINDOWS "HAKKINDA" DESTEK BILGILERINI AYARLAMA (OEM BILGISI)
# ----------------------------------------------------
Write-Host "`n[16/16] Windows Ayarlari > Sistem > Hakkinda Kismindaki Destek Bilgileri Ayarlaniyor..." -ForegroundColor Yellow

$OemInfoPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation"
Set-RegValue $OemInfoPath "Manufacturer" "WinHafiflet" "String"
Set-RegValue $OemInfoPath "Model" "WinHafiflet" "String"
Set-RegValue $OemInfoPath "SupportURL" "https://github.com/yilmazbakar84-lang/WinHafiflet" "String"
Set-RegValue $OemInfoPath "SupportPhone" "" "String"
Set-RegValue $OemInfoPath "SupportHours" "" "String"

Write-Host "Destek bilgileri ayarlandi (program adi: WinHafiflet, baglanti: GitHub sayfaniz)." -ForegroundColor Green
Write-Host "Kontrol etmek icin: Ayarlar > Sistem > Hakkinda > Windows Belirtimleri > Destek Al" -ForegroundColor DarkYellow

Write-Host "`n=== Tum Islemler Basariyla Tamamlandi! ===" -ForegroundColor Green
Write-Host "Sistemin tamamen hafiflemesi ve degisikliklerin tam oturmasi icin bilgisayari YENIDEN BASLATMAYI unutma!" -ForegroundColor Cyan
