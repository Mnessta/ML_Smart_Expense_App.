# ML Smart Expense Track

A smart expense tracking Flutter app with AI-powered insights, beautiful UI, and offline support.

## Features

### 📊 Dashboard Overview
- ✅ Animated balance card with hide/show toggle
- ✅ Smart summary bar with spending insights
- ✅ Daily spending chart with animations
- ✅ Modern category carousel
- ✅ Expense insights and budget forecasting
- ✅ Smart alerts for budget limits
- ✅ Transaction timeline with slide-to-delete
- ✅ Savings goal tracking with gamification

### 🎨 User Experience
- ✅ Dark/Light theme toggle with moon/sun icons
- ✅ Customizable accent colors
- ✅ Pull-to-refresh
- ✅ Slide-to-delete/edit transactions
- ✅ Animated transitions
- ✅ Search functionality
- ✅ Offline support with sync queue

### 🔐 Authentication
- ✅ Email/Password authentication
- ✅ Google Sign-in
- ✅ Guest mode
- ✅ Password visibility toggle

### 💰 Expense Management
- ✅ Add expenses and income
- ✅ Category management
- ✅ Budget tracking
- ✅ Budget suggestions based on spending history
- ✅ Analytics and insights

### 🛠 Technical Features
- ✅ State management with Provider
- ✅ Centralized error handling
- ✅ Data validation
- ✅ Loading states with shimmer effects
- ✅ Performance optimizations (database indexes, lazy loading)
- ✅ Offline support with connectivity monitoring
- ✅ SQLite database
- ✅ SharedPreferences for user preferences

## Getting Started

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Android Studio / VS Code
- Android device or emulator

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd ML_smart_expense_track
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── app_router.dart          # Routing configuration
├── models/                  # Data models
├── screens/                 # Screen widgets
├── widgets/                 # Reusable widgets
├── services/                # Business logic services
├── providers/               # State management providers
├── utils/                   # Utilities and helpers
└── constants.dart           # App constants
```

## Key Dependencies

- `provider` - State management
- `go_router` - Navigation
- `sqflite` - Local database
- `shared_preferences` - Local storage
- `fl_chart` - Charts and graphs
- `lottie` - Animations
- `shimmer` - Loading states
- `connectivity_plus` - Network status

## Testing

Run tests with:
```bash
flutter test
```

## Building

### Android
```bash
flutter build apk
```

### iOS
```bash
flutter build ios
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License.

## Future Enhancements

- [ ] Supabase integration for cloud sync
- [ ] Receipt scanning with ML Kit
- [ ] Recurring expenses
- [ ] Export to PDF
- [ ] Multi-language support
- [ ] Biometric authentication
- [ ] Advanced analytics
- [ ] Budget templates
- [ ] AI spending assistant
