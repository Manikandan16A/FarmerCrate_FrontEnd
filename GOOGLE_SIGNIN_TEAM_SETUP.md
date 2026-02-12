# Google Sign-In Setup for Team Members

## Problem
Each developer has a different debug keystore → different SHA-1 → Google Sign-In fails for team members.

## Solution: Share the Same Debug Keystore

### Step 1: Copy Your Debug Keystore

**You (project owner):**

1. Copy your debug keystore from:
   - Windows: `C:\Users\YourName\.android\debug.keystore`
   - Mac/Linux: `~/.android/debug.keystore`

2. Add it to the project:
   - Place it in: `android/app/debug.keystore`

3. Commit to Git (this is safe for debug keystore only)

### Step 2: Team Members Use Shared Keystore

**Your friend:**

1. Pull the latest code
2. Copy `android/app/debug.keystore` to:
   - Windows: `C:\Users\YourName\.android\debug.keystore`
   - Mac/Linux: `~/.android/debug.keystore`
   
3. Run:
```bash
flutter clean
flutter pub get
flutter run
```

Google Sign-In will now work because everyone uses the SAME SHA-1!

## Important Notes

- ✅ Safe to share debug keystore (only for development)
- ❌ NEVER share release keystore in Git
- Your SHA-1 in Google Cloud Console: `24:61:55:93:EA:0B:94:CA:A8:D1:83:42:70:45:A7:E3:6C:92:C5:0D`
- Package name: `com.example.farmer_crate`
- Project: `farmercrate`

## For Release Builds

Keep release keystore secure and share via secure channel (not Git).
