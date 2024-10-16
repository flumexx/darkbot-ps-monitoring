# Trage hier deine Webhook URL ein
$hookUrl = ''

# Der zu Ueberwachende Prozessname
$processName = 'javaw'  # Beispiel: javaw1

# Ueberwachungsintervall in Sekunden
$checkInterval = 10

# Pfad zur Steuerdatei fuer die Aktivierung/Deaktivierung des Monitorings
$controlFilePath = "C:\MonitorControl\monitoring_status.txt"

# Funktion zum Senden einer Discord-Webhook
function Send-DiscordWebhook {
    param (
        [string]$message
    )

    # Erstelle den Payload faer den Webhook
    $Body = @{
        'username' = 'DarkBot-Monitoring'
        'content'  = $message
    }

    # Senden des Webhooks
    Invoke-RestMethod -Uri $hookUrl -Method 'post' -Body $Body
}

# Funktion zum Ueberwachen des Prozesses
function MonitorProcess {
    while ($true) {
        # aeberpraefen, ob Monitoring aktiviert ist
        if (Test-Path $controlFilePath) {
            $monitoringStatus = Get-Content $controlFilePath

            if ($monitoringStatus -eq "disabled") {
                Write-Host "Monitoring ist deaktiviert. Warte 60 Sekunden, bevor erneut geprüft wird..."
                Start-Sleep -Seconds 60
                continue
            }
        } else {
            # Falls die Datei nicht existiert, standardmaeaeig Monitoring aktivieren
            New-Item -Path $controlFilePath -ItemType File -Value "enabled" -Force
            Write-Host "Steuerdatei nicht gefunden, Monitoring standardmaeaeig aktiviert."
        }

        # Ueberpruefen, ob der Prozess laeuft
        $process = Get-Process -Name $processName -ErrorAction SilentlyContinue

        if (-not $process) {
            # Wenn der Prozess nicht laeuft, sende eine Benachrichtigung an Discord
            $message = "Der Prozess '$processName' läuft nicht mehr!"
            Send-DiscordWebhook -message $message

            # Erste Wartezeit: 10 Minuten (600 Sekunden)
            Write-Host "Der Prozess '$processName' läuft nicht. Warte 10 Minuten, um erneut zu prüfen..."
            Start-Sleep -Seconds 600  # 10 Minuten warten

            # Erneut praefen, ob der Prozess laeuft
            $process = Get-Process -Name $processName -ErrorAction SilentlyContinue

            if (-not $process) {
                # Zweite Wartezeit: 60 Minuten (3600 Sekunden)
                Write-Host "Der Prozess '$processName' läuft nach 10 Minuten immer noch nicht. Warte 60 Minuten, um erneut zu prüfen..."
                Start-Sleep -Seconds 3600  # 60 Minuten warten

                # Endlosschleife, die alle 60 Minuten prueft
                while ($true) {
                    # Praefen, ob der Prozess wieder laeuft
                    $process = Get-Process -Name $processName -ErrorAction SilentlyContinue

                    if (-not $process) {
                        # Wenn der Prozess immer noch nicht laeuft, sende erneut eine Benachrichtigung
                        $message = "Der Prozess '$processName' läuft immer noch nicht."
                        Send-DiscordWebhook -message $message

                        # Warte wieder 60 Minuten
                        Write-Host "Der Prozess '$processName' läuft immer noch nicht. Warte erneut 60 Minuten..."
                        Start-Sleep -Seconds 3600  # Weitere 60 Minuten warten
                    } else {
                        # Wenn der Prozess wieder laeuft, beende die Schleife und gehe zur Hauptaeberwachung zuraeck
                        Write-Host "Der Prozess '$processName' läuft wieder. Überwachung wird fortgesetzt..."
                        break
                    }
                }
            } else {
                # Der Prozess laeuft wieder nach den ersten 10 Minuten
                Write-Host "Der Prozess '$processName' läuft wieder nach 10 Minuten. Überwachung wird fortgesetzt..."
            }
        }

        # Warte das regulaere Intervall, bevor erneut geprueft wird
        Start-Sleep -Seconds $checkInterval
    }
}

# Starten des Monitorings
MonitorProcess
