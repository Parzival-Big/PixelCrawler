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

## Usare i tuoi asset (tiles / objects / monsters)

Il gioco attualmente usa sprite **segnaposto** generati da `tools/generate_placeholders.py`, con la stessa struttura di cartelle del tuo asset pack:

```
assets/images/
├── tiles/      floor.png, wall_front.png, wall_top.png, stairs.png
├── objects/    chest.png, coin.png, torch.png, potion_red.png, potion_blue.png
├── monsters/   slime.png, bat.png, skeleton.png, goblin.png
├── heroes/     knight.png, mage.png, hunter.png, rogue.png, slime_hero.png
├── effects/    slash.png, fireball.png, arrow.png, blob.png
└── ui/         heart_full.png, heart_half.png, heart_empty.png
```

Per sostituire la grafica con il tuo pack:

1. Copia i tuoi PNG dentro `assets/images/tiles/`, `assets/images/objects/`, `assets/images/monsters/` (e `heroes/` per i personaggi).
2. Apri **`lib/config/game_assets.dart`**: è l'**unico** file che conosce i nomi dei file e il layout dei frame. Aggiorna percorso, dimensione dei frame e numero di frame di ogni sprite (le animazioni sono strisce orizzontali).
3. Fatto: il resto del codice non fa riferimento ad alcun file.

Il font incluso è [Press Start 2P](https://fonts.google.com/specimen/Press+Start+2P) (licenza SIL OFL), in tema con la pixel art.

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

## Rigenerare gli sprite segnaposto

```bash
pip install pillow
python3 tools/generate_placeholders.py
```

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
