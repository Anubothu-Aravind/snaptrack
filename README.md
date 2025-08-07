# SnapTrack

**SnapTrack** is a cross-platform Flutter application with a Python backend designed for real-time camera input, detection, and status monitoring. Built with modular architecture and platform flexibility, it supports Android, iOS, Web, Windows, macOS, and Linux environments.

---

## Features

- Real-time camera feed and detection overlay
- Custom detection models (via Python backend)
- Logs and status panel UI
- Platform support: Mobile, Web, Desktop
- Backend APIs for advanced processing (OpenCV, FastAPI, etc.)

---

## Project Structure

### Flutter Frontend (`lib/`)

| Folder             | Purpose |
|--------------------|---------|
| `main.dart`        | App entry point |
| `models/`          | Data models (`detection_models.dart`) |
| `providers/`       | State management (camera, detection, logs) |
| `screens/`         | UI pages (home, logs, settings) |
| `services/`        | Business logic (API/database services) |
| `widgets/`         | Reusable UI components (camera widget, alert overlay, etc.) |

### Python Backend (`python_backend/`)

| File/Folder         | Purpose |
|---------------------|---------|
| `main.py`           | Entry point for backend server |
| `requirements.txt`  | Python package dependencies |
| `car/`              | Local virtual environment and detection modules |

### Other Directories

- `assets/` – Static images and icons
- `test/` – Flutter widget testing
- `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/` – Platform-specific setup and code

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Python 3.8+
- Git

---

### 🔧 Setup

#### 1. Clone the Repository

```bash
git clone https://github.com/Anubothu-Aravind/snaptrack.git
cd snaptrack
````

#### 2. Set Up Flutter Frontend

```bash
cd flutter_application_1
flutter pub get
flutter run
```

#### 3. Set Up Python Backend

```bash
cd python_backend
python -m venv venv
# Activate virtualenv:
# On Windows:
venv\Scripts\activate
# On macOS/Linux:
source venv/bin/activate

pip install -r requirements.txt
python main.py
```

## Contributing

Pull requests are welcome. For major changes, open an issue first to discuss what you’d like to change or improve.


## 📬 Contact

Maintained by [@Anubothu-Aravind](https://github.com/Anubothu-Aravind)

---
