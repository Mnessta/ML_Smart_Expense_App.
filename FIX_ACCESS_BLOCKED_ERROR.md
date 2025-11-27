# 🚨 Fix: "Access blocked: This app's request is invalid"

## What This Error Means

This error occurs when Google OAuth consent screen is not properly configured or the app is in "Testing" mode without your email as a test user.

## ⚡ Quick Fix Steps

### Step 1: Go to Google Cloud Console
1. Go to: https://console.cloud.google.com/
2. Select your project
3. Go to **APIs & Services** → **OAuth consent screen**

### Step 2: Configure OAuth Consent Screen

**If you haven't set it up yet:**
1. Choose **"External"** (unless you have Google Workspace)
2. Click **"Create"**
3. Fill in **required fields**:
   - **App name**: `ML Smart Expense Tracker`
   - **User support email**: Your email address
   - **Developer contact information**: Your email address
4. Click **"Save and Continue"**

### Step 3: Add Scopes
1. On the **Scopes** page, click **"Add or Remove Scopes"**
2. Check these scopes:
   - ✅ `email`
   - ✅ `profile`
   - ✅ `openid`
3. Click **"Update"**
4. Click **"Save and Continue"**

### Step 4: Add Test Users (CRITICAL!)
1. On the **Test users** page:
   - Click **"+ Add Users"**
   - **Add your email address** (the one you'll use to sign in)
   - Add any other emails that need to test
   - Click **"Add"**
2. Click **"Save and Continue"**
3. Review and click **"Back to Dashboard"**

### Step 5: Publish App (Optional but Recommended)

**Option A: Keep in Testing Mode** (Easier for now)
- Keep app in "Testing" mode
- Make sure your email is added as a test user
- Only test users can sign in

**Option B: Publish App** (For production)
1. Go back to **OAuth consent screen**
2. Click **"PUBLISH APP"** button at the top
3. Confirm the publishing
4. **Note**: This makes the app available to anyone, but you can still limit it

### Step 6: Verify Configuration
- ✅ OAuth consent screen is configured
- ✅ Scopes are added (email, profile, openid)
- ✅ Your email is added as a test user (if in Testing mode)
- ✅ App is published (if you want anyone to use it)

### Step 7: Test Again
1. Close the app completely
2. Reopen the app
3. Try "Continue with Google" again
4. Use the **same email** that you added as a test user

## 🔍 Common Issues

### Issue: "Access blocked" even after adding test user
**Solution:**
- Make sure you're signing in with the **exact email** you added as a test user
- Wait 1-2 minutes after adding test users (changes take time to propagate)
- Try clearing browser cache or using incognito mode

### Issue: Can't find "Test users" page
**Solution:**
- Make sure you're on the **OAuth consent screen** page
- Scroll down - the Test users section is near the bottom
- If app is already published, you may need to unpublish first to add test users

### Issue: Want to allow anyone to sign in
**Solution:**
1. Go to OAuth consent screen
2. Click **"PUBLISH APP"**
3. Confirm publishing
4. Now anyone can sign in (no test users needed)

## ✅ Verification Checklist

- [ ] OAuth consent screen is configured
- [ ] App name, support email, and developer email are filled
- [ ] Scopes added: email, profile, openid
- [ ] **Your email is added as a test user** (if in Testing mode)
- [ ] App is published (if you want public access)
- [ ] You're signing in with the email you added as a test user

## 🎯 Expected Result

After fixing:
1. Tap "Continue with Google"
2. Browser opens
3. **No "Access blocked" error** ✅
4. Google sign-in page appears
5. Sign in successfully
6. Redirected back to app
7. Logged in! ✅

---

**Most Common Fix**: Add your email as a test user in Google Cloud Console → OAuth consent screen → Test users


