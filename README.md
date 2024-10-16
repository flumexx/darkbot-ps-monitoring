# darkbot-ps-monitoring

# Installationsanleitung für das Monitoring auf einem Windows Server

### Achtung: es wird der Prozess Name "javaw" überwacht. Sollte es einen anderen oder weiteren Prozess geben, funktioniert das Monitoring nicht! 

## 1. PowerShell-Skript vorbereiten:
- Kopiere Skript `Monitor.ps1` und speichere es unter `C:\MonitorControl\Monitor.ps1`.

- **Webhook URL in das Skript einfügen**:
  - Erstelle einen Discord Webhook in deinem Discord-Channel:
    Gehe zu deinem Channel > Einstellungen > Integrationen > Webhooks > "Webhook erstellen" > URL kopieren.
  - Füge die Webhook-URL im Skript `Monitor.ps1` unter `$hookUrl` ein.

## 2. NSSM herunterladen und installieren:
- Lade NSSM von der offiziellen Seite: https://nssm.cc/download.
- Entpacke NSSM nach `C:\nssm\`.

## 3. Dienst mit NSSM einrichten:
- Öffne eine CMD als Administrator.
- Führe den Befehl aus:
  ```bash
  C:\nssm\win64\nssm.exe install ProcessMonitorService "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -File "C:\MonitorControl\Monitor.ps1"
  ```

## 4. Dienst starten:
- Starte den Dienst:
  ```bash
  net start ProcessMonitorService
  ```

## 5. PowerShell-Ausführungsrichtlinie anpassen (falls erforderlich):
- Setze die Ausführungsrichtlinie:
  ```powershell
  Set-ExecutionPolicy RemoteSigned
  ```


# Funktionsweise des PowerShell-Monitoring-Skripts

## 1. Prozessüberwachung:
Das Skript überwacht in regelmäßigen Intervallen, ob ein definierter Prozess auf dem System läuft (im Beispiel: `javaw1`). Der Name des zu überwachenden Prozesses wird in der Variablen `$processName` festgelegt. Die Überprüfung erfolgt im Intervall von 10 Sekunden (konfiguriert über `$checkInterval`).

## 2. Benachrichtigung via Discord Webhook:
Wenn der Prozess nicht mehr läuft, wird eine Benachrichtigung über einen Discord Webhook versendet. Der Webhook-Link wird in der Variablen `$hookUrl` hinterlegt. Das Skript nutzt die Funktion `Send-DiscordWebhook`, um Nachrichten an Discord zu senden. Die Nachricht enthält Informationen darüber, dass der Prozess nicht mehr aktiv ist.

## 3. Wartezeiten bei Prozessausfall:
- Nach dem ersten Feststellen, dass der Prozess nicht mehr läuft, wartet das Skript 10 Minuten und prüft erneut.
- Läuft der Prozess nach den 10 Minuten immer noch nicht, wird erneut eine Nachricht an Discord gesendet, und das Skript wartet anschließend 60 Minuten, bevor es wieder überprüft.
- Falls der Prozess weiterhin nicht läuft, wird das Skript alle 60 Minuten erneut überprüfen und Benachrichtigungen senden.

## 4. Aktivierung und Deaktivierung des Monitorings:
Das Monitoring kann durch eine Steuerdatei gesteuert werden (`C:\MonitorControl\monitoring_status.txt`). Der Inhalt dieser Datei bestimmt, ob das Monitoring aktiv ist:
- **"enabled"**: Das Monitoring ist aktiv.
- **"disabled"**: Das Monitoring ist deaktiviert und wird alle 60 Sekunden den Status der Datei überprüfen.

## 5. Neustart des Monitorings:
Sollte der überwachte Prozess nach einem Ausfall wieder starten, wird das Monitoring fortgesetzt und das Skript kehrt in die Standardüberwachung zurück.

Das Skript läuft kontinuierlich im Hintergrund, um den definierten Prozess zu überwachen und Benachrichtigungen zu versenden, falls der Prozess nicht mehr aktiv ist.
