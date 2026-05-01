# KiranaBook — Flutter MVP
## किराना दुकान ऐप | Offline-First | Hindi UI

---

## ✅ QUICK START — 5 Steps

### Step 1: Install Flutter (if not installed)
```bash
# Download Flutter SDK from https://flutter.dev/docs/get-started/install
# Add to PATH, then verify:
flutter doctor
```

### Step 2: Unzip & Open Project
```bash
unzip kiranabook.zip
cd kiranabook
```

### Step 3: Install Dependencies
```bash
flutter pub get
```

### Step 4: Connect Android Phone
- Enable Developer Options on your Android phone:
  Settings → About Phone → Tap "Build Number" 7 times
- Enable USB Debugging:
  Settings → Developer Options → USB Debugging ON
- Connect via USB cable
- Allow the USB debugging prompt on phone

```bash
flutter devices   # should show your phone
```

### Step 5: Run the App
```bash
flutter run
```

For a release APK you can install without a cable:
```bash
flutter build apk --split-per-abi
# APK at: build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

---

## 📱 WHAT'S INSIDE

| Screen | Hindi | What it does |
|--------|-------|-------------|
| Home | घर | Daily summary — cash, udhaar, total outstanding |
| Bill | बिल | Tap items → Cash or Udhaar |
| Udhaar | उधार | All customers with balance, take payment |
| Saman | सामान | Stock list, add stock, edit prices |
| Settings | सेटिंग | Shop name, owner info |

---

## 🗂 PROJECT STRUCTURE

```
lib/
├── main.dart                    ← App entry + bottom nav shell
├── core/
│   ├── db/hive_db.dart          ← Hive init + seed data
│   ├── models/                  ← transaction, item, customer, store
│   ├── services/
│   │   ├── transaction_service.dart  ← createSale, createPayment, getBalance
│   │   ├── item_service.dart         ← stock management
│   │   ├── customer_service.dart     ← customer CRUD
│   │   └── share_service.dart        ← WhatsApp bill sharing
│   ├── utils/
│   │   ├── formatters.dart      ← ₹ currency, dates in Hindi
│   │   └── id_generator.dart    ← Offline-safe unique IDs
│   └── theme/app_theme.dart     ← Saffron + Green theme
└── features/
    ├── billing/billing_screen.dart  ← CORE: tap-based billing
    ├── udhaar/udhaar_screen.dart    ← ledger + customer detail
    ├── inventory/inventory_screen.dart
    ├── summary/summary_screen.dart
    └── settings/settings_screen.dart
```

---

## 💾 DATA MODEL

All data stored in **Hive** (local, offline, fast):

| Box | Purpose |
|-----|---------|
| `transactions` | Every sale, payment, stock add — immutable |
| `items` | Product catalog with stock counts |
| `customers` | Names + phone numbers |
| `store` | Shop settings |

**Key rule:** Customer balance is NEVER stored. Always computed:
`balance = SUM(udhaar sales) - SUM(payments)`

---

## 📦 DEPENDENCIES

| Package | Purpose |
|---------|---------|
| `hive_flutter` | Offline-first local DB |
| `flutter_riverpod` | State management |
| `share_plus` | WhatsApp sharing |
| `url_launcher` | Open WhatsApp |
| `intl` | Date/number formatting |
| `uuid` | Unique IDs |
| `connectivity_plus` | Internet status |

---

## 🔌 OFFLINE BEHAVIOUR

- ✅ All billing works with no internet
- ✅ Data saves to phone first, always
- ✅ No user action blocked by network state
- ✅ Offline-safe IDs: `storeId_timestamp_random4`

---

## 🚀 BUILD RELEASE APK

```bash
# Build optimized APK for ARM64 phones (most modern Android)
flutter build apk --release --split-per-abi

# Install directly to connected phone:
flutter install

# Or share the APK file:
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

---

## 🐛 TROUBLESHOOTING

**"No devices found"**
→ Enable USB debugging, try `flutter devices`

**"SDK not found"**
→ Run `flutter doctor` and fix the listed issues

**Fonts not loading**
→ The app uses Google Fonts fallback. Works without custom fonts.
→ For full Hindi support, download Baloo2 from Google Fonts into `assets/fonts/`

**Build fails on hive_generator**
→ Run: `flutter packages pub run build_runner build --delete-conflicting-outputs`
→ The .g.dart files are pre-generated in this project, so this shouldn't be needed.

---

## 📞 WHATSAPP BILL FORMAT

When sharing a bill, this text is sent:
```
🧾 *Sharma General Store*
📅 01 May 2026, 3:45 PM
─────────────────────
Aata × 2 = ₹50
Maggi × 4 = ₹60
─────────────────────
*Kul: ₹110* (💵 Cash)
─────────────────────
🙏 Dhanyavaad!
```

---

Made with ❤️ for India's 12M kirana shops.
