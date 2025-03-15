# Atlas Support SDK for Flutter

A Flutter SDK that integrates a real-time chat widget into Flutter applications.

## Installation

Add Atlas Support SDK to your Flutter project by adding the following dependency to your `pubspec.yaml`:

```yaml
dependencies:
  atlas_support_sdk: ^2.0.0
```

## Setup

Import the package into your code:

```dart
import 'package:atlas_support_sdk/atlas_support_sdk.dart';
```

Connect the SDK to your account (you can find your App ID in the [Atlas company settings](https://app.atlas.so/settings/company)):

```dart
AtlasSDK.setAppId("YOUR_APP_ID");
```

**ℹ️ It's crucial to execute this code at the app's launch, as SDK functionality will be unavailable otherwise.**

## Identify your users

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
  persist: "order_instance",
  query: "chatbotKey: order",
)
```

## Event Handling

The SDK provides several event handlers to monitor chat activities:

```dart
// Handle errors
AtlasSDK.onError((error) {
  print(error.message);
  if (error.original != null) print(error.original);
});

// Track new chat sessions
AtlasSDK.onChatStarted((chatStarted) {
  var message = "💬 New chat: ${chatStarted.ticketId}"
  if (chatStarted.chatbotKey != null) message += " (🤖 via chatbot ${chatStarted.chatbotKey})"; 
  print(message);
});

// Monitor new tickets
AtlasSDK.onNewTicket((newTicket) {
  var message = "🎫 New ticket: ${newTicket.ticketId}"; 
  if (chatStarted.chatbotKey != null) message += " (🤖 via chatbot ${chatStarted.chatbotKey})"; 
  print(message);
});

// Watch for identity changes
AtlasSDK.onChangeIdentity((identity) {
  if (identity == null) {
    print("User logged out");
  } else {
    print("User identified: ${identity.atlasId}");
  }
});

// Track conversation statistics
AtlasSDK.watchStats((stats) {
  var unreadCount = stats.conversations.fold(0, (sum, conversation) => sum + conversation.unread);
  print("Unread conversations: ${unreadCount}");
});
```

Each event handler returns a dispose function that can be called to remove the listener.

## Requirements

- Flutter 2.0.0 or later
- Dart 2.12.0 or later

## Support

For issues or feature requests, contact the engineering team at [engineering@getatlas.io](mailto:engineering@getatlas.io) or visit our [GitHub Issues](https://github.com/atlas-support-inc/flutter-sdk/issues) page.

For more details, visit the official [Atlas Support website](https://atlas.so).

## Author

Atlas Support Inc, engineering@atlas.so
