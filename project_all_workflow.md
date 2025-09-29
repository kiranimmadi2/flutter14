# Project All Workflow - Complete Flutter App Documentation

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Tech Stack](#2-tech-stack)
3. [Folder & File Structure](#3-folder--file-structure)
4. [Code Explanations](#4-code-explanations)
5. [Features & Workflows](#5-features--workflows)
6. [Data Flow](#6-data-flow)
7. [Setup & Run Instructions](#7-setup--run-instructions)
8. [Future Development Notes](#8-future-development-notes)

---

## 1. Project Overview

### What the App Does

**Supper** is an AI-powered universal matching platform that connects people based on natural language prompts. Users simply type what they're looking for (like "iPhone", "hiking partner in NYC", "lost dog", or "part-time designer") and the system intelligently matches them with complementary users in real-time.

The app acts as a universal connection hub that can handle:
- **Marketplace transactions** (buying/selling items)
- **Social connections** (dating, friendship, networking)
- **Professional services** (hiring, job seeking)
- **Lost & found** items/pets
- **Location-based activities** and meetups
- **Any other human interaction** that can be expressed in natural language

### Core Purpose and Functionality

**Primary Purpose**: Eliminate the need for multiple specialized apps by creating one intelligent platform that understands user intent and facilitates instant connections.

**Key Features**:
1. **Natural Language Processing**: Users type simple prompts instead of filling complex forms
2. **AI Intent Recognition**: System extracts meaning (buying, selling, looking, offering, etc.)
3. **Smart Clarification**: Asks follow-up questions when intent is unclear
4. **Real-time Matching**: Instantly finds complementary users based on intent + location + details
5. **Direct Communication**: Immediate chat and voice calling (no approval needed)
6. **Global Scalability**: Designed for millions of users worldwide

**User Journey Example**:
- User types: "iPhone"
- System asks: "Do you want to buy or sell an iPhone?"
- User answers: "Sell"
- System instantly shows buyers looking for iPhones in their area
- User can immediately chat or call interested buyers

### High-Level Architecture (Frontend, Backend, APIs, Database, Services)

#### Frontend (Flutter)
- **Cross-platform mobile app** (iOS, Android, Web)
- **Material Design UI** with dark/light theme support
- **Real-time responsive interface** with optimized performance
- **Voice calling integration** (no video calling)
- **Location-based services** with permission management
- **Push notifications** for matches and messages

#### Backend (Firebase)
- **Firebase Authentication** (Google Sign-in, email/password)
- **Cloud Firestore** (NoSQL database for real-time data)
- **Firebase Storage** (profile images, attachments)
- **Firebase Cloud Messaging** (push notifications)
- **Firebase Crashlytics** (error tracking and analytics)

#### APIs
- **Google Gemini AI** (intent recognition and clarification)
- **Google Text Embedding API** (semantic understanding and matching)
- **Firebase REST APIs** (data synchronization)
- **Google Maps APIs** (geocoding and location services)

#### Database (Cloud Firestore)
- **Users Collection**: Profiles, preferences, location data
- **AI Posts Collection**: User prompts with extracted intent and metadata
- **Conversations Collection**: Chat messages and call history
- **Matches Collection**: Real-time matching results and scoring
- **Optimized indexes** for location-based and intent-based queries

#### Services Architecture
- **Microservices Pattern**: Modular, scalable service architecture
- **AI Intent Engine**: Core intent analysis and extraction
- **Real-time Matching Service**: Multi-factor compatibility scoring
- **Conversation Service**: Chat and communication management
- **Location Service**: GPS and geocoding functionality
- **Notification Service**: Push notification orchestration
- **Profile Service**: User profile management
- **Error Handling Service**: Comprehensive error management and recovery
- **Memory Management**: Optimized resource usage and caching

---

## 2. Tech Stack

### Flutter & Dart Foundation
- **Flutter SDK**: 3.8.1+
- **Dart SDK**: ^3.8.1
- **Environment**: Multi-platform (iOS, Android, Web)
- **App Name**: "supper" (Supper - AI Assistant App)
- **Version**: 1.0.0+1

### Core Dependencies

#### Firebase Ecosystem
```yaml
firebase_core: ^3.8.0                    # Firebase initialization and core services
firebase_auth: ^5.3.3                    # User authentication (Google Sign-in, email/password)
cloud_firestore: ^5.4.4                  # NoSQL database with real-time updates
firebase_storage: ^12.3.4                # File storage (profile photos, attachments)
firebase_messaging: ^15.1.4              # Push notifications and background messaging
firebase_crashlytics: ^4.2.1             # Crash reporting and analytics
google_sign_in: ^6.2.2                   # Google OAuth integration
```

#### AI & Machine Learning
```yaml
google_generative_ai: ^0.4.6             # Google Gemini AI for intent analysis and matching
```

#### UI & User Experience
```yaml
cupertino_icons: ^1.0.8                  # iOS-style icons
cached_network_image: ^3.4.1             # Optimized image loading and caching
shimmer: ^3.0.0                          # Loading animations and skeleton screens
flutter_chat_bubble: ^2.0.2              # Chat message bubble widgets
badges: ^3.1.2                           # Notification badge overlays
```

#### Communication & Device Integration
```yaml
permission_handler: ^11.3.1              # Device permission management (location, camera, etc.)
flutter_local_notifications: ^18.0.1     # Local push notifications
url_launcher: ^6.3.1                     # External URL handling and deep links
```

#### Location & Mapping
```yaml
geolocator: ^13.0.2                      # GPS location services and distance calculations
geocoding: ^3.0.0                        # Address to coordinates conversion
```

#### State Management & Storage
```yaml
provider: ^6.1.2                         # State management solution
shared_preferences: ^2.3.2               # Local key-value storage
```

#### Utilities & Data Processing
```yaml
timeago: ^3.7.0                          # Relative time formatting ("2 hours ago")
image_picker: ^1.1.2                     # Camera and gallery access
intl: ^0.19.0                            # Internationalization and date formatting
uuid: ^4.5.1                             # Unique identifier generation
http: ^1.2.2                             # HTTP requests and API calls
connectivity_plus: ^6.0.5                # Network connectivity monitoring
```

#### Development & Testing
```yaml
flutter_test: # SDK                       # Unit testing framework
integration_test: # SDK                   # Integration testing framework
flutter_lints: 3.0.2                     # Dart/Flutter linting rules
flutter_patch_package: ^0.0.11           # Package modification utilities
```

### Platform-Specific Configuration

#### Android Configuration
- **Minimum SDK**: API 21 (Android 5.0)
- **Target SDK**: Latest available
- **Firebase Integration**: `google-services.json` in `android/app/`
- **Permissions**: Location, camera, microphone, internet, wake lock
- **Features**: Google Play Services, Firebase Cloud Messaging

#### iOS Configuration
- **Minimum iOS**: 12.0
- **Firebase Integration**: `GoogleService-Info.plist` in `ios/Runner/`
- **Capabilities**: Background modes, push notifications, location services
- **Privacy**: Location usage descriptions, camera usage descriptions

#### Web Configuration
- **Firebase SDK**: Web SDK integration
- **Service Worker**: Background message handling
- **Progressive Web App**: Manifest configuration
- **CORS**: Cross-origin resource sharing setup

---

## 3. Folder & File Structure

```
flutter 14/
├── .claude/                             # Claude AI assistant configuration
│   └── settings.local.json             # Local Claude settings
├── .idea/                              # IntelliJ IDEA/Android Studio configuration
│   ├── libraries/                      # SDK library configurations
│   ├── runConfigurations/              # Run configuration templates
│   └── workspace.xml                   # IDE workspace settings
├── android/                            # Android-specific configuration
│   └── app/
│       ├── src/
│       │   ├── main/
│       │   │   ├── AndroidManifest.xml # Main app manifest with permissions
│       │   │   └── res/                # Android resources (icons, styles)
│       │   ├── debug/                  # Debug build configuration
│       │   └── profile/                # Profile build configuration
│       └── google-services.json       # Firebase Android configuration
├── ios/                               # iOS-specific configuration
│   └── Runner/
│       └── Assets.xcassets/           # iOS app icons and launch images
├── web/                               # Web platform configuration
│   ├── index.html                     # Main web entry point
│   ├── manifest.json                  # PWA manifest
│   └── firebase-messaging-sw.js      # Service worker for background messages
├── lib/                               # Main Flutter source code
│   ├── main.dart                      # App entry point and initialization
│   ├── main_web.dart                  # Web-specific entry point
│   ├── firebase_options.dart          # Firebase platform configuration
│   ├── fix_platform_view_registry.dart # Web platform fixes
│   ├── platform_view_registry_fix.dart # Alternative platform fix
│   ├── web_platform_fix.dart          # Web-specific platform fixes
│   ├── models/                        # Data models and structures
│   │   ├── ai_post_model.dart         # AI-analyzed post model
│   │   ├── conversation_model.dart    # Chat conversation model
│   │   ├── message_model.dart         # Individual message model
│   │   ├── post_model.dart            # Legacy post model
│   │   └── user_profile.dart          # User profile model
│   ├── providers/                     # State management providers
│   │   └── theme_provider.dart        # App theme management (light/dark mode)
│   ├── screens/                       # Full-screen UI components
│   │   ├── login_screen.dart          # Authentication screen
│   │   ├── main_navigation_screen.dart # Main tab navigation
│   │   ├── home_screen.dart           # Dashboard/home screen
│   │   ├── feed_screen.dart           # User posts feed
│   │   ├── ai_create_post_screen.dart # AI-powered post creation
│   │   ├── create_post_screen.dart    # Legacy post creation
│   │   ├── universal_matching_screen.dart # Universal search interface
│   │   ├── ai_matching_screen.dart    # AI match display
│   │   ├── enhanced_ai_matching_screen.dart # Advanced AI matching
│   │   ├── enhanced_universal_matching_screen.dart # Enhanced universal search
│   │   ├── smart_matching_screen.dart # Smart matching interface
│   │   ├── whatsapp_style_matching_screen.dart # WhatsApp-style UI
│   │   ├── matching_screen.dart       # Basic match browsing
│   │   ├── chat_home_screen.dart      # Chat list screen
│   │   ├── chat_screen.dart           # Individual chat screen
│   │   ├── enhanced_chat_screen.dart  # Advanced chat features
│   │   ├── chat_screen_deprecated.dart # Legacy chat implementation
│   │   ├── conversations_screen.dart  # Conversation management
│   │   ├── profile_screen.dart        # User profile view
│   │   ├── profile_edit_screen.dart   # Profile editing interface
│   │   ├── profile_view_screen.dart   # View other user profiles
│   │   ├── profile_with_history_screen.dart # Profile with post history
│   │   ├── settings_screen.dart       # App settings
│   │   ├── theme_settings_screen.dart # Theme customization
│   │   └── performance_debug_screen.dart # Performance monitoring
│   ├── services/                      # Business logic services
│   │   ├── auth_service.dart          # Authentication management
│   │   ├── profile_service.dart       # User profile operations
│   │   ├── user_manager.dart          # User session management
│   │   ├── ai_intent_engine.dart      # Core AI intent analysis
│   │   ├── gemini_service.dart        # Google Gemini AI integration
│   │   ├── ai_matching_service.dart   # AI-powered matching engine
│   │   ├── enhanced_matching_service.dart # Enhanced matching algorithms
│   │   ├── fixed_ai_matching_service.dart # Optimized matching service
│   │   ├── realtime_matching_service.dart # Real-time match processing
│   │   ├── smart_intent_matcher.dart  # Intent compatibility scoring
│   │   ├── matching_service.dart      # Basic matching service
│   │   ├── matching_test_service.dart # Matching algorithm testing
│   │   ├── universal_intent_service.dart # Universal intent processing
│   │   ├── intent_clarification_service.dart # Intent clarification logic
│   │   ├── intent_extraction_service.dart # Intent extraction utilities
│   │   ├── progressive_intent_service.dart # Progressive intent refinement
│   │   ├── sequential_clarification_service.dart # Sequential Q&A service
│   │   ├── unified_intent_processor.dart # Unified intent processing
│   │   ├── comprehensive_ai_service.dart # Comprehensive AI operations
│   │   ├── smart_prompt_parser.dart   # Natural language prompt parsing
│   │   ├── conversation_service.dart  # Chat management
│   │   ├── notification_service.dart  # Push notification handling
│   │   ├── firebase_storage_service.dart # File upload/download
│   │   ├── location_service.dart      # GPS and location services
│   │   ├── geocoding_service.dart     # Address geocoding
│   │   ├── connectivity_service.dart  # Network connectivity monitoring
│   │   ├── vector_service.dart        # Vector embedding operations
│   │   ├── embedding_cache_service.dart # Embedding caching
│   │   ├── photo_cache_service.dart   # Photo caching service
│   │   ├── optimized_firestore_service.dart # Optimized Firestore operations
│   │   ├── safe_firestore_service.dart # Safe Firestore operations
│   │   ├── safe_network_service.dart  # Safe network operations
│   │   ├── migration_service.dart     # Data migration utilities
│   │   ├── debug_service.dart         # Debugging utilities
│   │   └── error_handler.dart         # Global error handling
│   ├── utils/                         # Utility functions and helpers
│   │   ├── app_optimizer.dart         # App performance optimization
│   │   ├── memory_manager.dart        # Memory management
│   │   ├── performance_monitor.dart   # Performance monitoring
│   │   ├── network_utils.dart         # Network utility functions
│   │   ├── api_error_handler.dart     # API error handling
│   │   ├── firestore_error_handler.dart # Firestore-specific error handling
│   │   ├── photo_url_helper.dart      # Photo URL utilities
│   │   ├── ui_integration_helper.dart # UI integration utilities
│   │   ├── keyboard_helper.dart       # Keyboard management
│   │   └── matching_system_tester.dart # Matching system testing
│   └── widgets/                       # Reusable UI components
│       ├── ai_clarification_dialog.dart # AI question dialogs
│       ├── conversational_clarification_dialog.dart # Conversational Q&A
│       ├── conversational_intent_dialog.dart # Intent conversation
│       ├── enhanced_clarification_dialog.dart # Enhanced clarification UI
│       ├── intent_clarification_dialog.dart # Intent clarification widgets
│       ├── sequential_clarification_dialog.dart # Sequential Q&A
│       ├── simple_intent_dialog.dart  # Simple intent dialogs
│       ├── smart_intent_dialog.dart   # Smart intent dialogs
│       ├── connection_dialog.dart     # User connection dialogs
│       ├── match_card_widget.dart     # Match display cards
│       ├── match_card_with_actions.dart # Actionable match cards
│       ├── user_avatar.dart           # Profile photo widget
│       ├── glassmorphic_container.dart # Glassmorphic UI effects
│       ├── optimized_conversation_list.dart # Optimized chat list
│       ├── performance_overlay_widget.dart # Performance overlay
│       └── persistent_keyboard_wrapper.dart # Keyboard persistence
├── test/                              # Test files
│   ├── widget_test.dart               # Widget unit tests
│   └── performance/
│       └── scroll_performance_test.dart # Performance testing
├── project_memory/                    # Project documentation
│   ├── PROJECT_MEMORY.md              # Project development history
│   ├── README.md                      # Project memory documentation
│   └── versions/                      # Version history
├── firebase.json                      # Firebase project configuration
├── firestore.indexes.json            # Firestore database indexes
├── firestore_intents.indexes.json    # Intent-specific indexes
├── cors.json                          # CORS configuration
├── pubspec.yaml                       # Flutter project dependencies
├── analysis_options.yaml             # Dart analyzer configuration
├── README.md                          # Basic project information
├── CLAUDE.md                          # Project requirements and notes
├── DEPLOYMENT_FIXES.md                # Deployment troubleshooting
├── FIREBASE_RULES_DEPLOYMENT.md       # Firebase rules deployment guide
├── FIRESTORE_INDEX_SETUP.md           # Firestore index setup guide
├── FIRESTORE_INDEXES.md               # Firestore indexes documentation
├── firebase_rules.md                  # Firebase security rules
├── PERFORMANCE_TESTING_GUIDE.md       # Performance testing guide
├── SMART_MATCHING_EXPLAINED.md        # Smart matching algorithm explanation
├── WEBRTC_SETUP.md                    # WebRTC setup documentation
└── project_all_workflow.md            # This comprehensive documentation
```

### Key Directory Explanations

#### `/lib` - Main Application Code
The heart of the Flutter application containing all Dart source code organized by function:

- **`models/`**: Data structures representing app entities (User, Post, Message, Conversation)
- **`services/`**: Business logic separated by functionality (25+ specialized services)
- **`screens/`**: Full-screen UI components (20+ different screens)
- **`widgets/`**: Reusable UI components (dialogs, cards, containers)
- **`providers/`**: State management classes using Provider pattern
- **`utils/`**: Helper functions and utilities for optimization and error handling

#### `/android` & `/ios` - Platform-Specific Code
Contains platform-specific configurations, permissions, and native integrations:

- Firebase configuration files
- App icons and launch screens
- Platform permissions and capabilities
- Build configurations for different environments

#### `/web` - Web Platform Support
Web-specific configurations for Progressive Web App functionality:

- Service worker for background message handling
- Web app manifest for PWA features
- HTML entry point with Firebase integration

#### Configuration Files
- **`pubspec.yaml`**: Dependencies, assets, and project metadata
- **`firebase.json`**: Firebase services configuration
- **`firestore.indexes.json`**: Database query optimization indexes
- **`analysis_options.yaml`**: Dart code analysis rules

---

## 4. Code Explanations

### Main Entry Point (`lib/main.dart`)

The app initializes with comprehensive setup for cross-platform compatibility:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // System UI configuration for immersive experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  // Lock to portrait orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Firebase initialization with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Background message handler registration
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Service initialization sequence
  await AppOptimizer.initialize();
  MemoryManager().initialize();
  UserManager().initialize();
  await NotificationService().initialize();
  await ConnectivityService().initialize();

  runApp(const MyApp());
}
```

**Key Components:**

#### MyApp Widget
```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Supper',
            theme: themeProvider.themeData,
            home: const AuthWrapper(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
```

#### AuthWrapper - Authentication State Management
```dart
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData && snapshot.data != null) {
          // Ensure profile exists and initialize services
          ProfileService().ensureProfileExists();
          LocationService().initializeLocation();
          ConversationService().cleanupDuplicateConversations();

          return const MainNavigationScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
```

### Core Data Models

#### AIPostModel (`lib/models/ai_post_model.dart`)
Represents AI-analyzed user posts with comprehensive metadata:

```dart
class AIPostModel {
  final String id;
  final String userId;
  final String originalPrompt;                    // User's natural language input
  final Map<String, dynamic> analysis;           // AI analysis results
  final Map<String, String> clarificationAnswers; // User's Q&A responses
  final List<double> embedding;                   // Vector embedding for semantic matching
  final GeoPoint? location;                       // Geographic coordinates
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> matchedUserIds;             // Users already matched
  final bool isActive;                           // Post visibility status
  final Map<String, dynamic> metadata;          // Additional metadata

  // Constructors, serialization methods, and utilities
  AIPostModel({
    required this.id,
    required this.userId,
    required this.originalPrompt,
    required this.analysis,
    this.clarificationAnswers = const {},
    this.embedding = const [],
    this.location,
    required this.createdAt,
    required this.updatedAt,
    this.matchedUserIds = const [],
    this.isActive = true,
    this.metadata = const {},
  });

  // Factory constructor from Firestore document
  factory AIPostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AIPostModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      originalPrompt: data['originalPrompt'] ?? '',
      analysis: data['analysis'] ?? {},
      clarificationAnswers: Map<String, String>.from(data['clarificationAnswers'] ?? {}),
      embedding: List<double>.from(data['embedding'] ?? []),
      location: data['location'] as GeoPoint?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      matchedUserIds: List<String>.from(data['matchedUserIds'] ?? []),
      isActive: data['isActive'] ?? true,
      metadata: data['metadata'] ?? {},
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'originalPrompt': originalPrompt,
      'analysis': analysis,
      'clarificationAnswers': clarificationAnswers,
      'embedding': embedding,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'matchedUserIds': matchedUserIds,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  // Utility methods
  String get intent => analysis['intent'] ?? 'unknown';
  String get action => analysis['action'] ?? 'unknown';
  Map<String, dynamic> get entities => analysis['entities'] ?? {};
  double get confidence => analysis['confidence']?.toDouble() ?? 0.0;
  bool get needsClarification => analysis['needsClarification'] ?? false;
}
```

#### UserProfile (`lib/models/user_profile.dart`)
Complete user information model with all profile data:

```dart
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final String? location;                        // Human-readable address
  final double? latitude;                        // GPS coordinates
  final double? longitude;
  final bool isOnline;
  final DateTime lastSeen;
  final String? fcmToken;                        // Push notification token
  final String? bio;
  final List<String> interests;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> preferences;        // User preferences
  final Map<String, dynamic> settings;          // App settings
  final int postCount;
  final int matchCount;
  final int conversationCount;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    this.location,
    this.latitude,
    this.longitude,
    this.isOnline = false,
    required this.lastSeen,
    this.fcmToken,
    this.bio,
    this.interests = const [],
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
    this.preferences = const {},
    this.settings = const {},
    this.postCount = 0,
    this.matchCount = 0,
    this.conversationCount = 0,
  });

  // Factory constructors and serialization methods
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      location: data['location'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      isOnline: data['isOnline'] ?? false,
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fcmToken: data['fcmToken'],
      bio: data['bio'],
      interests: List<String>.from(data['interests'] ?? []),
      isVerified: data['isVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      preferences: data['preferences'] ?? {},
      settings: data['settings'] ?? {},
      postCount: data['postCount'] ?? 0,
      matchCount: data['matchCount'] ?? 0,
      conversationCount: data['conversationCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'fcmToken': fcmToken,
      'bio': bio,
      'interests': interests,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'preferences': preferences,
      'settings': settings,
      'postCount': postCount,
      'matchCount': matchCount,
      'conversationCount': conversationCount,
    };
  }

  // Utility methods
  bool get hasLocation => latitude != null && longitude != null;
  bool get hasProfileImage => profileImageUrl != null && profileImageUrl!.isNotEmpty;
  String get displayLocation => location ?? 'Location not set';

  // Calculate distance to another user
  double? distanceTo(UserProfile other) {
    if (!hasLocation || !other.hasLocation) return null;
    return Geolocator.distanceBetween(
      latitude!, longitude!,
      other.latitude!, other.longitude!
    ) / 1000; // Convert to kilometers
  }
}
```

#### ConversationModel (`lib/models/conversation_model.dart`)
Chat conversation structure with participant management:

```dart
class ConversationModel {
  final String id;
  final List<String> participants;               // User IDs in conversation
  final MessageModel? lastMessage;               // Most recent message
  final Map<String, int> unreadCounts;          // Unread count per participant
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;          // Additional conversation data
  final bool isActive;                          // Conversation status

  ConversationModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.unreadCounts = const {},
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
    this.isActive = true,
  });

  // Factory constructor and serialization
  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConversationModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] != null
          ? MessageModel.fromMap(data['lastMessage'])
          : null,
      unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      metadata: data['metadata'] ?? {},
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'lastMessage': lastMessage?.toMap(),
      'unreadCounts': unreadCounts,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
      'isActive': isActive,
    };
  }

  // Utility methods
  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere((id) => id != currentUserId, orElse: () => '');
  }

  int getUnreadCount(String userId) {
    return unreadCounts[userId] ?? 0;
  }

  bool hasUnreadMessages(String userId) {
    return getUnreadCount(userId) > 0;
  }
}
```

#### MessageModel (`lib/models/message_model.dart`)
Individual message structure with status tracking:

```dart
class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final MessageType type;                        // text, image, voice, system
  final DateTime createdAt;
  final MessageStatus status;                    // sent, delivered, read
  final String? imageUrl;                        // For image messages
  final String? voiceUrl;                        // For voice messages
  final Map<String, dynamic> metadata;          // Additional message data

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.type = MessageType.text,
    required this.createdAt,
    this.status = MessageStatus.sent,
    this.imageUrl,
    this.voiceUrl,
    this.metadata = const {},
  });

  // Enums for message types and status
  enum MessageType { text, image, voice, system }
  enum MessageStatus { sent, delivered, read }

  // Factory constructor and serialization
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${data['type']}',
        orElse: () => MessageType.text,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == 'MessageStatus.${data['status']}',
        orElse: () => MessageStatus.sent,
      ),
      imageUrl: data['imageUrl'],
      voiceUrl: data['voiceUrl'],
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'content': content,
      'type': type.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.toString().split('.').last,
      'imageUrl': imageUrl,
      'voiceUrl': voiceUrl,
      'metadata': metadata,
    };
  }

  // Utility methods
  bool get isText => type == MessageType.text;
  bool get isImage => type == MessageType.image;
  bool get isVoice => type == MessageType.voice;
  bool get isSystem => type == MessageType.system;
  bool get isRead => status == MessageStatus.read;
  bool get isDelivered => status == MessageStatus.delivered;
  String get formattedTime => DateFormat('HH:mm').format(createdAt);
}
```

### Service Architecture

#### AI Intent Engine (`lib/services/ai_intent_engine.dart`)
The core AI processing engine using Google Gemini for natural language understanding:

```dart
class AIIntentEngine {
  static final AIIntentEngine _instance = AIIntentEngine._internal();
  factory AIIntentEngine() => _instance;
  AIIntentEngine._internal();

  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: _getApiKey(),
    generationConfig: GenerationConfig(
      temperature: 0.1,
      topK: 1,
      topP: 1,
      maxOutputTokens: 1024,
    ),
  );

  /// Analyzes user input to extract structured intent data
  Future<Map<String, dynamic>> analyzeIntent(String userInput) async {
    try {
      final prompt = _buildAnalysisPrompt(userInput);
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      final responseText = response.text;
      if (responseText == null) {
        throw Exception('No response from AI model');
      }

      return _parseAIResponse(responseText);
    } catch (e) {
      debugPrint('Error analyzing intent: $e');
      return _createErrorResponse(userInput);
    }
  }

  /// Generates vector embedding for semantic matching
  Future<List<double>> generateEmbedding(String text) async {
    try {
      final embeddingModel = GenerativeModel(
        model: 'text-embedding-004',
        apiKey: _getApiKey(),
      );

      final content = [Content.text(text)];
      final response = await embeddingModel.embedContent(content);

      return response.embedding.values;
    } catch (e) {
      debugPrint('Error generating embedding: $e');
      return [];
    }
  }

  /// Suggests clarification questions for ambiguous input
  Future<List<String>> suggestClarifications(String userInput, Map<String, dynamic> analysis) async {
    try {
      final prompt = _buildClarificationPrompt(userInput, analysis);
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      final responseText = response.text;
      if (responseText == null) return [];

      return _parseClarificationQuestions(responseText);
    } catch (e) {
      debugPrint('Error suggesting clarifications: $e');
      return [];
    }
  }

  /// Builds the analysis prompt for intent extraction
  String _buildAnalysisPrompt(String userInput) {
    return '''
Analyze this user request and extract structured intent data: "$userInput"

Return a JSON object with this exact structure:
{
  "intent": "seeking|offering|neutral",
  "action": "buy|sell|find|offer|help|meet|etc",
  "entities": {
    "item": "extracted item/service/person",
    "price": number_or_null,
    "location": "extracted location or null",
    "condition": "extracted condition or null",
    "specifications": ["list", "of", "requirements"]
  },
  "matchCriteria": {
    "mustHave": ["required", "features"],
    "niceToHave": ["preferred", "features"],
    "dealBreakers": ["unacceptable", "features"]
  },
  "confidence": 0.0_to_1.0,
  "needsClarification": true_or_false,
  "clarificationReasons": ["list", "of", "ambiguities"]
}

Examples:
- "iPhone" → needs clarification (buy or sell?)
- "Selling iPhone 15 $800" → clear selling intent
- "Looking for roommate NYC" → seeking intent for housing
- "Lost dog Central Park" → lost/found intent

Be precise and conservative with confidence scores.
''';
  }

  /// Builds clarification prompt for generating questions
  String _buildClarificationPrompt(String userInput, Map<String, dynamic> analysis) {
    final reasons = analysis['clarificationReasons'] as List<dynamic>? ?? [];
    return '''
The user said: "$userInput"
Analysis shows these ambiguities: ${reasons.join(', ')}

Generate 1-3 short, clear questions to resolve the ambiguity.
Format as JSON array: ["Question 1?", "Question 2?"]

Make questions:
- Specific and actionable
- Easy to answer with few words
- Progressive (most important first)
- Conversational tone

Examples:
- For "iPhone": ["Do you want to buy or sell an iPhone?"]
- For "friend": ["Do you want male, female, or anyone as a friend?"]
- For "room": ["Are you looking to rent or offering a room?"]
''';
  }

  /// Parses AI response into structured data
  Map<String, dynamic> _parseAIResponse(String responseText) {
    try {
      // Extract JSON from response
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(responseText);
      if (jsonMatch == null) {
        throw Exception('No JSON found in response');
      }

      final jsonStr = jsonMatch.group(0)!;
      return json.decode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error parsing AI response: $e');
      return _createErrorResponse(responseText);
    }
  }

  /// Parses clarification questions from AI response
  List<String> _parseClarificationQuestions(String responseText) {
    try {
      // Extract JSON array from response
      final jsonMatch = RegExp(r'\[.*\]', dotAll: true).firstMatch(responseText);
      if (jsonMatch == null) return [];

      final jsonStr = jsonMatch.group(0)!;
      final questions = json.decode(jsonStr) as List<dynamic>;
      return questions.map((q) => q.toString()).toList();
    } catch (e) {
      debugPrint('Error parsing clarification questions: $e');
      return [];
    }
  }

  /// Creates error response for failed analysis
  Map<String, dynamic> _createErrorResponse(String input) {
    return {
      'intent': 'unknown',
      'action': 'unknown',
      'entities': {},
      'matchCriteria': {
        'mustHave': [],
        'niceToHave': [],
        'dealBreakers': [],
      },
      'confidence': 0.0,
      'needsClarification': true,
      'clarificationReasons': ['Failed to analyze input'],
      'originalInput': input,
      'error': true,
    };
  }

  String _getApiKey() {
    // In production, use environment variables or secure storage
    return const String.fromEnvironment('GEMINI_API_KEY');
  }
}
```

#### AI Matching Service (`lib/services/ai_matching_service.dart`)
Real-time matching orchestrator with multi-factor scoring:

```dart
class AIMatchingService {
  static final AIMatchingService _instance = AIMatchingService._internal();
  factory AIMatchingService() => _instance;
  AIMatchingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AIIntentEngine _intentEngine = AIIntentEngine();

