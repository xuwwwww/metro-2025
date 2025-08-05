# Metro App - Flutter Firebase Chat Application

A Flutter-based mobile application with Firebase Firestore integration for user authentication and real-time chat room management. Built for Metro Hackerthon 2025 Team 47.

## Installation and Setup

### Prerequisites Installation

#### 1. Install Node.js and npm
```bash
# Download and install Node.js from: https://nodejs.org/
# Choose LTS version (recommended: 18.x or higher)

# Verify installation
node --version
npm --version
```

#### 2. Install Flutter SDK
```bash
# Download Flutter SDK from: https://flutter.dev/docs/get-started/install
# Extract to a directory (e.g., C:\flutter)

# Add Flutter to PATH environment variable
# Add C:\flutter\bin to your system PATH

# Verify installation
flutter doctor
```

#### 3. Install Android Studio
```bash
# Download Android Studio from: https://developer.android.com/studio
# Install with default settings
# Install Android SDK (API level 21+)
# Install Android NDK (latest version)
```

#### 4. Install Project Dependencies
```bash
# Clone the repository
git clone <repository-url>
cd metro

# Install Node.js dependencies for manage.js CLI
npm install

# Install Flutter dependencies
flutter pub get
```

#### 5. Firebase Setup
1. Create a Firebase project at https://console.firebase.google.com/
2. Enable Firestore database
3. Download `serviceAccountKey.json` and place in project root
4. Update Firebase configuration in `android/app/google-services.json`

#### 6. Database Initialization
```bash
# Initialize admin account and create all rooms
node manage.js init-admin
node manage.js init-rooms
```

#### 7. Run the Application
```bash
# Run on connected device or emulator
flutter run
```

## Project Overview

Metro App is a mobile application that provides:
- User Authentication: UID-based login system with password verification
- Chat Rooms: Real-time messaging in metro station-themed chat rooms
- Persistent Storage: Remembers user login state and custom layouts
- Admin Management: Special admin account (UID: '0') with full permissions
- Customizable Home Screen: Draggable icon grid with persistent layout

## Development Environment

### System Requirements
- Operating System: Windows 10/11
- Flutter SDK: ^3.8.1
- Dart SDK: ^3.8.1
- Android Studio: Latest version
- Android SDK: API level 21+
- Android NDK: Latest version
- Node.js: 18+ (for manage.js CLI)

### Development Tools
- IDE: Android Studio / VS Code with Flutter extensions
- Version Control: Git
- Package Manager: Flutter pub, npm

### Firebase Configuration
- Firebase Project: Metro Hackerthon 2025
- Database: Firestore (NoSQL)
- Authentication: Custom UID-based system
- Real-time: Firestore listeners for chat messages

## Project Structure

```
metro/
├── android/                 # Android platform files
├── ios/                    # iOS platform files
├── lib/                    # Main Flutter source code
│   ├── main.dart          # App entry point
│   ├── models/
│   │   └── app_item.dart  # AppItem model with JSON serialization
│   ├── pages/
│   │   ├── home_page.dart     # Main home screen with draggable grid
│   │   ├── chat_page.dart     # Real-time chat interface
│   │   ├── settings_page.dart # User settings and authentication
│   │   ├── detail_page.dart   # App detail pages
│   │   └── others_page.dart   # Other features page
│   └── widgets/
│       ├── draggable_icon_grid.dart  # Draggable home screen grid
│       ├── item_selector.dart        # Icon selection widget
│       ├── dynamic_widget.dart       # Dynamic widgets (clock, etc.)
│       ├── color_picker.dart         # Color selection widget
│       ├── icon_picker.dart          # Icon selection widget
│       └── add_icon_button.dart      # Add icon button widget
├── manage.js              # Firebase Firestore management CLI
├── serviceAccountKey.json # Firebase service account credentials
├── pubspec.yaml          # Flutter dependencies
└── README.md            # This file
```

## Firebase Database Schema

### Collections Structure

#### 1. `users` Collection
```javascript
users/{uid} {
  displayName: string,      // User's display name
  password: string,         // User's password (encrypted in production)
  permissions: string[],    // Array of room IDs user can access
  createdAt: timestamp      // Account creation timestamp
}
```

**Example:**
```javascript
users/0 {
  displayName: "Admin",
  password: "X9v$2L!z7#qT",
  permissions: ["台北車站", "善導寺", "忠孝新生", ...],
  createdAt: Timestamp
}

users/1 {
  displayName: "John Doe",
  password: "userpass123",
  permissions: ["台北車站", "善導寺"],
  createdAt: Timestamp
}
```

#### 2. `chatRooms` Collection
```javascript
chatRooms/{roomId} {
  name: string,             // Room display name
  createdBy: string,        // Creator's UID
  createdAt: timestamp      // Room creation timestamp
}
```

