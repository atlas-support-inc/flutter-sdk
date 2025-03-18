// For development you can specify different values:
// flutter run --dart-define=ATLAS_API_URL=http://localhost:8080/api --dart-define=ATLAS_WS_URL=ws://localhost:8080 --dart-define=ATLAS_EMBED_URL=http://localhost:1234 --dart-define=ATLAS_APP_ID=w51lhvyut7

const atlasWebSocketBaseUrl = String.fromEnvironment('ATLAS_WS_URL', defaultValue: 'wss://app.atlas.so');
const atlasApiBaseUrl = String.fromEnvironment('ATLAS_API_URL', defaultValue: 'https://app.atlas.so/api');
const atlasWidgetBaseUrl = String.fromEnvironment('ATLAS_EMBED_URL', defaultValue: 'https://embed.atlas.so');