  /// Finds matches for a given post using multi-factor scoring
  Future<List<Match>> findMatches(AIPostModel userPost) async {
    try {
      final allPosts = await _getAllRelevantPosts(userPost);
      final matches = <Match>[];

      for (final post in allPosts) {
        if (post.userId == userPost.userId) continue; // Skip own posts
        if (userPost.matchedUserIds.contains(post.userId)) continue; // Skip already matched

        final matchScore = await _calculateMatchScore(userPost, post);

        if (matchScore.totalScore > 0.5) { // 50% minimum threshold
          final explanation = await _generateMatchExplanation(userPost, post, matchScore);
          matches.add(Match(
            post: post,
            score: matchScore.totalScore,
            explanation: explanation,
            factors: matchScore.factors,
            createdAt: DateTime.now(),
          ));
        }
      }

      // Sort by score (highest first) and return top matches
      matches.sort((a, b) => b.score.compareTo(a.score));
      return matches.take(20).toList();
    } catch (e) {
      debugPrint('Error finding matches: $e');
      return [];
    }
  }

  /// Calculates comprehensive match score using multiple factors
  Future<MatchScore> _calculateMatchScore(AIPostModel post1, AIPostModel post2) async {
    // Factor 1: AI Compatibility Analysis (40% weight)
    final aiScore = await _calculateAICompatibility(post1, post2);

    // Factor 2: Semantic Similarity (30% weight)
    final semanticScore = _calculateSemanticSimilarity(post1, post2);

    // Factor 3: Location Proximity (15% weight)
    final locationScore = _calculateLocationProximity(post1, post2);

    // Factor 4: Timing Relevance (10% weight)
    final timeScore = _calculateTimeRelevance(post2);

    // Factor 5: Keyword Overlap (5% weight)
    final keywordScore = _calculateKeywordOverlap(post1, post2);

    final totalScore = (aiScore * 0.4) +
                      (semanticScore * 0.3) +
                      (locationScore * 0.15) +
                      (timeScore * 0.1) +
                      (keywordScore * 0.05);

    return MatchScore(
      totalScore: totalScore,
      factors: {
        'aiCompatibility': aiScore,
        'semanticSimilarity': semanticScore,
        'locationProximity': locationScore,
        'timeRelevance': timeScore,
        'keywordOverlap': keywordScore,
      },
    );
  }

