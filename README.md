# 🌦️ UMBRELLA ☂️

**UMBRELLA** is a Flutter-based mobile application that helps users plan their day around the weather with clear, practical forecasts and timely reminders. It provides accurate, easy-to-read updates about upcoming rain, temperature changes, and overall comfort levels — helping users make smarter decisions about commuting, travel, and outdoor plans.

---

## 👥 Team Members

| Name | Student ID | Role |
|------|------------|------|
| Alp Ege Bulutoğlu | 32397 | Project Coordinator |
| Aysın Nur İpek | 32393 | Testing & QA Lead |
| Yavuz Başkurt | 34543 | Documentation & Submission Lead |
| Berkay Türeyen | 30763 | Integration & Repository Lead |
| Nisa Kan | 31999 | Presentation & Communication Lead |

---

## 📦 Deliverables
- Working Flutter application (demo-ready)
- GitHub repository with visible commits (implementation + integration + fixes)
- Automated tests (at least **1 unit** + **1 widget**) and `flutter test` passes
- `README.md` with setup/run instructions and test explanations
- Final PDF report (to be uploaded on SUCourse)
- 5-minute demo video (Google Drive link)

---

## ✅ Requirements
- Flutter SDK: **3.7.x**
- Dart: **3.7.x**
- Android Studio / Xcode (emulator/simulator)
- Firebase project configured (Auth + Firestore)

---

## 🚀 Setup & Run Instructions

### 1) Clone the repository
```bash
git clone https://github.com/Alpegeb/UMBRELLA.git
cd UMBRELLA
````

### 2) Install dependencies

```bash
flutter pub get
```

### 3) Firebase configuration

This project uses **Firebase Authentication** and **Cloud Firestore**.
✅ Firebase is already configured in the repository (required config files are included).

### 4) Run the app

```bash
flutter run
```

---

## 🧪 Testing

Run all tests:

```bash
flutter test
```

Integration test (optional):

```bash
flutter test integration_test
```

### What our tests cover

We implemented at least **2 meaningful tests** (1 unit test + 1 widget test) and ensured `flutter test` passes successfully.

1. **Unit Test — `test/settings_state_unit_test.dart`**
   Verifies that `SettingsState` loads preferences from `SharedPreferences`, updates them through setter methods, and persists values across new `SettingsState` instances.

2. **Widget Test — `test/settings_state_widget_umbrella_toggle_test.dart`**
   Pumps a minimal UI using `Provider`, waits for `SettingsState` to finish loading, taps the toggle button, and confirms the displayed text updates when `showUmbrellaIndex` changes.

3. **Smoke Test — `test/widget_test.dart`**
   Simple sanity check to ensure the test pipeline runs correctly.

4. **Integration Test — `integration_test/app_launch_test.dart`**
   End-to-end smoke test that launches a minimal app entrypoint and verifies the app starts successfully.

---

## Known Limitations / Notes

* Some background features (e.g., notifications / background tasks) may behave differently on emulators due to OS restrictions.
* If location permissions are denied, weather-based features may be limited.

---

## 📽️ Video Demo

* Google Drive video link:

```
https://drive.google.com/drive/folders/1JNxIXDQkgdzMutTdpftluHGEoEYKak8h?usp=sharing
```
