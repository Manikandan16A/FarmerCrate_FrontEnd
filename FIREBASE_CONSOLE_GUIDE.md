# Firebase Console Setup for Google Sign-In

Project: `farmercrate-c62de`

## Step 1: Enable Google Sign-In (2 min)

1. Go to https://console.firebase.google.com/
2. Select project: `farmercrate-c62de`
3. Authentication → Sign-in method
4. Click "Google" → Toggle Enable
5. Select support email → Save

## Step 2: Configure OAuth Consent Screen (5 min)

1. Go to https://console.cloud.google.com/
2. Select project: `farmercrate-c62de`
3. ☰ Menu → APIs & Services → OAuth consent screen
4. Select "External" → CREATE (if first time)

**Page 1 - App Information:**
- App name: `Farmer Crate`
- User support email: Your email
- Developer contact: Your email
- Click SAVE AND CONTINUE

**Page 2 - Scopes:**
- Click ADD OR REMOVE SCOPES
- Check: `.../auth/userinfo.email`, `.../auth/userinfo.profile`, `openid`
- Click UPDATE → SAVE AND CONTINUE

**Page 3 - Test Users:**
- Click + ADD USERS
- Enter test emails (one per line)
- Click ADD → SAVE AND CONTINUE

**Page 4 - Summary:**
- Click BACK TO DASHBOARD

✅ Done! Test your app.