  /// Uses AI to determine if two intents are complementary
  Future<double> _calculateAICompatibility(AIPostModel post1, AIPostModel post2) async {
    try {
      final prompt = '''
Analyze if these two user intents are compatible for matching:

User 1: "${post1.originalPrompt}"
Intent: ${post1.intent}, Action: ${post1.analysis['action']}
Entities: ${post1.entities}

User 2: "${post2.originalPrompt}"
Intent: ${post2.intent}, Action: ${post2.analysis['action']}
Entities: ${post2.entities}

Return a compatibility score from 0.0 to 1.0 where:
- 1.0 = Perfect match (buyer/seller, lost/found, etc.)
- 0.8-0.9 = Very compatible
- 0.6-0.7 = Somewhat compatible
- 0.3-0.5 = Weak compatibility
- 0.0-0.2 = Not compatible

Consider:
- Complementary intents (seeking ↔ offering)
- Item/service compatibility
- Price range compatibility
- Location compatibility
- Timing compatibility

Respond with just the score number (e.g., 0.85)
''';

      final content = [Content.text(prompt)];
      final response = await _intentEngine._model.generateContent(content);
      final scoreText = response.text?.trim();

      if (scoreText != null) {
        final score = double.tryParse(scoreText);
        if (score != null && score >= 0.0 && score <= 1.0) {
          return score;
        }
      }

      return 0.0;
    } catch (e) {
      debugPrint('Error calculating AI compatibility: $e');
      return 0.0;
    }
  }

  /// Calculates semantic similarity using vector embeddings
  double _calculateSemanticSimilarity(AIPostModel post1, AIPostModel post2) {
    if (post1.embedding.isEmpty || post2.embedding.isEmpty) return 0.0;

    // Calculate cosine similarity between embeddings
    final dotProduct = _dotProduct(post1.embedding, post2.embedding);
    final magnitude1 = _magnitude(post1.embedding);
    final magnitude2 = _magnitude(post2.embedding);

    if (magnitude1 == 0.0 || magnitude2 == 0.0) return 0.0;

    final cosineSimilarity = dotProduct / (magnitude1 * magnitude2);
    return math.max(0.0, cosineSimilarity); // Ensure non-negative
  }

  /// Calculates location-based proximity score
  double _calculateLocationProximity(AIPostModel post1, AIPostModel post2) {
    if (post1.location == null || post2.location == null) return 0.5; // Neutral if no location

    final distance = Geolocator.distanceBetween(
      post1.location!.latitude,
      post1.location!.longitude,
      post2.location!.latitude,
      post2.location!.longitude,
    ) / 1000; // Convert to kilometers

    // Score based on distance (closer = higher score)
    if (distance <= 1) return 1.0;        // Within 1km
    if (distance <= 5) return 0.9;        // Within 5km
    if (distance <= 10) return 0.8;       // Within 10km
    if (distance <= 25) return 0.6;       // Within 25km
    if (distance <= 50) return 0.4;       // Within 50km
    if (distance <= 100) return 0.2;      // Within 100km
    return 0.0;                           // Beyond 100km
  }

  /// Calculates time-based relevance score
  double _calculateTimeRelevance(AIPostModel post) {
    final now = DateTime.now();
    final hoursSincePost = now.difference(post.createdAt).inHours;

    // Score based on recency (newer = higher score)
    if (hoursSincePost <= 1) return 1.0;     // Within 1 hour
    if (hoursSincePost <= 6) return 0.9;     // Within 6 hours
    if (hoursSincePost <= 24) return 0.8;    // Within 1 day
    if (hoursSincePost <= 72) return 0.6;    // Within 3 days
    if (hoursSincePost <= 168) return 0.4;   // Within 1 week
    if (hoursSincePost <= 720) return 0.2;   // Within 1 month
    return 0.1;                              // Older than 1 month
  }

  /// Calculates keyword overlap using Jaccard similarity
  double _calculateKeywordOverlap(AIPostModel post1, AIPostModel post2) {
    final keywords1 = _extractKeywords(post1.originalPrompt);
    final keywords2 = _extractKeywords(post2.originalPrompt);

    final intersection = keywords1.intersection(keywords2);
    final union = keywords1.union(keywords2);

    if (union.isEmpty) return 0.0;
    return intersection.length / union.length;
  }

  /// Extracts keywords from text for overlap calculation
  Set<String> _extractKeywords(String text) {
    final words = text.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 3) // Filter short words
        .toSet();

    // Remove common stop words
    final stopWords = {'with', 'have', 'this', 'that', 'they', 'them', 'their', 'what', 'when', 'where', 'who', 'why', 'how'};
    return words.difference(stopWords);
  }

  /// Helper functions for vector operations
  double _dotProduct(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;
    double sum = 0.0;
    for (int i = 0; i < a.length; i++) {
      sum += a[i] * b[i];
    }
    return sum;
  }

  double _magnitude(List<double> vector) {
    double sum = 0.0;
    for (final value in vector) {
      sum += value * value;
    }
    return math.sqrt(sum);
  }

  /// Generates human-readable explanation for why users matched
  Future<String> _generateMatchExplanation(AIPostModel post1, AIPostModel post2, MatchScore score) async {
    try {
      final prompt = '''
Generate a brief, friendly explanation for why these two users matched:

User 1: "${post1.originalPrompt}"
User 2: "${post2.originalPrompt}"

Match factors:
- AI Compatibility: ${(score.factors['aiCompatibility']! * 100).round()}%
- Semantic Similarity: ${(score.factors['semanticSimilarity']! * 100).round()}%
- Location Proximity: ${(score.factors['locationProximity']! * 100).round()}%

Write 1-2 sentences explaining why they're a good match.
Use friendly, conversational language.
Focus on the main compatibility factor.

Examples:
- "You both are interested in iPhones - they're selling and you're looking to buy!"
- "Perfect match! You're both looking for tennis partners in the same area."
- "Great news - they found a golden retriever that matches your lost dog description."
''';

      final content = [Content.text(prompt)];
      final response = await _intentEngine._model.generateContent(content);
      return response.text?.trim() ?? 'You both have complementary interests!';
    } catch (e) {
      debugPrint('Error generating match explanation: $e');
      return 'You both have complementary interests!';
    }
  }

  /// Gets all relevant posts for matching
  Future<List<AIPostModel>> _getAllRelevantPosts(AIPostModel userPost) async {
    try {
      // Query posts that are active and not from the same user
      final query = _firestore
          .collection('ai_posts')
          .where('isActive', isEqualTo: true)
          .where('userId', isNotEqualTo: userPost.userId)
          .orderBy('createdAt', descending: true)
          .limit(100); // Limit for performance

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => AIPostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting relevant posts: $e');
      return [];
    }
  }

  /// Processes new posts for real-time matching
  Future<void> processNewPost(AIPostModel newPost) async {
    try {
      final matches = await findMatches(newPost);

      for (final match in matches) {
        // Send notification for high-score matches
        if (match.score > 0.8) {
          await _sendMatchNotification(newPost.userId, match);
        }

        // Update match records
        await _saveMatchRecord(newPost.userId, match);
      }
    } catch (e) {
      debugPrint('Error processing new post: $e');
    }
  }

  /// Sends push notification for new matches
  Future<void> _sendMatchNotification(String userId, Match match) async {
    try {
      final notificationService = NotificationService();
      await notificationService.sendMatchNotification(
        userId: userId,
        matchedUserId: match.post.userId,
        explanation: match.explanation,
      );
    } catch (e) {
      debugPrint('Error sending match notification: $e');
    }
  }

  /// Saves match record to database
  Future<void> _saveMatchRecord(String userId, Match match) async {
    try {
      await _firestore.collection('matches').add({
        'userId': userId,
        'matchedUserId': match.post.userId,
        'matchedPostId': match.post.id,
        'score': match.score,
        'explanation': match.explanation,
        'factors': match.factors,
        'createdAt': Timestamp.fromDate(match.createdAt),
        'status': 'pending', // pending, contacted, ignored
      });
    } catch (e) {
      debugPrint('Error saving match record: $e');
    }
  }
}

/// Data class for match scoring results
class MatchScore {
  final double totalScore;
  final Map<String, double> factors;

  MatchScore({
    required this.totalScore,
    required this.factors,
  });
}

