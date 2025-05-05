# Atlas Support SDK for Flutter

A Flutter SDK that integrates a real-time chat widget into Flutter applications.

## Installation

Add Atlas Support SDK to your Flutter project by adding the following dependency to your `pubspec.yaml`:

```yaml
dependencies:
  atlas_support_sdk: ^2.0.0
```

## Setup

To use it with Android you need to ensure that internet access is enabled in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

Import the package into your code:

```dart
import 'package:atlas_support_sdk/atlas_support_sdk.dart';
```

Connect the SDK to your account (you can find your App ID in the [Atlas company settings](https://app.atlas.so/settings/company)):

```dart
AtlasSDK.setAppId("YOUR_APP_ID");
```

**ℹ️ It's crucial to execute this code at the app's launch, as SDK functionality will be unavailable otherwise.**

## User Management

### Identify Users
Make the following call with user details wherever a user logs into your application:

```dart
AtlasSDK.identify(
  userId: "user123",
  userHash: null, // Optional security hash
  name: "John Doe",
  email: "john@example.com",
  phoneNumber: "+1234567890",
  customFields: {
    "title": "senior",
    "level": 8,
  }
);
```

To make sure scammers can't spoof a user, you should pass a `userHash` into the identify call. You can find how to enable `userHash` validation in the [User Authentication](https://help.atlas.so/articles/620722-user-authentication) article.

Optional parameters like `name`, `email`, or `phoneNumber` should be set to null (not empty string) if they're unknown, so they won't override previously stored values.

When you want to update the user's details, you can call `identify` method again.

### Logout
To clear the user's session when they log out of your application, use:

```dart
AtlasSDK.logout();
```

## Atlas Widget

### Basic Implementation
To display the Atlas chat widget in your Flutter app:

```dart
AtlasSDK.Widget();
```

### Configuring the Widget
You can configure how Atlas UI looks through the [Chat Configuration page](https://app.atlas.so/configuration/chat). You can also configure the behavior using query parameters:

```dart
// Initialize chat with help center opened
AtlasSDK.Widget(query: "open: helpcenter")

// Initialize chat with a specific chatbot
AtlasSDK.Widget(query: "chatbotKey: report_bug")

// Initialize chat with last opened chatbot if exists
AtlasSDK.Widget(query: "chatbotKey: report_bug; prefer: last")
```

### Persistent Chat Sessions
To maintain chat state across widget rebuilds, use the `persist` parameter:

```dart
AtlasSDK.Widget(
  persist: "unique_key", // Controllers are stored by this key
  query: "chatbotKey: support"
)
```

## Event Handling

### Errors
The SDK provides detailed error information through the `AtlasError` class:

```dart
AtlasSDK.onError((error) {
  print("Error message: ${error.message}");
  print("Original error: ${error.original}"); // Additional error details if available
});
```

### Ticket Events
The SDK provides several event handlers to monitor chat activities:

```dart
// Triggered whenever user starts new chat
AtlasSDK.onChatStarted((chatStarted) {
  var message = "💬 New chat: ${chatStarted.ticketId}"
  if (chatStarted.chatbotKey != null) message += " (🤖 via chatbot ${chatStarted.chatbotKey})"; 
  print(message);
});

// Triggered when either basic chat has started, or chatbot has created ticket from the conversation
AtlasSDK.onNewTicket((newTicket) {
  var message = "🎫 New ticket: ${newTicket.ticketId}"; 
  if (newTicket.chatbotKey != null) message += " (🤖 via chatbot ${newTicket.chatbotKey})"; 
  print(message);
});

// Triggered when user identity is changed or removed
AtlasSDK.onChangeIdentity((identity) {
  if (identity == null) {
    print("User logged out");
  } else {
    print("User identified: ${identity.atlasId}");
  }
});

// Triggered when messages are received, read, or ticket is closed/reopened
AtlasSDK.watchStats((stats) {
  var unreadCount = stats.conversations.fold(0, (sum, conversation) => sum + conversation.unread);
  print("Unread conversations: ${unreadCount}");
});
```

### Event Handler Cleanup
All event handlers return a dispose function that should be called when the listener is no longer needed:

```dart
// Register handler
final dispose = AtlasSDK.onError((error) {
  print(error.message);
});

// Later, when you want to remove the handler
dispose();
```

## Ticket Management

You can update custom fields for a specific ticket after it's created:

```dart
AtlasSDK.updateCustomFields(
  "ticket_123",
  {
    "priority": "high",
    "category": "billing",
    // Any valid custom field
  }
);
```

## Custom Field Types
The SDK supports various custom field types. Here's how to properly format each type:

```dart
{
  // Text field (string)
  "description": "Customer feedback",
  
  // Number field (integer)
  "age": 25,
  
  // Decimal field (number with decimal places)
  "price": 99.99,
  
  // Date field (YYYY-MM-DD format)
  "birthDate": "1990-01-01",
  
  // List field (single selection from predefined list)
  "status": "active",
  
  // Multi field (multiple selections from predefined list)
  "tags": ["urgent", "billing"],
  
  // URL field (object with url and title)
  "website": {
    "url": "https://example.com",
    "title": "Company Website"
  },
  
  // Address field (object with address components, each is optional)
  "shippingAddress": {
    "street1": "123 Main St",
    "street2": "Apt 4B",
    "city": "New York",
    "state": "NY",
    "zipCode": "10001",
    "country": "US"
  },
  
  // Agent field (UUID)
  "assignedAgent": "550e8400-e29b-41d4-a716-446655440000",
  
  // Customer field (UUID)
  "customerId": "550e8400-e29b-41d4-a716-446655440000",
  
  // Account field (UUID)
  "accountId": "550e8400-e29b-41d4-a716-446655440000",
  
  // Ticket field (UUID)
  "relatedTicket": "550e8400-e29b-41d4-a716-446655440000"
}
```

## Data Management

The SDK automatically handles:
- Persistent storage of user identification
- Chat session management
- Controller state persistence when using the `persist` parameter
- Automatic reconnection handling

All data is securely stored using the device's SharedPreferences.

## Requirements

- Flutter 2.0.0 or later
- Dart 2.12.0 or later

## Support

For issues or feature requests, contact the engineering team at [engineering@atlas.so](mailto:engineering@atlas.so) or visit our [GitHub Issues](https://github.com/atlas-support-inc/flutter-sdk/issues) page.

For more details, visit the official [Atlas Support website](https://atlas.so).

## Author

Atlas Support Inc, engineering@atlas.so
