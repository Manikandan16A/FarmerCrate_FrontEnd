# Google Sign-In Setup Guide

## Backend Setup (Required)

Your backend needs to handle Google authentication. Add this endpoint:

**POST** `/api/auth/google`

**Request Body:**
```json
{
  "idToken": "google_id_token",
  "email": "user@example.com",
  "name": "User Name"
}
```

**Response (Success - 200):**
```json
{
  "token": "jwt_token",
  "user": {
    "id": 1,
    "name": "User Name",
    "email": "user@example.com",
    "role": "customer"
  }
}
```

## Android Setup

1. **Get SHA-1 Certificate Fingerprint:**
   ```bash
   cd android
   ./gradlew signingReport
   ```

2. **Go to Google Cloud Console:**
   - Visit: https://console.cloud.google.com/
   - Create a new project or select existing one
   - Enable "Google+ API"

3. **Create OAuth 2.0 Credentials:**
   - Go to "Credentials" → "Create Credentials" → "OAuth client ID"
   - Select "Android"
   - Enter package name: `com.example.farmer_crate` (check android/app/build.gradle)
   - Enter SHA-1 fingerprint from step 1
   - Click "Create"

4. **Update android/app/build.gradle:**
   ```gradle
   defaultConfig {
       applicationId "com.example.farmer_crate"
       minSdkVersion 21  // Must be at least 21
   }
   ```

## iOS Setup

1. **Go to Google Cloud Console:**
   - Create OAuth client ID for iOS
   - Enter iOS bundle ID (check ios/Runner/Info.plist)

2. **Update ios/Runner/Info.plist:**
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleTypeRole</key>
           <string>Editor</string>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
           </array>
       </dict>
   </array>
   ```

3. **Update ios/Podfile:**
   ```ruby
   platform :ios, '12.0'  # Minimum iOS 12
   ```

## Web Setup (Optional)

1. Create OAuth client ID for Web application
2. Add authorized JavaScript origins
3. Update `web/index.html`:
   ```html
   <meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com">
   ```

## Testing

Run the app and click "Continue with Google" button on the sign-in page.

## Troubleshooting

- **Error: PlatformException(sign_in_failed)**: Check SHA-1 certificate is correct
- **Error: 10**: OAuth client not configured properly
- **No response**: Backend endpoint not implemented