/// Data class for match results
class Match {
  final AIPostModel post;
  final double score;
  final String explanation;
  final Map<String, double> factors;
  final DateTime createdAt;

  Match({
    required this.post,
    required this.score,
    required this.explanation,
    required this.factors,
    required this.createdAt,
  });
}
```

### State Management (Provider Pattern)

#### Theme Provider (`lib/providers/theme_provider.dart`)
Comprehensive theme management with dark/light mode support:

```dart
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  Color _primaryColor = Colors.blue;
  String _fontFamily = 'System';

  // Getters
  bool get isDarkMode => _isDarkMode;
  Color get primaryColor => _primaryColor;
  String get fontFamily => _fontFamily;

  ThemeData get themeData => _isDarkMode ? _darkTheme : _lightTheme;

  // Light theme configuration
  ThemeData get _lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primarySwatch: MaterialColor(
      _primaryColor.value,
      _generateMaterialColor(_primaryColor),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.light,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      centerTitle: true,
    ),
    cardTheme: CardTheme(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    fontFamily: _fontFamily == 'System' ? null : _fontFamily,
  );

  // Dark theme configuration
  ThemeData get _darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primarySwatch: MaterialColor(
      _primaryColor.value,
      _generateMaterialColor(_primaryColor),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 2,
      centerTitle: true,
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF1E1E1E),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    fontFamily: _fontFamily == 'System' ? null : _fontFamily,
  );

  // Toggle between light and dark mode
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveThemePreference();
    notifyListeners();
  }

  // Set specific theme mode
  void setThemeMode(bool isDark) {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      _saveThemePreference();
      notifyListeners();
    }
  }

  // Change primary color
  void setPrimaryColor(Color color) {
    _primaryColor = color;
    _saveThemePreference();
    notifyListeners();
  }

  // Change font family
  void setFontFamily(String fontFamily) {
    _fontFamily = fontFamily;
    _saveThemePreference();
    notifyListeners();
  }

  // Load theme preferences from storage
  Future<void> loadThemePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;

    final primaryColorValue = prefs.getInt('primaryColor');
    if (primaryColorValue != null) {
      _primaryColor = Color(primaryColorValue);
    }

    _fontFamily = prefs.getString('fontFamily') ?? 'System';
    notifyListeners();
  }

  // Save theme preferences to storage
  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setInt('primaryColor', _primaryColor.value);
    await prefs.setString('fontFamily', _fontFamily);
  }

  // Generate material color swatch from single color
  Map<int, Color> _generateMaterialColor(Color color) {
    return {
      50: _lighten(color, 0.9),
      100: _lighten(color, 0.8),
      200: _lighten(color, 0.6),
      300: _lighten(color, 0.4),
      400: _lighten(color, 0.2),
      500: color,
      600: _darken(color, 0.1),
      700: _darken(color, 0.2),
      800: _darken(color, 0.3),
      900: _darken(color, 0.4),
    };
  }

  Color _lighten(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  Color _darken(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}
```

### Screen Components

#### Universal Matching Screen (`lib/screens/universal_matching_screen.dart`)
The main interface for universal search and intent processing:

```dart
class UniversalMatchingScreen extends StatefulWidget {
  @override
  State<UniversalMatchingScreen> createState() => _UniversalMatchingScreenState();
}

class _UniversalMatchingScreenState extends State<UniversalMatchingScreen> {
  final UniversalIntentService _intentService = UniversalIntentService();
  final UnifiedIntentProcessor _unifiedProcessor = UnifiedIntentProcessor();
  final SequentialClarificationService _sequentialClarification = SequentialClarificationService();
  final RealtimeMatchingService _realtimeService = RealtimeMatchingService();
  final TextEditingController _intentController = TextEditingController();

  bool _isProcessing = false;
  List<Map<String, dynamic>> _matches = [];
  List<Map<String, dynamic>> _userIntents = [];
  Map<String, dynamic>? _currentIntent;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserIntents();
    _loadUserProfile();
    _realtimeService.initialize();
  }

  Future<void> _processIntent() async {
    final intent = _intentController.text.trim();
    if (intent.isEmpty) {
      setState(() {
        _errorMessage = 'Please describe what you\'re looking for';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isProcessing = true;
    });

    try {
      // Step 1: Extract entities from user input
      final extractedData = await _sequentialClarification.extractEntities(intent);

      // Step 2: Check if clarification is needed
      if (extractedData['needsClarification'] == true) {
        await _showClarificationDialog(extractedData);
      } else {
        // Step 3: Process intent and find matches
        await _processCompleteIntent(extractedData);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error processing intent: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _showClarificationDialog(Map<String, dynamic> extractedData) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => SequentialClarificationDialog(
        extractedData: extractedData,
        clarificationService: _sequentialClarification,
      ),
    );

    if (result != null) {
      // Process with clarified data
      final clarifiedData = {
        ...extractedData,
        'clarificationAnswers': result,
      };
      await _processCompleteIntent(clarifiedData);
    }
  }

  Future<void> _processCompleteIntent(Map<String, dynamic> intentData) async {
    try {
      // Create post and find matches
      final matches = await _unifiedProcessor.processAndMatch(
        originalPrompt: _intentController.text.trim(),
        extractedData: intentData,
      );

      setState(() {
        _matches = matches;
        _currentIntent = intentData;
      });

      // Clear input after successful processing
      _intentController.clear();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error finding matches: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find Anything'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Input Section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _intentController,
                  decoration: InputDecoration(
                    hintText: 'What are you looking for?',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: (_) => _processIntent(),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processIntent,
                    child: _isProcessing
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 8),
                              Text('Processing...'),
                            ],
                          )
                        : Text('Find Matches'),
                  ),
                ),
              ],
            ),
          ),

          // Error Display
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            ),

          // Matches List
          Expanded(
            child: _matches.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No matches yet',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          'Describe what you\'re looking for',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _matches.length,
                    itemBuilder: (context, index) {
                      final match = _matches[index];
                      return MatchCardWithActions(
                        match: match,
                        onTap: () => _handleMatchTap(match),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _handleMatchTap(Map<String, dynamic> match) {
    // Navigate to chat or profile based on user preference
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedChatScreen(
          otherUserId: match['userId'],
          otherUserName: match['userName'],
          otherUserPhotoUrl: match['userProfile']?['photoUrl'],
        ),
      ),
    );
  }
}
```

#### Conversation Service (`lib/services/conversation_service.dart`)
Manages chat conversations and message handling:

```dart
class ConversationService {
  static final ConversationService _instance = ConversationService._internal();
  factory ConversationService() => _instance;
  ConversationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Generate consistent conversation ID between two users
  String generateConversationId(String userId1, String userId2) {
    // Always sort user IDs to ensure consistency
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  /// Get or create conversation between current user and another user
  Future<String> getOrCreateConversation(UserProfile otherUser) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('No authenticated user');
    }

    final conversationId = generateConversationId(currentUserId, otherUser.id);