**Subcollection: `chatRooms/{roomId}/members`**
```javascript
chatRooms/{roomId}/members/{uid} {
  joinedAt: timestamp       // When user joined the room
}
```

**Subcollection: `chatRooms/{roomId}/messages`**
```javascript
chatRooms/{roomId}/messages/{messageId} {
  senderUid: string,        // Sender's UID
  senderProfile: {          // Sender's profile info
    displayName: string,
    avatarUrl: string
  },
  content: string,          // Message content
  timestamp: timestamp      // Message timestamp
}
```

### Default Metro Stations (Chat Rooms)
- 台北車站
- 善導寺
- 忠孝新生
- 忠孝復興
- 忠孝敦化
- 國父紀念館
- 市政府
- 南港
- 南港展覽館

## manage.js CLI Tool

The `manage.js` file is a Node.js CLI tool for managing Firebase Firestore data. It provides comprehensive database management capabilities.

### Installation
```bash
npm install firebase-admin yargs
```

### Usage
```bash
node manage.js <command> [options]
```

### Available Commands

#### Query Commands
```bash
# List all chat rooms
node manage.js list-rooms

# List messages in a specific room
node manage.js list-messages <roomId>

# Export all data to JSON files
node manage.js fetch-data
```

#### Creation Commands
```bash
# Initialize admin account and grant all permissions
node manage.js init-admin

# Create all metro station chat rooms
node manage.js init-rooms

# Create a new user with username and password
node manage.js create-user <uid> <username> <password>

# Create a single chat room
node manage.js create-room <roomId> <name>
```

#### Deletion Commands
```bash
# Clear all users (except admin)
node manage.js clear-users

# Remove a specific user
node manage.js remove-user <uid>

# Clear all chat rooms
node manage.js clear-rooms

# Remove a specific chat room
node manage.js remove-room <roomId>

# Clear messages (all rooms or specific room)
node manage.js clear-messages [roomId]
```

#### Modification Commands
```bash
# Grant user access to a chat room
node manage.js grant <uid> <roomId>

# Revoke user access from a chat room
node manage.js revoke <uid> <roomId>
```

### Admin Account
- UID: `0`
- Password: `X9v$2L!z7#qT`
- Permissions: All chat rooms by default

## App Features

### Authentication System
- UID-based Login: Users log in with their UID and password
- Admin Account: Special UID '0' with full system access
- Auto UID Generation: New accounts get sequential UIDs (1, 2, 3...)
- Persistent Login: Login state survives app restarts

### Chat System
- Real-time Messaging: Live message updates using Firestore streams
- Room-based Chat: Separate chat rooms for different metro stations
- Permission-based Access: Users can only access rooms they have permissions for
- Message History: All messages stored in Firestore with timestamps

### Home Screen
- Draggable Grid: Customizable icon layout with drag-and-drop
- Persistent Layout: Icon positions saved and restored
- Dynamic Widgets: Clock widget and other interactive elements
- Icon Management: Add, remove, and reorder icons

### Settings
- User Profile: Edit display name
- Room Permissions: Select which chat rooms to join
- App Settings: Notifications, dark mode, font size
- Account Management: Login, logout, create account

## Data Flow

### Login Flow
1. User enters UID and password
2. App checks credentials against Firestore
3. If valid, login state saved to SharedPreferences
4. User permissions loaded from Firestore
5. User can access authorized chat rooms

### Chat Flow
1. User selects a chat room from their permissions
2. App connects to Firestore stream for real-time messages
3. Messages displayed in chronological order
4. New messages automatically appear in real-time
5. User can send messages which are stored in Firestore

### Layout Persistence
1. User customizes home screen layout
2. Layout data serialized to JSON
3. Saved to device using SharedPreferences
4. Restored on app startup
5. Changes persist across app sessions

## Security Considerations

### Current Implementation
- Passwords stored in plain text (should be hashed in production)
- UID-based authentication (consider adding email verification)
- Firestore security rules should be configured

### Recommended Improvements
- Implement password hashing (bcrypt)
- Add email verification system
- Configure Firestore security rules
- Implement rate limiting for chat messages
- Add message encryption for sensitive content

## Troubleshooting

### Common Issues

#### Firebase Connection
```bash
# Check Firebase configuration
flutter doctor
flutter pub get

# Verify service account key
node manage.js list-rooms
```

#### Build Issues
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

#### Database Issues
```bash
# Reset database (WARNING: Deletes all data)
node manage.js clear-users
node manage.js clear-rooms
node manage.js init-admin
node manage.js init-rooms
```

#### Node.js Issues
```bash
# Clear npm cache
npm cache clean --force

# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install
```

## License

This project is part of Metro Hackerthon 2025 Team 47.


**Metro App v0.0.1** - Built with Flutter and Firebase
