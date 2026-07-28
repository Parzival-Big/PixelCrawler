# Pixel Crawler

Un dungeon crawler **2.5D** in pixel art per **iOS** e **Android**, costruito con [Flutter](https://flutter.dev) + [Flame](https://flame-engine.org).

Esplora un dungeon infinito generato proceduralmente, sconfiggi i mostri, raccogli monete e pozioni, trova le scale e scendi sempre più in profondità. Ogni piano è più difficile del precedente.

## Eroi

| Eroe | Stile | Note |
|---|---|---|
| **Knight** | Mischia | Tanta vita, spada ad ampio raggio |
| **Mage** | Distanza | Palle di fuoco esplosive con danno ad area |
| **Hunter** | Distanza | Frecce rapide, alta cadenza |
| **Rogue** | Mischia | Velocissimo, colpi critici |
| **Slime** | Mischia | 🔒 Si sblocca raggiungendo il **piano 3** |

Lo sblocco dello Slime (e i record) sono salvati in locale sul dispositivo.

## Controlli

- **Joystick virtuale** (sinistra) per muoversi
- **Pulsante rosso** (destra) per attaccare — mira automatica sul nemico più vicino
- Su desktop/emulatore: **WASD / frecce** per muoversi, **Spazio / J** per attaccare

## La grafica 2.5D

La visuale è top-down con profondità simulata:

- i muri hanno una **faccia frontale** in mattoni e una **cima** scura;
- tutte le entità sono **ordinate sull'asse Y** (chi è più in basso viene disegnato davanti);
- ombre ellittiche sotto i personaggi e bande di occlusione ambientale sotto i muri;
- torce animate con **bagliore additivo**.

## Asset

La grafica è l'asset pack 1-bit (16×16, palette a 3 toni `#B9DDA7` / `#68A08A` / `#1E4250`) contenuto in **`assets/raw_pack/`** (tiles, objects, monsters). La GUI usa la stessa palette.

Gli sprite pronti per il gioco in `assets/images/` (strisce di animazione, eroe Slime con corona, effetti nella palette del pack) sono **composti automaticamente** dal raw pack:

```bash
pip install pillow
python3 tools/prepare_pack.py
```

Da rieseguire ogni volta che il raw pack cambia. La mappatura fra file e sprite di gioco (percorsi, dimensioni e numero di frame) vive in un unico punto: **`lib/config/game_assets.dart`**.

I muri usano l'**auto-tiling**: il renderer sceglie il tile giusto (dritto, angolo interno/esterno, 5 varianti di texture) in base a dove si trova il pavimento rispetto al muro.

Il font incluso è [Press Start 2P](https://fonts.google.com/specimen/Press+Start+2P) (licenza SIL OFL), in tema con la pixel art. `tools/generate_placeholders.py` resta disponibile come fallback per rigenerare sprite segnaposto.

## Eseguire il progetto

```bash
flutter pub get
flutter run                      # dispositivo/emulatore collegato
```

### Build Android

```bash
flutter build apk --release      # oppure: flutter build appbundle
```

### Build iOS (richiede macOS + Xcode)

```bash
flutter build ios --release
```

Il gioco è bloccato in **orientamento orizzontale** con UI immersiva.

### Web (per provarlo al volo nel browser)

```bash
flutter run -d chrome
```

## Test

```bash
flutter analyze
flutter test
```

I test coprono: generazione del dungeon (le scale sono sempre raggiungibili, tutto lo spawn è su tile calpestabili), progressione della difficoltà, salvataggio/sblocco dello Slime e uno smoke test che avvia il gioco vero con ogni eroe e simula alcuni secondi di gameplay.

## Struttura del codice

```
lib/
├── config/game_assets.dart        # registro di tutti gli asset (unico punto di rimappatura)
├── services/save_service.dart     # progressi persistenti (sblocchi, record)
├── game/
│   ├── pixel_crawler_game.dart    # FlameGame: camera, input, piani, overlay
│   ├── heroes.dart                # definizioni dei 5 eroi
│   ├── monsters.dart              # definizioni dei mostri
│   ├── dungeon/                   # generatore procedurale + modello griglia
│   └── components/                # player, mostri, attacchi, oggetti, renderer 2.5D
└── ui/
    ├── theme.dart                 # palette + font pixel
    ├── widgets/                   # PixelButton, PixelPanel, anteprime sprite
    └── screens/                   # menu, selezione eroe, schermata di gioco + HUD
```