    try {
      // First, try to get existing conversation
      final conversationDoc = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();

      if (conversationDoc.exists) {
        // Conversation exists, update participant info if needed
        await _updateParticipantInfo(conversationId, currentUserId, otherUser);
        return conversationId;
      }

      // Conversation doesn't exist, create it
      await _createConversation(conversationId, currentUserId, otherUser);
      return conversationId;
    } catch (e) {
      throw Exception('Failed to get or create conversation: $e');
    }
  }

  /// Create a new conversation
  Future<void> _createConversation(
    String conversationId,
    String currentUserId,
    UserProfile otherUser,
  ) async {
    final currentUserDoc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .get();

    final currentUserData = currentUserDoc.data() ?? {};
    final currentUserName = currentUserData['name'] ??
                            _auth.currentUser?.displayName ??
                            'User';
    final currentUserPhoto = currentUserData['photoUrl'] ??
                            _auth.currentUser?.photoURL;

    await _firestore.collection('conversations').doc(conversationId).set({
      'id': conversationId,
      'participantIds': [currentUserId, otherUser.id],
      'participantNames': {
        currentUserId: currentUserName,
        otherUser.id: otherUser.name,
      },
      'participantPhotos': {
        currentUserId: currentUserPhoto,
        otherUser.id: otherUser.profileImageUrl,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessageTime': null,
      'lastMessage': null,
      'lastMessageSenderId': null,
      'unreadCount': {
        currentUserId: 0,
        otherUser.id: 0,
      },
      'isTyping': {
        currentUserId: false,
        otherUser.id: false,
      },
      'isGroup': false,
      'lastSeen': {
        currentUserId: FieldValue.serverTimestamp(),
        otherUser.id: null,
      },
      'isArchived': false,
    });
  }

  /// Send a message in a conversation
  Future<void> sendMessage({
    required String conversationId,
    required String content,
    required String type,
    String? imageUrl,
    String? voiceUrl,
  }) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('No authenticated user');
    }

    try {
      final messageId = _firestore.collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc()
          .id;

      final messageData = {
        'id': messageId,
        'senderId': currentUserId,
        'content': content,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'sent',
        'imageUrl': imageUrl,
        'voiceUrl': voiceUrl,
        'metadata': {},
      };

      // Add message to subcollection
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .set(messageData);

      // Update conversation with last message info
      await _updateConversationLastMessage(conversationId, messageData);

      // Send push notification to other participant
      await _sendMessageNotification(conversationId, content, currentUserId);

    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Update conversation with last message information
  Future<void> _updateConversationLastMessage(
    String conversationId,
    Map<String, dynamic> messageData,
  ) async {
    final conversationRef = _firestore
        .collection('conversations')
        .doc(conversationId);

    final conversationDoc = await conversationRef.get();
    final conversationData = conversationDoc.data() ?? {};
    final participantIds = List<String>.from(conversationData['participantIds'] ?? []);
    final currentUserId = _auth.currentUser?.uid;

    if (currentUserId == null) return;

    // Update unread counts for other participants
    final unreadCount = Map<String, dynamic>.from(conversationData['unreadCount'] ?? {});
    for (final participantId in participantIds) {
      if (participantId != currentUserId) {
        unreadCount[participantId] = (unreadCount[participantId] ?? 0) + 1;
      }
    }

    await conversationRef.update({
      'lastMessage': messageData['content'],
      'lastMessageTime': messageData['createdAt'],
      'lastMessageSenderId': currentUserId,
      'unreadCount': unreadCount,
    });
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      // Reset unread count for current user
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .update({
        'unreadCount.$currentUserId': 0,
        'lastSeen.$currentUserId': FieldValue.serverTimestamp(),
      });

      // Update message statuses to 'read' for messages from other users
      final messagesQuery = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId)
          .where('status', isNotEqualTo: 'read')
          .get();

      final batch = _firestore.batch();
      for (final doc in messagesQuery.docs) {
        batch.update(doc.reference, {'status': 'read'});
      }
      await batch.commit();

    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  /// Get conversation stream for real-time updates
  Stream<DocumentSnapshot> getConversationStream(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .snapshots();
  }

  /// Get messages stream for real-time chat
  Stream<QuerySnapshot> getMessagesStream(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Send push notification for new message
  Future<void> _sendMessageNotification(
    String conversationId,
    String content,
    String senderId,
  ) async {
    try {
      final notificationService = NotificationService();
      await notificationService.sendMessageNotification(
        conversationId: conversationId,
        content: content,
        senderId: senderId,
      );
    } catch (e) {
      debugPrint('Error sending message notification: $e');
    }
  }

  /// Clean up duplicate conversations (maintenance function)
  Future<void> cleanupDuplicateConversations() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final conversations = await _firestore
          .collection('conversations')
          .where('participantIds', arrayContains: currentUserId)
          .get();

      final groupedConversations = <String, List<DocumentSnapshot>>{};

      // Group conversations by participant pairs
      for (final doc in conversations.docs) {
        final data = doc.data();
        final participantIds = List<String>.from(data['participantIds'] ?? []);
        participantIds.sort();
        final key = participantIds.join('_');

        if (!groupedConversations.containsKey(key)) {
          groupedConversations[key] = [];
        }
        groupedConversations[key]!.add(doc);
      }

      // Remove duplicates (keep the most recent one)
      for (final group in groupedConversations.values) {
        if (group.length > 1) {
          group.sort((a, b) {
            final aTime = a.data()['createdAt'] as Timestamp?;
            final bTime = b.data()['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          // Delete all but the first (most recent)
          for (int i = 1; i < group.length; i++) {
            await group[i].reference.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up duplicate conversations: $e');
    }
  }
}
```

### Widget Components

#### Match Card with Actions (`lib/widgets/match_card_with_actions.dart`)
Displays match results with interaction options:

```dart
class MatchCardWithActions extends StatelessWidget {
  final Map<String, dynamic> match;
  final VoidCallback? onTap;

  const MatchCardWithActions({
    Key? key,
    required this.match,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isDark ? 8 : 4,
      shadowColor: theme.primaryColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap ?? () => _viewProfile(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isDark
                ? LinearGradient(
                    colors: [
                      theme.cardColor,
                      theme.cardColor.withOpacity(0.95),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Row
              Row(
                children: [
                  // Avatar
                  Hero(
                    tag: 'avatar_${match['userId']}',
                    child: CircleAvatar(
                      radius: 28,
                      backgroundImage: match['userProfile']?['photoUrl'] != null
                          ? CachedNetworkImageProvider(match['userProfile']['photoUrl'])
                          : null,
                      child: match['userProfile']?['photoUrl'] == null
                          ? Icon(Icons.person, size: 28)
                          : null,
                    ),
                  ),
                  SizedBox(width: 12),

                  // Name and Location
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match['userName'] ?? 'User',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (match['userLocation'] != null)
                          Text(
                            match['userLocation'],
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Match Score Badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getScoreColor(match['score'] ?? 0.0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${((match['score'] ?? 0.0) * 100).round()}%',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Original Intent
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  match['originalPrompt'] ?? 'No description available',
                  style: theme.textTheme.bodyMedium,
                ),
              ),

              SizedBox(height: 12),

              // Match Explanation
              if (match['explanation'] != null)
                Text(
                  match['explanation'],
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),

              SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _startChat(context),
                      icon: Icon(Icons.chat, size: 18),
                      label: Text('Chat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewProfile(context),
                      icon: Icon(Icons.person, size: 18),
                      label: Text('Profile'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  void _startChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedChatScreen(
          otherUserId: match['userId'],
          otherUserName: match['userName'],
          otherUserPhotoUrl: match['userProfile']?['photoUrl'],
        ),
      ),
    );
  }

  void _viewProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileViewScreen(
          userId: match['userId'],
        ),
      ),
    );
  }
}
```

---

## 5. Features & Workflows

### Core Features Overview

1. **Universal Search & Intent Processing**
2. **AI-Powered Clarification System**
3. **Real-Time Intelligent Matching**
4. **Instant Communication (Chat + Voice)**
5. **Location-Aware Matching**
6. **Profile Management & Discovery**

---

### Feature 1: Universal Search & Intent Processing

**Files Involved:**
- `lib/screens/universal_matching_screen.dart`
- `lib/services/universal_intent_service.dart`
- `lib/services/ai_intent_engine.dart`
- `lib/services/unified_intent_processor.dart`

**User Workflow:**

1. **User Opens App** → Main navigation shows "Find Anything" tab
2. **User Types Natural Language** → "iPhone", "tennis partner", "lost dog", etc.
3. **System Processes Input** → AI Intent Engine analyzes text
4. **AI Extracts Structured Data** → Intent, entities, confidence score
5. **Decision Point:**
   - If clear intent → Proceed to matching
   - If ambiguous → Trigger clarification workflow
6. **Post Creation** → Save structured intent to database
7. **Real-time Matching** → Find compatible users immediately
8. **Display Results** → Show matches with explanations

**Technical Implementation Flow:**

```
User Input: "iPhone"
    ↓
AIIntentEngine.analyzeIntent()
    ↓
{
  "intent": "unknown",
  "entities": {"item": "iPhone"},
  "confidence": 0.3,
  "needsClarification": true,
  "clarificationReasons": ["Unclear if buying or selling"]
}
    ↓
Show clarification dialog: "Do you want to buy or sell an iPhone?"
    ↓
User answers: "Sell"
    ↓
Complete intent: {
  "intent": "offering",
  "action": "sell",
  "entities": {"item": "iPhone"},
  "confidence": 0.95
}
    ↓
Create AIPostModel and find matches
```

**UI/UX Flow:**

1. **Search Interface:**
   - Large search bar with placeholder "What are you looking for?"
   - Search icon and voice input option
   - Submit button with loading state

2. **Processing State:**
   - Loading spinner with "Processing..." text
   - Progress indicator for AI analysis

3. **Results Display:**
   - Match cards with user photos and descriptions
   - Match percentage badges
   - Quick action buttons (Chat, View Profile)

---

### Feature 2: AI-Powered Clarification System

**Files Involved:**
- `lib/widgets/sequential_clarification_dialog.dart`
- `lib/services/sequential_clarification_service.dart`
- `lib/widgets/conversational_clarification_dialog.dart`

**User Workflow:**

1. **Ambiguous Input Detected** → AI confidence < 70%
2. **Generate Questions** → AI creates contextual questions
3. **Sequential Q&A** → One question at a time for better UX
4. **Progressive Refinement** → Each answer narrows down intent
5. **Completion** → When sufficient clarity achieved
6. **Final Processing** → Create post with clarified intent

**Clarification Examples:**

**Example 1: Marketplace Item**
```
User: "iPhone"
System: "Do you want to buy or sell an iPhone?"
User: "Sell"
System: "What's your asking price?"
User: "$800"
System: "Any specific model or condition?"
User: "iPhone 15, excellent condition"
→ Complete intent created
```

**Example 2: Social Connection**
```
User: "Looking for a friend"
System: "Do you prefer male, female, or anyone as a friend?"
User: "Female"
System: "What age range are you looking for?"
User: "25-35"
System: "Any specific interests or activities?"
User: "Hiking, coffee, books"
→ Complete intent created
```

**Technical Implementation:**

```dart
class SequentialClarificationDialog extends StatefulWidget {
  final Map<String, dynamic> extractedData;
  final SequentialClarificationService clarificationService;

  @override
  _SequentialClarificationDialogState createState() => _SequentialClarificationDialogState();
}

class _SequentialClarificationDialogState extends State<SequentialClarificationDialog> {
  int _currentQuestionIndex = 0;
  Map<String, String> _answers = {};
  List<String> _questions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() { _isLoading = true; });

    final questions = await widget.clarificationService.generateQuestions(
      widget.extractedData
    );

    setState(() {
      _questions = questions;
      _isLoading = false;
    });
  }

  void _answerQuestion(String answer) {
    setState(() {
      _answers[_questions[_currentQuestionIndex]] = answer;
      _currentQuestionIndex++;
    });

    if (_currentQuestionIndex >= _questions.length) {
      // All questions answered
      Navigator.of(context).pop(_answers);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _questions.isEmpty) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating questions...'),
          ],
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];

    return AlertDialog(
      title: Text('Quick Question'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(currentQuestion),
          SizedBox(height: 16),
          // Dynamic answer options based on question type
          ..._buildAnswerOptions(currentQuestion),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
      ],
    );
  }

  List<Widget> _buildAnswerOptions(String question) {
    // Generate appropriate input widgets based on question type
    if (question.contains('buy or sell')) {
      return [
        ElevatedButton(
          onPressed: () => _answerQuestion('buy'),
          child: Text('Buy'),
        ),
        ElevatedButton(
          onPressed: () => _answerQuestion('sell'),
          child: Text('Sell'),
        ),
      ];
    } else if (question.contains('male, female')) {
      return [
        ElevatedButton(
          onPressed: () => _answerQuestion('male'),
          child: Text('Male'),
        ),
        ElevatedButton(
          onPressed: () => _answerQuestion('female'),
          child: Text('Female'),
        ),
        ElevatedButton(
          onPressed: () => _answerQuestion('anyone'),
          child: Text('Anyone'),
        ),
      ];
    } else {
      // Text input for open-ended questions
      return [
        TextField(
          decoration: InputDecoration(hintText: 'Your answer...'),
          onSubmitted: _answerQuestion,
        ),
      ];
    }
  }
}
```

---

### Feature 3: Real-Time Intelligent Matching

**Files Involved:**
- `lib/services/ai_matching_service.dart`
- `lib/services/realtime_matching_service.dart`
- `lib/screens/ai_matching_screen.dart`

**Matching Algorithm Components:**

1. **AI Compatibility Analysis (40% weight)**
   - Uses Gemini AI to determine intent compatibility
   - Checks for complementary intents (buyer ↔ seller)
   - Considers item/service compatibility

2. **Semantic Similarity (30% weight)**
   - Cosine similarity of text embeddings
   - Measures conceptual similarity between posts

3. **Location Proximity (15% weight)**
   - Haversine distance calculation
   - Proximity bonus for nearby users

4. **Timing Relevance (10% weight)**
   - Recency bonus for newer posts
   - Decay function for older posts

5. **Keyword Overlap (5% weight)**
   - Jaccard similarity of extracted keywords
   - Direct text matching bonus

**Real-Time Processing Workflow:**

```
New Post Created
    ↓
Firestore Trigger
    ↓
RealtimeMatchingService.processNewPost()
    ↓
For each relevant existing post:
    ↓
Calculate multi-factor score
    ↓
If score > 50%: Create match record
    ↓
If score > 80%: Send push notification
    ↓
Update UI with new matches
```

**Matching Score Calculation:**

```dart
Future<MatchScore> calculateMatchScore(AIPostModel post1, AIPostModel post2) async {
  // Factor 1: AI Compatibility (40%)
  final aiScore = await _calculateAICompatibility(post1, post2);

  // Factor 2: Semantic Similarity (30%)
  final semanticScore = _calculateSemanticSimilarity(post1, post2);

  // Factor 3: Location Proximity (15%)
  final locationScore = _calculateLocationProximity(post1, post2);

  // Factor 4: Timing Relevance (10%)
  final timeScore = _calculateTimeRelevance(post2);

  // Factor 5: Keyword Overlap (5%)
  final keywordScore = _calculateKeywordOverlap(post1, post2);

  final totalScore = (aiScore * 0.4) +
                    (semanticScore * 0.3) +
                    (locationScore * 0.15) +
                    (timeScore * 0.1) +
                    (keywordScore * 0.05);

  return MatchScore(
    totalScore: totalScore,
    factors: {
      'aiCompatibility': aiScore,
      'semanticSimilarity': semanticScore,
      'locationProximity': locationScore,
      'timeRelevance': timeScore,
      'keywordOverlap': keywordScore,
    },
  );
}
```

**User Experience:**

1. **Instant Results** → Matches appear within seconds of posting
2. **Push Notifications** → High-quality matches (>80%) trigger notifications
3. **Match Explanations** → AI-generated explanations for why users matched
4. **Real-time Updates** → Match list updates as new relevant posts are created
5. **Quality Scoring** → Visual indicators showing match confidence

---

### Feature 4: Instant Communication System

**Files Involved:**
- `lib/services/conversation_service.dart`
- `lib/screens/enhanced_chat_screen.dart`
- `lib/models/conversation_model.dart`
- `lib/models/message_model.dart`

**Communication Workflow:**

1. **Match Selection** → User taps "Chat" on match card
2. **Conversation Creation** → System creates or finds existing conversation
3. **Real-time Chat** → WebSocket-like real-time messaging via Firestore
4. **Message Status** → Sent, delivered, read indicators
5. **Push Notifications** → Background message notifications
6. **Voice Calling** → Direct voice calls between matched users

**Chat Features:**

- **Real-time messaging** with typing indicators
- **Message status tracking** (sent, delivered, read)
- **Image sharing** with camera/gallery integration
- **Voice messages** (future enhancement)
- **Message history** with pagination
- **Conversation list** with unread counts
- **Push notifications** for new messages

**Voice Calling Implementation:**

*Note: The project documentation indicates voice calling is implemented but video calling is explicitly excluded per requirements.*

**Technical Implementation:**

```dart
class EnhancedChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoUrl;

  @override
  _EnhancedChatScreenState createState() => _EnhancedChatScreenState();
}

class _EnhancedChatScreenState extends State<EnhancedChatScreen> {
  final ConversationService _conversationService = ConversationService();
  final TextEditingController _messageController = TextEditingController();

  String? _conversationId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeConversation();
  }

  Future<void> _initializeConversation() async {
    try {
      final otherUser = UserProfile(
        id: widget.otherUserId,
        name: widget.otherUserName,
        email: '', // Will be fetched if needed
        profileImageUrl: widget.otherUserPhotoUrl,
      );

      final conversationId = await _conversationService.getOrCreateConversation(otherUser);

      setState(() {
        _conversationId = conversationId;
        _isLoading = false;
      });

      // Mark messages as read
      await _conversationService.markMessagesAsRead(conversationId);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing chat: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _conversationId == null) return;

    _messageController.clear();

    try {
      await _conversationService.sendMessage(
        conversationId: _conversationId!,
        content: content,
        type: 'text',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Loading...')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.otherUserPhotoUrl != null
                  ? NetworkImage(widget.otherUserPhotoUrl!)
                  : null,
              child: widget.otherUserPhotoUrl == null
                  ? Icon(Icons.person, size: 16)
                  : null,
            ),
            SizedBox(width: 8),
            Text(widget.otherUserName),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.phone),
            onPressed: _initiateVoiceCall,
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _conversationId != null
                ? StreamBuilder<QuerySnapshot>(
                    stream: _conversationService.getMessagesStream(_conversationId!),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final messages = snapshot.data!.docs;

                      return ListView.builder(
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final messageDoc = messages[index];
                          final messageData = messageDoc.data() as Map<String, dynamic>;

                          return _buildMessageBubble(messageData);
                        },
                      );
                    },
                  )
                : Center(child: Text('Unable to load messages')),
          ),

          // Message Input
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: Icon(Icons.send),
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> messageData) {
    final isMe = messageData['senderId'] == FirebaseAuth.instance.currentUser?.uid;
    final content = messageData['content'] ?? '';
    final timestamp = messageData['createdAt'] as Timestamp?;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).primaryColor
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content,
              style: TextStyle(
                color: isMe ? Colors.white : null,
              ),
            ),
            if (timestamp != null)
              Text(
                _formatTime(timestamp.toDate()),
                style: TextStyle(
                  fontSize: 12,
                  color: isMe ? Colors.white70 : Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _initiateVoiceCall() {
    // Voice calling implementation
    // Note: Video calling is explicitly excluded per project requirements
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Voice Call'),
        content: Text('Initiating voice call with ${widget.otherUserName}...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
```

---

### Feature 5: Location-Aware Matching

**Files Involved:**
- `lib/services/location_service.dart`
- `lib/services/geocoding_service.dart`

**Location Features:**

1. **GPS Location Detection** → Automatic current location detection
2. **Permission Management** → Proper location permission handling
3. **Geocoding** → Convert addresses to coordinates and vice versa
4. **Distance Calculation** → Haversine formula for accurate distance
5. **Proximity Matching** → Location factor in matching algorithm
6. **Privacy Controls** → Optional location sharing

**Location Workflow:**

1. **App Launch** → Request location permission if not granted
2. **Background Location** → Periodically update user location
3. **Post Creation** → Attach location data to posts
4. **Matching** → Factor distance into compatibility score
5. **Display** → Show approximate distance in match cards

**Technical Implementation:**

```dart
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _currentPosition;
  String? _currentAddress;

  Future<void> initializeLocation() async {
    final permission = await _checkLocationPermission();
    if (permission == LocationPermission.granted) {
      await _getCurrentLocation();
    }
  }

  Future<LocationPermission> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      );

      _currentPosition = position;

      // Get human-readable address
      _currentAddress = await _getAddressFromPosition(position);

      // Update user profile with location
      await _updateUserLocation(position, _currentAddress);

      return position;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  Future<String?> _getAddressFromPosition(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return '${placemark.locality}, ${placemark.administrativeArea}';
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
    }
    return null;
  }

  Future<void> _updateUserLocation(Position position, String? address) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'location': address,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating user location: $e');
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // km
  }

  // Getters
  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  bool get hasLocation => _currentPosition != null;
}
```

---

### Feature 6: Profile Management

**Files Involved:**
- `lib/services/profile_service.dart`
- `lib/screens/profile_edit_screen.dart`
- `lib/screens/profile_screen.dart`
- `lib/screens/profile_view_screen.dart`

**Profile Features:**

1. **Auto Profile Creation** → Profile created on first login
2. **Photo Upload** → Camera/gallery integration with optimization
3. **Bio and Interests** → Rich profile information
4. **Post History** → View user's previous posts and matches
5. **Settings Management** → Privacy and notification preferences
6. **Verification Status** → User verification badges

**Profile Management Workflow:**

1. **First Login** → Auto-create basic profile from auth data
2. **Profile Completion** → Prompt user to complete profile
3. **Photo Upload** → Optimized image upload to Firebase Storage
4. **Information Update** → Real-time profile updates
5. **Privacy Settings** → Control visibility and data sharing

---

## 6. Data Flow

### High-Level Data Architecture

```
User Input → AI Analysis → Intent Extraction → Clarification (if needed) →
Post Creation → Real-Time Matching → Notification → Communication
```

### Detailed Data Flow Diagrams

#### 1. User Input Processing Flow

```
UniversalMatchingScreen
    ↓ (user types input)
