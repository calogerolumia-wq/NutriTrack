# NutriTrack

NutriTrack e una app Flutter offline per importare, correggere e gestire una dieta settimanale.

## Funzionalita principali

- Gestione settimanale di giorni, pasti e alimenti.
- Modifica manuale completa (aggiungi/modifica/elimina pasti e alimenti).
- Copia/incolla e duplicazione dei pasti tra giorni.
- Import da foto (camera o galleria) con OCR on-device (ML Kit) e revisione guidata.
- Export della dieta in PDF (condivisione/salvataggio dal sistema).
- Tema app (sistema/light/dark) e preferenze UI.

## Migliorie OCR implementate

- Parsing giorni e pasti con normalizzazione robusta del testo.
- Supporto accenti e varianti OCR (es. caratteri sporchi o codifiche miste).
- Riconoscimento quantita in piu formati:
  - `pane integrale 50 g`
  - `50 g pane integrale`
  - `pane integrale (50 g)`
  - `(50 g) pane integrale`
- Gestione numeri sia in cifra che in parola:
  - `1 mela`, `2 fette`
  - `una mela`, `due fette`, `tre ...`
- Supporto alternative alimento:
  - alternative inline (`oppure`, `in alternativa`, ecc.)
  - alternative in colonna destra del foglio (layout OCR con bounding box)
  - salvataggio delle alternative dentro ogni alimento.

## Flusso import

1. Scatto/selezione foto.
2. Crop immagine.
3. OCR + parsing automatico.
4. Revisione import (correzione campi incerti).
5. Salvataggio finale nel piano dieta.

Nota: la bozza OCR non viene salvata in modo definitivo finche non premi `Salva` nella schermata di revisione.

## Ricorrenza settimanale

Quando lavori su una nuova data, l'app puo riusare automaticamente il giorno con lo stesso weekday gia presente (es. lunedi successivo), cosi non devi reinserire tutto da zero ogni settimana.

## Formato date e testi UI

- Etichette giorno uniformate (es. `Lunedi`, `Martedi`, `Mercoledi`).
- Formato giorno visualizzato in stile: `Mercoledi 4 marzo`.
- Pulizia testo UI per evitare caratteri corrotti (mojibake).

## Dove salva i dati

Salvataggio locale sul dispositivo, nessun backend obbligatorio:

- Piano dieta: Hive box `mydiet_box`, chiave `diet_plan_json_v1`.
- Preferenze UI (tema, toggle metriche avanzate): SharedPreferences.

Su Android il file Hive e nella sandbox app, tipicamente:

`/data/user/0/com.example.mydiet/app_flutter/mydiet_box.hive`

## Export PDF

Da Impostazioni puoi generare un PDF completo della dieta.
Il file viene passato al foglio di condivisione del sistema, dove scegli dove salvarlo.

## Nome app e icona launcher

- Nome app impostato a: `NutriTrack` (Android/iOS).
- Icona configurata da: `assets/logo.png` tramite `flutter_launcher_icons`.

Se devi rigenerare le icone:

```bash
flutter pub get
dart run flutter_launcher_icons
```

## Avvio progetto

```bash
flutter pub get
flutter run
```
