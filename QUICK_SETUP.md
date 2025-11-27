# 🚀 Quick Supabase Setup - 4 Steps

## ⚠️ IMPORTANT: You need to do Steps 1-2 manually in Supabase Dashboard

---

## Step 1: Create Supabase Project & Get Credentials

### 1.1 Create Project
1. Go to: https://supabase.com/dashboard
2. Click **"New Project"**
3. Fill in:
   - **Name**: `ML Smart Expense Tracker`
   - **Database Password**: (Save this password!)
   - **Region**: Choose closest to you
4. Click **"Create new project"**
5. Wait 2-3 minutes for setup

### 1.2 Get Your Credentials
1. In dashboard, click **Settings** (gear icon) → **API**
2. Find these two values:
   - **Project URL**: `https://xxxxx.supabase.co` 
   - **anon public key**: Long string starting with `eyJ...`
3. **Copy both** - you'll need them in Step 4

---

## Step 2: Run Database Schema

1. In Supabase dashboard, click **SQL Editor** (left sidebar)
2. Click **"New query"**
3. Open the file `supabase_schema.sql` from this project
4. **Copy ALL the SQL code** from that file
5. **Paste it** into the SQL Editor
6. Click **"Run"** (or press Ctrl+Enter / Cmd+Enter)
7. You should see: ✅ **"Success. No rows returned"**

---

## Step 3: Update Configuration File

**I'll help you with this once you provide your credentials!**

Open: `lib/config/supabase_config.dart`

Replace:
- `YOUR_SUPABASE_URL` → Your Project URL from Step 1.2
- `YOUR_SUPABASE_ANON_KEY` → Your anon key from Step 1.2

---

## Step 4: Test Connection

Run this command to test:
```bash
flutter run
```

Check the console output - you should see:
```
✅ Supabase initialized successfully
```

If you see warnings, the config needs updating.

---

## 📋 Checklist

- [ ] Step 1: Created Supabase project and got credentials
- [ ] Step 2: Ran SQL schema in Supabase SQL Editor
- [ ] Step 3: Updated `lib/config/supabase_config.dart` with credentials
- [ ] Step 4: Tested connection - app runs without errors

---

## 🆘 Need Help?

If you get stuck:
1. Check `SUPABASE_SETUP.md` for detailed instructions
2. Verify credentials in Supabase Dashboard → Settings → API
3. Check console for error messages