UniversalIntentService.processUserInput()
    ↓
AIIntentEngine.analyzeIntent()
    ↓ (HTTP request to Google Gemini API)
Gemini AI Response
    ↓ (parse structured JSON)
{
  intent: "seeking",
  action: "buy",
  entities: { item: "iPhone", budget: 500 },
  confidence: 0.85,
  needsClarification: false
}
    ↓ (if confidence < 0.7)
Sequential Clarification Service
    ↓ (show dialog with questions)
User Answers Questions
    ↓ (merge answers with initial analysis)
Complete Intent Data
    ↓
Create AIPostModel
    ↓ (save to Firestore)
Collection: "ai_posts"
```

#### 2. Real-Time Matching Process Flow

```
Firestore Listener (ai_posts collection)
    ↓ (new document detected)
RealtimeMatchingService.processNewPost()
    ↓ (query existing posts)
For each relevant post:
    ↓
AIMatchingService.calculateMatchScore()
    ↓ (parallel calculations)
┌─ AI Compatibility (40%) ─┐
├─ Semantic Similarity (30%) ─┤
├─ Location Proximity (15%) ─┤  → Weighted Total Score
├─ Time Relevance (10%) ─┤
└─ Keyword Overlap (5%) ─┘
    ↓ (if score > 0.5)
Create Match Record
    ↓ (save to Firestore)
Collection: "matches"
    ↓ (if score > 0.8)
Send Push Notification
    ↓
Update UI with new matches
```

#### 3. Communication Data Flow

```
User taps "Chat" on match card
    ↓
ConversationService.getOrCreateConversation()
    ↓ (check existing)
Query: conversations where participantIds contains both users
    ↓ (if exists)
Return existing conversation ID
    ↓ (if not exists)
Create new conversation document
    ↓
Navigate to EnhancedChatScreen
    ↓ (real-time listener)
StreamBuilder<QuerySnapshot> → messages subcollection
    ↓ (user types message)
ConversationService.sendMessage()
    ↓ (batch write)
┌─ Add message to subcollection ─┐
├─ Update conversation last message ─┤
├─ Increment unread count ─┤
└─ Send push notification ─┘
    ↓ (real-time update)
All participants see new message immediately
```

### API Requests & Responses

#### Google Gemini AI API Integration

**Intent Analysis Request:**
```json
{
  "contents": [{
    "parts": [{
      "text": "Analyze this user request and extract structured intent: 'iPhone under $500'\n\nReturn JSON with: intent, action, entities, confidence, needsClarification"
    }]
  }],
  "generationConfig": {
    "temperature": 0.1,
    "topK": 1,
    "topP": 1,
    "maxOutputTokens": 1024
  }
}
```

**Intent Analysis Response:**
```json
{
  "candidates": [{
    "content": {
      "parts": [{
        "text": "{\n  \"intent\": \"seeking\",\n  \"action\": \"buy\",\n  \"entities\": {\n    \"item\": \"iPhone\",\n    \"maxPrice\": 500,\n    \"category\": \"electronics\"\n  },\n  \"confidence\": 0.95,\n  \"needsClarification\": false\n}"
      }]
    }
  }]
}
```

**Text Embedding Request:**
```json
{
  "model": "models/text-embedding-004",
  "content": {
    "parts": [{"text": "iPhone smartphone mobile phone buy purchase electronics"}]
  }
}
```

**Text Embedding Response:**
```json
{
  "embedding": {
    "values": [0.1234, -0.5678, 0.9012, ..., 0.4567]
  }
}
```

#### Firebase Firestore Operations

**Database Collections Structure:**

```javascript
// Collection: users
{
  [userId]: {
    name: "John Doe",
    email: "john@example.com",
    profileImageUrl: "https://...",
    location: "New York, NY",
    latitude: 40.7128,
    longitude: -74.0060,
    isOnline: true,
    lastSeen: Timestamp,
    fcmToken: "device_token",
    bio: "Software developer and tech enthusiast",
    interests: ["technology", "hiking", "photography"],
    createdAt: Timestamp,
    updatedAt: Timestamp
  }
}

// Collection: ai_posts
{
  [postId]: {
    userId: "user123",
    originalPrompt: "iPhone under $500",
    analysis: {
      intent: "seeking",
      action: "buy",
      entities: { item: "iPhone", maxPrice: 500 },
      confidence: 0.95
    },
    clarificationAnswers: {},
    embedding: [0.1, 0.2, ..., 0.9], // 1536-dimensional vector
    location: GeoPoint(40.7128, -74.0060),
    createdAt: Timestamp,
    updatedAt: Timestamp,
    isActive: true,
    matchedUserIds: ["user456", "user789"]
  }
}

// Collection: conversations
{
  [conversationId]: {
    participantIds: ["user123", "user456"],
    participantNames: {
      "user123": "John Doe",
      "user456": "Jane Smith"
    },
    participantPhotos: {
      "user123": "https://...",
      "user456": "https://..."
    },
    lastMessage: "Hey, is the iPhone still available?",
    lastMessageTime: Timestamp,
    lastMessageSenderId: "user123",
    unreadCount: {
      "user123": 0,
      "user456": 1
    },
    isTyping: {
      "user123": false,
      "user456": false
    },
    createdAt: Timestamp
  }
}

// Subcollection: conversations/{conversationId}/messages
{
  [messageId]: {
    senderId: "user123",
    content: "Hey, is the iPhone still available?",
    type: "text",
    status: "delivered",
    createdAt: Timestamp,
    imageUrl: null,
    voiceUrl: null
  }
}

// Collection: matches
{
  [matchId]: {
    userId: "user123",
    matchedUserId: "user456",
    matchedPostId: "post789",
    score: 0.87,
    explanation: "You both are interested in iPhones - they're selling and you're looking to buy!",
    factors: {
      aiCompatibility: 0.95,
      semanticSimilarity: 0.82,
      locationProximity: 0.75,
      timeRelevance: 0.90,
      keywordOverlap: 0.65
    },
    status: "pending", // pending, contacted, ignored
    createdAt: Timestamp
  }
}
```

**Firestore Security Rules:**

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own profile
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null; // Others can read basic profile info
    }

    // Posts are readable by authenticated users, writable by owner
    match /ai_posts/{postId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
                      request.auth.uid == resource.data.userId;
    }

    // Conversations are accessible only to participants
    match /conversations/{conversationId} {
      allow read, write: if request.auth != null &&
                            request.auth.uid in resource.data.participantIds;

      // Messages subcollection
      match /messages/{messageId} {
        allow read, write: if request.auth != null &&
                              request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participantIds;
      }
    }

    // Matches are readable by involved users
    match /matches/{matchId} {
      allow read: if request.auth != null &&
                     (request.auth.uid == resource.data.userId ||
                      request.auth.uid == resource.data.matchedUserId);
      allow write: if request.auth != null &&
                      request.auth.uid == resource.data.userId;
    }
  }
}
```

**Firestore Indexes:**

```json
{
  "indexes": [
    {
      "collectionGroup": "ai_posts",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "isActive", "order": "ASCENDING"},
        {"fieldPath": "analysis.intent", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "ai_posts",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "userId", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "conversations",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "participantIds", "arrayConfig": "CONTAINS"},
        {"fieldPath": "lastMessageTime", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "messages",
      "queryScope": "COLLECTION_GROUP",
      "fields": [
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    }
  ]
}
```

### Local Storage & Caching Strategy

#### SharedPreferences Usage

```dart
// Theme preferences
final prefs = await SharedPreferences.getInstance();
await prefs.setBool('isDarkMode', true);
await prefs.setString('primaryColor', '#2196F3');
await prefs.setString('fontFamily', 'Roboto');

// User preferences
await prefs.setBool('notificationsEnabled', true);
await prefs.setBool('locationSharingEnabled', true);
await prefs.setString('lastLocationUpdate', DateTime.now().toIso8601String());

// App state
await prefs.setStringList('recentSearches', ['iPhone', 'tennis partner']);
await prefs.setString('lastUsedIntentTemplate', 'marketplace');
```

#### Memory Management & Caching

```dart
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  // Cache for user profiles
  final Map<String, UserProfile> _userProfileCache = {};

  // Cache for post embeddings
  final Map<String, List<double>> _embeddingCache = {};

  // Cache for conversation metadata
  final Map<String, ConversationModel> _conversationCache = {};

  void initialize() {
    // Set cache size limits
    Timer.periodic(Duration(minutes: 5), (_) => _cleanupCaches());
  }

  void _cleanupCaches() {
    // Remove old entries to prevent memory leaks
    if (_userProfileCache.length > 100) {
      _userProfileCache.clear();
    }
    if (_embeddingCache.length > 50) {
      _embeddingCache.clear();
    }
  }

  UserProfile? getCachedUserProfile(String userId) {
    return _userProfileCache[userId];
  }

  void cacheUserProfile(String userId, UserProfile profile) {
    _userProfileCache[userId] = profile;
  }
}
```

#### Image Caching

```dart
class PhotoCacheService {
  static final PhotoCacheService _instance = PhotoCacheService._internal();
  factory PhotoCacheService() => _instance;
  PhotoCacheService._internal();

  // Using cached_network_image for automatic caching
  Widget buildCachedImage(String? imageUrl, {double? width, double? height}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Icon(Icons.person, size: width ?? height ?? 40);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        child: Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Icon(
        Icons.error,
        size: width ?? height ?? 40,
      ),
      memCacheWidth: (width?.toInt() ?? 200) * 2, // 2x for retina displays
      memCacheHeight: (height?.toInt() ?? 200) * 2,
      maxWidthDiskCache: 800,
      maxHeightDiskCache: 800,
    );
  }

  Future<void> preloadImage(String imageUrl) async {
    try {
      await precacheImage(CachedNetworkImageProvider(imageUrl),
                         navigatorKey.currentContext!);
    } catch (e) {
      debugPrint('Error preloading image: $e');
    }
  }
}
```

### Error Handling Strategy

#### Global Error Handler

```dart
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  void initialize() {
    // Catch all Flutter errors
    FlutterError.onError = (FlutterErrorDetails details) {
      _logError(details.exception, details.stack);
      _reportToCrashlytics(details.exception, details.stack);
    };

    // Catch all other errors
    PlatformDispatcher.instance.onError = (error, stack) {
      _logError(error, stack);
      _reportToCrashlytics(error, stack);
      return true;
    };
  }

  void _logError(dynamic error, StackTrace? stack) {
    debugPrint('Error: $error');
    if (stack != null) {
      debugPrint('Stack trace: $stack');
    }
  }

  void _reportToCrashlytics(dynamic error, StackTrace? stack) {
    try {
      FirebaseCrashlytics.instance.recordError(error, stack);
    } catch (e) {
      debugPrint('Failed to report to Crashlytics: $e');
    }
  }
}
```

#### Network Error Handling

```dart
class SafeNetworkService {
  static Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;

        if (attempts >= maxRetries) {
          rethrow;
        }

        if (e is SocketException ||
            e is TimeoutException ||
            e is HttpException) {
          // Network-related errors - retry with exponential backoff
          await Future.delayed(delay * attempts);
        } else {
          // Non-network errors - don't retry
          rethrow;
        }
      }
    }

    throw Exception('Max retry attempts reached');
  }
}
```

#### Firestore Error Handling

```dart
class SafeFirestoreService {
  static Future<DocumentSnapshot?> safeGet(DocumentReference ref) async {
    try {
      final doc = await ref.get();
      return doc.exists ? doc : null;
    } on FirebaseException catch (e) {
      switch (e.code) {
        case 'permission-denied':
          debugPrint('Permission denied accessing document');
          return null;
        case 'unavailable':
          debugPrint('Firestore temporarily unavailable');
          throw Exception('Service temporarily unavailable');
        default:
          debugPrint('Firestore error: ${e.code} - ${e.message}');
          rethrow;
      }
    } catch (e) {
      debugPrint('Unexpected error: $e');
      rethrow;
    }
  }

  static Future<void> safeWrite(
    DocumentReference ref,
    Map<String, dynamic> data,
  ) async {
    try {
      await ref.set(data, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      switch (e.code) {
        case 'permission-denied':
          throw Exception('You do not have permission to perform this action');
        case 'quota-exceeded':
          throw Exception('Quota exceeded. Please try again later.');
        default:
          throw Exception('Failed to save data: ${e.message}');
      }
    }
  }
}
```

