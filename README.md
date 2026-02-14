# FinGuard

A minimalistic Flutter Android app for **daily spending discipline**. FinGuard helps users maintain a fixed daily budget by enforcing behavioral budgeting through carry-forward logic, real-time visual feedback, and local notifications.

## 🚀 Key Features

- **Manual Expense Logging**: Quickly log expenses with custom categories, amounts, and optional descriptions.
- **Smart Dashboard**:
  - **Carry Forward**: Automatically rolls over your surplus or deficit to the next day.
  - **Today's Total**: Large typography for immediate spending awareness.
  - **Daily Limit**: Displays your set target at a glance.
- **Progress Tracking**: A dynamic progress bar showing current spending vs. the effective limit (Daily Limit + Carry Forward).
- **Discipline Mode**:
  - App theme shifts to **Red** when the limit is exceeded.
  - Local Notification triggers: *"Limit exceeded. Discipline mode activated."*
- **Weekly Overview**: Visualize your discipline over the last 7 days with bar charts and summary statistics (Total, Average, Days Over Limit).
- **Persistent Settings**: Configure your custom daily limit (e.g., ₹160).

## 🏗️ Architecture

The project follows a clean architecture pattern for scalability and maintainability:

```text
lib/
├── main.dart                          # App entry point & Theme configuration
├── models/                            # Data models (Expense, DailyRecord)
├── services/                          # Business logic (Database, Notifications)
└── screens/                           # UI Screens (Home, Add Expense, Settings, Chart)
```

- **Database**: SQLite (`sqflite`) for local data persistence.
- **Notifications**: `flutter_local_notifications` for real-time discipline alerts.
- **Charts**: `fl_chart` for beautiful weekly visualization.

## 🎨 Design Philosophy

- **Minimalistic**: White background, clean typography (Roboto).
- **Focused**: No unnecessary animations or feature bloat.
- **Visual Feedback**: Intentional use of Green (Safe) and Red (Exceeded) to nudge user behavior.

## 🛠️ Getting Started

### Prerequisites

- Flutter SDK (latest stable)
- Android Studio / VS Code with Flutter extension
- An Android Emulator or physical device

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yash-7575/FinGuard.git
   cd FinGuard
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run
   ```

## 📜 Technical Requirements

- Flutter
- SQLite (Local Storage)
- Local Notifications
- Shared Preferences (Settings)
