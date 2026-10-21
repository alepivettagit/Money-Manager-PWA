<div align="center">
  # 🌐 Money Manager (Web & PWA)
  **Applicazione Web e Progressive Web App (PWA) per la gestione finanziaria personale, sincronizzazione Cloud Firestore e Scansione Scontrini con Google Gemini AI.**

  [![Flutter Web](https://img.shields.io/badge/Flutter-Web_%26_PWA-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
  [![Firebase](https://img.shields.io/badge/Firebase-Auth_%26_Firestore_%26_Hosting-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
  [![Google Gemini](https://img.shields.io/badge/Gemini_AI-Receipt_OCR-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://aistudio.google.com)
  [![PWA Ready](https://img.shields.io/badge/PWA-Installable-5A0FC8?style=for-the-badge&logo=pwa&logoColor=white)](https://web.dev/progressive-web-apps/)
</div>

---

## 📱 Cos'è Money Manager PWA?

**Money Manager PWA** è la versione Web e **Progressive Web App** di Money Manager. Può essere utilizzata direttamente da qualsiasi browser su computer, tablet o smartphone, oppure **installata sulla schermata Home del tuo dispositivo** comportandosi come una vera e propria applicazione nativa a schermo intero (senza le barre del browser).

- 📱 **Design Reattivo & Mobile-Framed**:
  - Su schermi desktop/laptop: visualizza un elegante frame centrale in formato smartphone per un'esperienza d'uso focalizzata e pulita.
  - Su smartphone e tablet: si espande automaticamente al 100% dell'altezza e larghezza del display.
- ⚡ **Scansione Scontrini Intelligente**: carica una foto o usa la fotocamera per analizzare automaticamente gli scontrini con **Google Gemini AI**.
- ☁️ **Sincronizzazione Cloud in Tempo Reale**: sincronizzata con **Cloud Firestore**, compatibile al 100% con la versione mobile Android APK.
- 🏷️ **Gestione Categorie Personalizzate**: crea e organizza categorie di entrata e spesa con icone e colori dedicati.

---

## 📲 Come Installare la PWA sul Tuo Telefono (Senza Store)

Puoi installare Money Manager sulla schermata principale del tuo smartphone in pochi secondi:

### Su iPhone / iPad (Safari):
1. Apri il link della tua Web App su **Safari**.
2. Tocca il pulsante **Condividi** (l'icona con il quadrato e la freccia verso l'alto in basso al centro).
3. Scorri le opzioni e tocca **"Aggiungi a schermata Home"** (Add to Home Screen).
4. Tocca **Aggiungi** in alto a destra. L'icona dell'app comparirà tra le tue applicazioni!

### Su Android (Chrome / Samsung Internet):
1. Apri il link della tua Web App su **Google Chrome**.
2. Tocca il banner che compare in basso **"Installa Money Manager"** oppure tocca i tre puntini in alto a destra `⋮` e seleziona **"Installa app"** (o *"Aggiungi a schermata Home"*).
3. Conferma con **Installa**. L'app verrà installata e sarà avviabile a schermo intero come una normale app Android!

---

## ✨ Funzionalità Principali

1. **Autenticazione Cloud**: login e registrazione sicura con email e password (con recupero password integrato).
2. **Multi-Conto**: gestione di saldi multipli (Conto Corrente, Risparmi, Contanti, Carte).
3. **Scansione Scontrini con IA (Gemini)**: estrazione automatica di totale, negozio, data e categoria dalle ricevute.
4. **Categorie Personalizzate**: aggiunta di nuove categorie con selezione visiva di oltre 30 icone e palette colori.
5. **Dashboard & Calendario**: statistiche mensili, grafici a torta interattivi e navigazione spese su calendario.

---

## 🛠️ Guida Sviluppatore: Configurazione e Deploy

### 1. Prerequisiti
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.13.5`)
- [Node.js](https://nodejs.org/) & [Firebase CLI](https://firebase.google.com/docs/cli) (`npm install -g firebase-tools`)
- Un account Google con accesso a [Firebase Console](https://console.firebase.google.com/) e [Google AI Studio](https://aistudio.google.com/)

---

### 2. Configurazione Firebase
1. Vai su [Firebase Console](https://console.firebase.google.com/) e crea un nuovo progetto.
2. **Abilita Authentication**: attiva il provider **Email/Password** nella sezione *Sign-in method*.
3. **Abilita Cloud Firestore**: crea il database e applica le regole in `firestore.rules`:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId}/{document=**} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```
4. **Registra un'app Web**:
   - Vai nelle impostazioni del progetto -> *Aggiungi app* -> seleziona **Web** `</>`.
   - Copia il file template `lib/firebase_options.dart.example`:
     ```bash
     cp lib/firebase_options.dart.example lib/firebase_options.dart
     ```
   - Inserisci la tua `apiKey`, `appId`, `projectId`, `authDomain` e `storageBucket` in `lib/firebase_options.dart`.

---

### 3. Configurazione Google Gemini API (Scanner Scontrini)
1. Ottieni una chiave API gratuita su [Google AI Studio](https://aistudio.google.com/apikey).
2. *(Opzionale consigliato)* Nelle impostazioni della chiave su Google AI Studio, imposta la restrizione HTTP Referrer sul dominio della tua web app (es. `https://tuo-progetto.web.app/*`) per proteggerla da utilizzi non autorizzati.
3. Copia il file template:
   ```bash
   cp lib/constants/api_constants.dart.example lib/constants/api_constants.dart
   ```
4. Inserisci la tua chiave in `lib/constants/api_constants.dart`.

---

### 4. Configurazione Firebase Hosting
1. Copia il file template `.firebaserc.example`:
   ```bash
   cp .firebaserc.example .firebaserc
   ```
2. Modifica `.firebaserc` inserendo il Project ID del tuo progetto Firebase.

---

### 5. Avvio Locale & Deploy in Produzione

#### Test Locale nel Browser:
```bash
# 1. Scarica le dipendenze
flutter pub get

# 2. Avvia l'app su Chrome
flutter run -d chrome
```

#### Pubblicazione su Firebase Hosting:
```bash
# 1. Effettua il login su Firebase CLI (se non già fatto)
firebase login

# 2. Compila la versione Web ottimizzata per la produzione
flutter build web --release

# 3. Distribuisci su Firebase Hosting e aggiorna le regole Firestore
firebase deploy
```
Al termine del comando, Firebase ti fornirà l'URL pubblico (es. `https://tuo-progetto.web.app`) accessibile da tutto il mondo!

---

## 📂 Struttura del Progetto

```text
lib/
├── constants/          # Configurazione Google Gemini AI
├── models/             # Modelli Account, Transaction e CategoryItem
├── providers/          # State management con Provider
├── screens/            # Schermate Auth, Home, Calendario, Ripartizione, Saldi
├── services/           # Servizi AuthService, DatabaseHelper (Firestore), GeminiReceiptService
└── widgets/            # Dialoghi di creazione, gestione categorie, scanner IA, grafici
web/
├── index.html          # Entrypoint Web con meta tag per PWA
├── manifest.json       # Configurazione installabilità PWA
└── icons/              # Icone PWA nelle diverse risoluzioni
```

---

## 📄 Licenza
Rilasciato sotto licenza MIT.