---

## 7. Setup & Run Instructions

### Prerequisites

#### Development Environment Setup

**1. Flutter SDK Installation:**
```bash
# macOS (using Homebrew)
brew install --cask flutter

# Windows (using Chocolatey)
choco install flutter

# Linux (manual installation)
cd ~/development
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"
```

**2. Development Tools:**
```bash
# Install Android Studio
# Download from: https://developer.android.com/studio

# Install VS Code with Flutter extension
# Download from: https://code.visualstudio.com/

# Install Xcode (macOS only, for iOS development)
# Install from Mac App Store
```

**3. Platform SDKs:**
```bash
# Android SDK (via Android Studio)
# iOS SDK (via Xcode on macOS)
# Web support (enabled by default in Flutter 3.8+)

# Verify installation
flutter doctor -v
```

#### Firebase Project Setup

**1. Create Firebase Project:**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: "supper-app" (or your preferred name)
4. Enable Google Analytics (recommended)
5. Choose Analytics location

**2. Enable Firebase Services:**
```bash
# Authentication
- Go to Authentication > Sign-in method
- Enable Google Sign-in
- Enable Email/Password
- Download configuration files

# Firestore Database
- Go to Firestore Database > Create database
- Start in test mode (we'll update rules later)
- Choose region closest to your users

# Cloud Storage
- Go to Storage > Get started
- Start in test mode
- Choose same region as Firestore

# Cloud Messaging
- Go to Cloud Messaging
- No additional setup required

# Crashlytics
- Go to Crashlytics > Get started
- Follow setup instructions for each platform
```

**3. Download Configuration Files:**
```bash
# Android: google-services.json
# Download from Project Settings > General > Your apps
# Place in: android/app/google-services.json

# iOS: GoogleService-Info.plist
# Download from Project Settings > General > Your apps
# Place in: ios/Runner/GoogleService-Info.plist

# Web: Firebase config object
# Copy from Project Settings > General > Your apps > Web app
# Add to: lib/firebase_options.dart
```

#### API Keys Setup

**1. Google Gemini AI API:**
```bash
# Go to Google AI Studio: https://aistudio.google.com/
# Create API key
# Add to environment variables or secure storage

# For development, add to lib/config/api_keys.dart:
class ApiKeys {
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';
}
```

**2. Google Maps API (for geocoding):**
```bash
# Go to Google Cloud Console: https://console.cloud.google.com/
# Enable Geocoding API and Maps SDK
# Create API key with appropriate restrictions
# Add to platform-specific configuration files
```

### Installation Steps

#### 1. Clone and Basic Setup

```bash
# Clone the repository
git clone <repository_url>
cd "flutter 14"

# Verify Flutter installation
flutter doctor -v

# Install dependencies
flutter pub get

# Clean any existing builds
flutter clean
```

#### 2. Environment Configuration

**Create environment configuration file:**

```dart
// lib/config/environment.dart
class Environment {
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'your-api-key-here',
  );

  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'your-maps-api-key-here',
  );

  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false,
  );
}
```

**Environment variables setup:**

```bash
# Create .env file (for development)
GEMINI_API_KEY=your_actual_gemini_api_key_here
GOOGLE_MAPS_API_KEY=your_actual_maps_api_key_here
PRODUCTION=false

# For production builds, pass via build command:
flutter build apk --dart-define=GEMINI_API_KEY=your_key --dart-define=PRODUCTION=true
```

#### 3. Firebase Configuration

**Deploy Firestore rules:**

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in project directory
firebase init

# Select Firestore, Storage, and Hosting
# Use existing project (select your created project)
# Accept default files (firestore.rules, firestore.indexes.json)

# Deploy rules and indexes
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

**Update Firestore rules:**

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own profile
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null;
    }

    // Posts are readable by all authenticated users
    match /ai_posts/{postId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
                      request.auth.uid == request.resource.data.userId;
    }

    // Conversations are accessible only to participants
    match /conversations/{conversationId} {
      allow read, write: if request.auth != null &&
                            request.auth.uid in resource.data.participantIds;

      match /messages/{messageId} {
        allow read, write: if request.auth != null &&
                              request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participantIds;
      }
    }

    // Matches are readable by involved users
    match /matches/{matchId} {
      allow read: if request.auth != null &&
                     (request.auth.uid == resource.data.userId ||
                      request.auth.uid == resource.data.matchedUserId);
    }
  }
}
```

#### 4. Platform-Specific Setup

**Android Configuration:**

```bash
# android/app/build.gradle
android {
    compileSdkVersion 34

    defaultConfig {
        applicationId "com.example.supper"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0"
        multiDexEnabled true
    }
}

dependencies {
    implementation 'com.google.firebase:firebase-bom:32.7.0'
    implementation 'com.android.support:multidex:1.0.3'
}
```

**iOS Configuration:**

```bash
# ios/Runner/Info.plist
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to find nearby matches.</string>
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to take profile photos.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to select profile photos.</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for voice calling.</string>

# Set minimum iOS version
ios/Podfile:
platform :ios, '12.0'
```

**Web Configuration:**

```html
<!-- web/index.html -->
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="Supper - AI-powered universal matching platform">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="Supper">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">
  <link rel="icon" type="image/png" href="favicon.png"/>
  <title>Supper</title>
  <link rel="manifest" href="manifest.json">
</head>
<body>
  <!-- Firebase SDKs -->
  <script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js"></script>
  <script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-firestore-compat.js"></script>
  <script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-auth-compat.js"></script>
  <script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js"></script>

  <script>
    // Firebase configuration
    const firebaseConfig = {
      apiKey: "your-api-key",
      authDomain: "your-project.firebaseapp.com",
      projectId: "your-project-id",
      storageBucket: "your-project.appspot.com",
      messagingSenderId: "123456789",
      appId: "your-app-id"
    };
    firebase.initializeApp(firebaseConfig);
  </script>

  <script src="main.dart.js" type="application/javascript"></script>
</body>
</html>
```

### Running the Application

#### Development Mode

```bash
# Run on connected device (automatically detects available devices)
flutter run

# Run on specific platform
flutter run -d chrome          # Web browser
flutter run -d android         # Android device/emulator
flutter run -d ios            # iOS device/simulator (macOS only)

# Run with specific environment
flutter run --dart-define=GEMINI_API_KEY=your_key

# Hot reload during development
# Press 'r' for hot reload
# Press 'R' for hot restart
# Press 'q' to quit
```

#### Debug and Testing

```bash
# Run tests
flutter test

# Run integration tests
flutter test integration_test/

# Run with performance profiling
flutter run --profile

# Generate test coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

#### Building for Production

**Android APK (for testing):**
```bash
flutter build apk --release --dart-define=GEMINI_API_KEY=your_production_key
# Output: build/app/outputs/flutter-apk/app-release.apk
```

**Android App Bundle (for Play Store):**
```bash
flutter build appbundle --release --dart-define=GEMINI_API_KEY=your_production_key
# Output: build/app/outputs/bundle/release/app-release.aab
```

**iOS (for App Store):**
```bash
flutter build ios --release --dart-define=GEMINI_API_KEY=your_production_key
# Then use Xcode to archive and upload to App Store Connect
```

**Web (for hosting):**
```bash
flutter build web --release --dart-define=GEMINI_API_KEY=your_production_key
# Output: build/web/

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

### Troubleshooting Common Issues

#### 1. Firebase Connection Issues

```bash
# Verify Firebase configuration
flutter packages pub run build_runner build

# Check if google-services.json is in correct location
ls android/app/google-services.json

# Verify iOS configuration
ls ios/Runner/GoogleService-Info.plist

# Clear Firebase cache
flutter clean
flutter pub get
cd ios && pod install --repo-update (for iOS)
```

#### 2. API Key Issues

```bash
# Verify API keys are set correctly
echo $GEMINI_API_KEY

# Check API key permissions in Google Cloud Console
# Ensure Gemini API is enabled
# Verify API key restrictions are not too restrictive
```

#### 3. Build Issues

```bash
# Clear all caches and rebuild
flutter clean
flutter pub get
cd ios && pod clean && pod install (for iOS)
flutter build apk --debug

# Check for version conflicts
flutter pub deps
flutter doctor -v
```

#### 4. Platform-Specific Issues

**Android:**
```bash
# Update Android SDK and build tools
# Check gradle versions in android/gradle/wrapper/gradle-wrapper.properties
# Verify Android signing configuration
```

**iOS:**
```bash
# Update Xcode to latest version
# Update CocoaPods: sudo gem install cocoapods
# Clean derived data: rm -rf ~/Library/Developer/Xcode/DerivedData
```

**Web:**
```bash
# Enable web support if not already enabled
flutter config --enable-web
flutter create --platforms web .

# Check CORS configuration for API calls
# Verify Firebase web configuration
```

### Performance Optimization

#### 1. Build Optimizations

```bash
# Enable code shrinking and obfuscation
flutter build apk --release --obfuscate --split-debug-info=build/symbols

# Tree shaking for web
flutter build web --release --tree-shake-icons --dart-define=Dart2jsOptimization=O4
```

#### 2. Asset Optimization

```bash
# Optimize images before adding to assets
# Use WebP format for web platform
# Implement lazy loading for large lists
```

#### 3. Database Optimizations

```javascript
// Create compound indexes for common queries
// firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "ai_posts",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "isActive", "order": "ASCENDING"},
        {"fieldPath": "analysis.intent", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    }
  ]
}
```

---

## 8. Future Development Notes

### Architectural Improvements

#### 1. Scalability Enhancements

**Database Sharding Strategy:**
```
Current: Single Firestore database
↓
Future: Geographic sharding
├── firestore-us-east (Americas)
├── firestore-eu-west (Europe)
├── firestore-asia-pacific (Asia)
└── Cross-region replication for critical data
```

**Microservices Migration:**
```
Current: Monolithic Flutter app with service classes
↓
Future: Microservices architecture
├── Intent Analysis Service (AI processing)
├── Matching Engine Service (real-time matching)
├── Communication Service (chat & voice)
├── Notification Service (push notifications)
└── User Management Service (profiles & auth)
```

**Caching Layer Implementation:**
```
Current: Local caching with SharedPreferences
↓
Future: Distributed caching
├── Redis for session data
├── CDN for static assets
├── Database query result caching
└── API response caching
```

#### 2. AI & Machine Learning Improvements

**Custom ML Models:**
```dart
// Future: Custom trained models for intent classification
class CustomIntentClassifier {
  late tflite.Interpreter _interpreter;

  Future<void> loadModel() async {
    final modelData = await rootBundle.load('assets/models/intent_classifier.tflite');
    _interpreter = tflite.Interpreter.fromBuffer(modelData.buffer.asUint8List());
  }

  Future<Map<String, double>> classifyIntent(String text) async {
    // Preprocess text
    final inputTokens = _preprocessText(text);

    // Run inference
    final input = [inputTokens];
    final output = [List<double>.filled(10, 0)]; // 10 intent categories

    _interpreter.run(input, output);

    // Post-process results
    return _postprocessResults(output[0]);
  }
}
```

**Advanced Matching Algorithms:**
```dart
// Future: Collaborative filtering for improved matching
class CollaborativeMatchingEngine {
  Future<List<Match>> findMatches(String userId) async {
    // 1. Content-based filtering (current implementation)
    final contentMatches = await _contentBasedMatching(userId);

    // 2. Collaborative filtering (user similarity)
    final collaborativeMatches = await _collaborativeFiltering(userId);

    // 3. Hybrid approach combining both
    final hybridMatches = _combineMatchingStrategies(
      contentMatches,
      collaborativeMatches,
    );

    // 4. Machine learning ranking
    return await _mlRanking(hybridMatches, userId);
  }

  Future<List<Match>> _collaborativeFiltering(String userId) async {
    // Find users with similar interaction patterns
    final similarUsers = await _findSimilarUsers(userId);

    // Recommend posts that similar users engaged with
    final recommendations = await _generateRecommendations(similarUsers);

    return recommendations;
  }
}
```

**Natural Language Understanding:**
```dart
// Future: Multi-language support with advanced NLU
class AdvancedNLUEngine {
  Future<IntentAnalysis> analyzeMultiLanguage(String text) async {
    // 1. Language detection
    final language = await _detectLanguage(text);

    // 2. Translation to English if needed
    final englishText = language != 'en'
        ? await _translateText(text, language, 'en')
        : text;

    // 3. Advanced entity extraction
    final entities = await _extractEntitiesWithContext(englishText);

    // 4. Sentiment analysis
    final sentiment = await _analyzeSentiment(englishText);

    // 5. Intent classification with confidence scoring
    final intent = await _classifyIntent(englishText, entities, sentiment);

    return IntentAnalysis(
      originalText: text,
      language: language,
      entities: entities,
      sentiment: sentiment,
      intent: intent,
      confidence: intent.confidence,
    );
  }
}
```

#### 3. Real-Time Features Enhancement

**WebSocket Integration:**
```dart
// Future: WebSocket for real-time updates
class RealtimeConnectionManager {
  late WebSocketChannel _channel;
  final StreamController<RealtimeEvent> _eventController = StreamController.broadcast();

  Future<void> connect(String userId) async {
    _channel = WebSocketChannel.connect(
      Uri.parse('wss://api.supper.app/ws/$userId'),
    );

    _channel.stream.listen((data) {
      final event = RealtimeEvent.fromJson(jsonDecode(data));
      _eventController.add(event);
    });
  }

  Stream<RealtimeEvent> get events => _eventController.stream;

  void sendEvent(RealtimeEvent event) {
    _channel.sink.add(jsonEncode(event.toJson()));
  }
}

// Usage for real-time matching
class RealtimeMatchingService {
  final RealtimeConnectionManager _connection = RealtimeConnectionManager();

  void initialize(String userId) {
    _connection.connect(userId);

    _connection.events.listen((event) {
      switch (event.type) {
        case 'new_match':
          _handleNewMatch(event.data);
          break;
        case 'message_received':
          _handleNewMessage(event.data);
          break;
        case 'user_online':
          _handleUserOnline(event.data);
          break;
      }
    });
  }
}
```

**Advanced Push Notifications:**
```dart
// Future: Smart notification system with ML
class SmartNotificationService {
  Future<void> sendIntelligentNotification({
    required String userId,
    required NotificationType type,
    required Map<String, dynamic> data,
  }) async {
    // 1. Check user notification preferences
    final preferences = await _getUserNotificationPreferences(userId);

    // 2. Analyze user activity patterns
    final activityPattern = await _analyzeUserActivity(userId);

    // 3. Determine optimal timing
    final optimalTime = _calculateOptimalDeliveryTime(activityPattern);

    // 4. Personalize notification content
    final personalizedContent = await _personalizeContent(userId, type, data);

    // 5. Schedule notification
    await _scheduleNotification(
      userId: userId,
      content: personalizedContent,
      deliveryTime: optimalTime,
      priority: _calculatePriority(type, data),
    );
  }

  Future<String> _personalizeContent(
    String userId,
    NotificationType type,
    Map<String, dynamic> data,
  ) async {
    final userProfile = await _getUserProfile(userId);
    final interactionHistory = await _getInteractionHistory(userId);

    // Use ML to generate personalized notification text
    return await _generatePersonalizedText(
      type: type,
      data: data,
      profile: userProfile,
      history: interactionHistory,
    );
  }
}
```

#### 4. Security & Privacy Enhancements

**End-to-End Encryption:**
```dart
// Future: E2E encryption for messages
class E2EEncryptionService {
  static const String _algorithm = 'AES-256-GCM';

  Future<String> encryptMessage(String message, String recipientPublicKey) async {
    // 1. Generate symmetric key
    final symmetricKey = _generateSymmetricKey();

    // 2. Encrypt message with symmetric key
    final encryptedMessage = await _encryptSymmetric(message, symmetricKey);

    // 3. Encrypt symmetric key with recipient's public key
    final encryptedKey = await _encryptAsymmetric(symmetricKey, recipientPublicKey);

    // 4. Combine encrypted message and key
    return jsonEncode({
      'encryptedMessage': encryptedMessage,
      'encryptedKey': encryptedKey,
      'algorithm': _algorithm,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<String> decryptMessage(String encryptedData, String privateKey) async {
    final data = jsonDecode(encryptedData);

    // 1. Decrypt symmetric key with private key
    final symmetricKey = await _decryptAsymmetric(data['encryptedKey'], privateKey);

    // 2. Decrypt message with symmetric key
    final message = await _decryptSymmetric(data['encryptedMessage'], symmetricKey);

    return message;
  }
}
```

**Advanced User Verification:**
```dart
// Future: Multi-factor user verification
class AdvancedVerificationService {
  Future<VerificationResult> verifyUser(String userId) async {
    final verificationMethods = <String, bool>{};

    // 1. Phone number verification
    verificationMethods['phone'] = await _verifyPhoneNumber(userId);

    // 2. Email verification
    verificationMethods['email'] = await _verifyEmail(userId);

    // 3. Government ID verification (optional)
    verificationMethods['id'] = await _verifyGovernmentId(userId);

    // 4. Social media cross-verification
    verificationMethods['social'] = await _verifySocialMedia(userId);

    // 5. Biometric verification (future)
    verificationMethods['biometric'] = await _verifyBiometric(userId);

    final verificationScore = _calculateVerificationScore(verificationMethods);

    return VerificationResult(
      userId: userId,
      methods: verificationMethods,
      score: verificationScore,
      level: _getVerificationLevel(verificationScore),
      badgeType: _getBadgeType(verificationScore),
    );
  }
}
```

#### 5. Analytics & Insights

**Advanced Analytics Dashboard:**
```dart
// Future: Real-time analytics for user behavior
class AdvancedAnalyticsService {
  Future<UserInsights> generateUserInsights(String userId) async {
    final analytics = await _gatherAnalyticsData(userId);

    return UserInsights(
      // Matching effectiveness
      matchSuccessRate: analytics['matches']['successRate'],
      averageMatchScore: analytics['matches']['averageScore'],
      bestMatchingCategories: analytics['matches']['topCategories'],

      // Communication patterns
      responseRate: analytics['communication']['responseRate'],
      averageResponseTime: analytics['communication']['avgResponseTime'],
      preferredCommunicationTimes: analytics['communication']['preferredTimes'],

      // User engagement
      sessionDuration: analytics['engagement']['avgSessionDuration'],
      dailyActiveTime: analytics['engagement']['dailyActiveTime'],
      featureUsage: analytics['engagement']['featureUsage'],

      // Recommendations
      suggestedImprovements: await _generateSuggestions(analytics),
      optimizationTips: await _generateOptimizationTips(analytics),
    );
  }

  Future<List<String>> _generateSuggestions(Map<String, dynamic> analytics) async {
    final suggestions = <String>[];

    // ML-based suggestions
    if (analytics['matches']['successRate'] < 0.3) {
      suggestions.add('Try being more specific in your posts for better matches');
    }

    if (analytics['communication']['responseRate'] < 0.5) {
      suggestions.add('Responding faster could improve your connection rate');
    }

    return suggestions;
  }
}
```

**Business Intelligence Platform:**
```dart
// Future: Platform-wide analytics for business insights
class BusinessIntelligenceService {
  Future<PlatformMetrics> generatePlatformMetrics() async {
    return PlatformMetrics(
      // User metrics
      totalUsers: await _getTotalUsers(),
      activeUsers: await _getActiveUsers(),
      userGrowthRate: await _calculateGrowthRate(),
      userRetentionRate: await _calculateRetentionRate(),

      // Matching metrics
      totalMatches: await _getTotalMatches(),
      successfulConnections: await _getSuccessfulConnections(),
      averageTimeToMatch: await _getAverageTimeToMatch(),
      topMatchingCategories: await _getTopCategories(),

      // Revenue metrics (future monetization)
      revenue: await _calculateRevenue(),
      subscriptionConversions: await _getSubscriptionConversions(),
      averageRevenuePerUser: await _getARPU(),

      // Technical metrics
      apiResponseTimes: await _getApiMetrics(),
      errorRates: await _getErrorRates(),
      systemUptime: await _getUptime(),
    );
  }
}
```

### Technology Migration Path

#### State Management Evolution

```dart
// Current: Provider
// Future: Consider Riverpod for better performance and testing

// Riverpod example for future migration
final userProfileProvider = FutureProvider.family<UserProfile, String>((ref, userId) async {
  final profileService = ref.read(profileServiceProvider);
  return await profileService.getUserProfile(userId);
});

final matchesProvider = StreamProvider.family<List<Match>, String>((ref, userId) {
  final matchingService = ref.read(matchingServiceProvider);
  return matchingService.getMatchesStream(userId);
});

// Usage in widgets
class UserProfileWidget extends ConsumerWidget {
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider(userId));

    return userProfileAsync.when(
      data: (profile) => ProfileView(profile: profile),
      loading: () => LoadingWidget(),
      error: (error, stack) => ErrorWidget(error: error),
    );
  }
}
```

#### Backend Evolution Strategy

```
Phase 1: Current (Firebase-centric)
├── Firebase Auth, Firestore, Storage
├── Google Gemini AI
└── Cloud Functions for complex operations

Phase 2: Hybrid (6-12 months)
├── Keep Firebase for real-time features
├── Add Node.js/Python microservices for AI
├── Redis for caching
└── Message queues for background processing

Phase 3: Microservices (12-18 months)
├── Kubernetes cluster for microservices
├── API Gateway for request routing
├── Dedicated databases per service
└── Event-driven architecture

Phase 4: Scale (18+ months)
├── Multi-region deployment
├── Auto-scaling infrastructure
├── Advanced monitoring and alerting
└── Machine learning pipeline automation
```

### Monetization Strategies

#### 1. Premium Features

```dart
// Future: Subscription-based premium features
class PremiumFeatureService {
  Future<bool> hasFeatureAccess(String userId, PremiumFeature feature) async {
    final subscription = await _getUserSubscription(userId);

    switch (feature) {
      case PremiumFeature.unlimitedMatches:
        return subscription.tier >= SubscriptionTier.basic;
      case PremiumFeature.priorityMatching:
        return subscription.tier >= SubscriptionTier.premium;
      case PremiumFeature.advancedFilters:
        return subscription.tier >= SubscriptionTier.premium;
      case PremiumFeature.readReceipts:
        return subscription.tier >= SubscriptionTier.basic;
      case PremiumFeature.voiceMessages:
        return subscription.tier >= SubscriptionTier.premium;
      default:
        return false;
    }
  }
}

enum PremiumFeature {
  unlimitedMatches,
  priorityMatching,
  advancedFilters,
  readReceipts,
  voiceMessages,
  profileBoost,
  detailedAnalytics,
}

enum SubscriptionTier {
  free,
  basic,
  premium,
  enterprise,
}
```

#### 2. Enterprise Solutions

```dart
// Future: B2B platform for companies
class EnterpriseService {
  Future<void> createEnterpriseAccount({
    required String companyName,
    required String adminUserId,
    required EnterpriseFeatures features,
  }) async {
    // Create enterprise workspace
    // Enable advanced features like:
    // - Employee networking
    // - Skills matching
    // - Project collaboration
    // - Team building features
  }
}
```

### Development Best Practices

#### 1. Testing Strategy

```dart
// Comprehensive testing approach
// Unit tests for business logic
// Widget tests for UI components
// Integration tests for complete flows
// Performance tests for scalability

// Example: Testing the matching algorithm
group('AI Matching Service Tests', () {
  late AIMatchingService matchingService;
  late MockFirestore mockFirestore;

  setUp(() {
    mockFirestore = MockFirestore();
    matchingService = AIMatchingService(firestore: mockFirestore);
  });

  test('should return high score for complementary intents', () async {
    final post1 = AIPostModel(/* selling iPhone */);
    final post2 = AIPostModel(/* buying iPhone */);

    final score = await matchingService.calculateMatchScore(post1, post2);

    expect(score.totalScore, greaterThan(0.8));
    expect(score.factors['aiCompatibility'], greaterThan(0.9));
  });

  test('should handle edge cases gracefully', () async {
    final invalidPost = AIPostModel(/* invalid data */);

    expect(
      () => matchingService.calculateMatchScore(invalidPost, invalidPost),
      throwsA(isA<ValidationException>()),
    );
  });
});
```

#### 2. Code Quality Standards

```dart
// Enforce coding standards with analysis_options.yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  strong-mode:
    implicit-casts: false
    implicit-dynamic: false

linter:
  rules:
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - avoid_print
    - prefer_final_locals
    - unnecessary_null_checks
    - use_super_parameters
```

#### 3. Documentation Standards

```dart
/// Service for managing user authentication and sessions.
///
/// This service handles:
/// - Google Sign-in authentication
/// - Session management and persistence
/// - User profile creation and updates
/// - Online status tracking
///
/// Example usage:
/// ```dart
/// final authService = AuthService();
/// final user = await authService.signInWithGoogle();
/// if (user != null) {
///   print('Signed in: ${user.displayName}');
/// }
/// ```
class AuthService {
  /// Signs in user with Google OAuth.
  ///
  /// Returns [User] object if successful, null otherwise.
  /// Throws [AuthException] if sign-in fails.
  Future<User?> signInWithGoogle() async {
    // Implementation
  }
}
```

### Final Recommendations

#### For AI/LLMs Continuing This Project

1. **Understand the Core Philosophy**: This is a universal intent matching platform, not just another social app. The AI should handle ANY type of human need or offering.

2. **Focus on Intent Quality**: Matching quality depends on accurate intent extraction. Continuously improve AI prompts and clarification logic.

3. **Test Edge Cases**: Handle unusual inputs like "My grandmother needs help" or "Looking for someone to practice French with" gracefully.

4. **Maintain Real-Time Performance**: As features are added, ensure real-time matching doesn't slow down. Consider background processing for non-urgent matches.

5. **Prioritize Safety**: With direct user connections, implement robust blocking, reporting, and moderation features.

#### Key Files to Monitor

- `lib/services/ai_intent_engine.dart` - The brain of the system
- `lib/services/ai_matching_service.dart` - The heart of user connections
- `lib/services/universal_intent_service.dart` - Main orchestrator
- `lib/services/conversation_service.dart` - Communication backbone
- `lib/models/ai_post_model.dart` - Core data structure

#### Success Metrics to Track

- **Intent classification accuracy** (>90% target)
- **Match success rate** (users who start conversations)
- **User retention** (daily/weekly active users)
- **Response times** (<2 seconds for matching)
- **Error rates** (<1% for critical operations)

#### Scaling Considerations

- **Database partitioning** by geographic regions
- **Microservices** for AI processing and matching
- **CDN** for global content delivery
- **Load balancing** for high availability
- **Monitoring** and alerting for proactive issue resolution

This comprehensive documentation provides a complete technical blueprint for understanding, maintaining, and scaling the Supper app. The architecture supports the universal matching concept while maintaining simplicity for end users and scalability for millions of users globally.

---

**Document Complete**: This file contains everything needed to understand, build, maintain, and scale the Supper AI-powered universal matching platform.