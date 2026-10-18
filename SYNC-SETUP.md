# Cloud sync setup (about 5 minutes, free)

Iron Records can keep your Mac and iPhone in step using a free [Supabase](https://supabase.com) project. Your data lives in **your own** project, protected by your login.

## One-time setup

1. **Create a project.** Sign in at supabase.com → *New project*. Name it `iron-records`, choose a region near you (e.g. West EU / London), set a database password (save it somewhere; the app doesn't need it), free plan.
2. **Create the table.** Wait for the project to finish setting up, then open **SQL Editor → New query**, paste the whole of [`supabase-setup.sql`](supabase-setup.sql), and press **Run**. You should see "Success. No rows returned".
3. **Let yourself sign in straight away.** **Authentication → Sign In / Providers → Email** (the menu wording varies slightly): turn **off** "Confirm email" and save.
4. **Copy two values.** **Project Settings → API** (or *API Keys*): copy the **Project URL** and the **anon / publishable** key. Never use the *service_role* / *secret* key.
5. **Connect the app.** In Iron Records open **Data → Cloud sync**, paste the address and key, enter an email and a password, and press **Create account**. It uploads your data straight away.
6. **Lock the door behind you.** Back in Supabase: **Authentication → Sign In / Providers** and turn **off** "Allow new users to sign up", so nobody else can create an account on your project.

## Each extra device (iPhone, other browsers)

On a connected device: **Data → Cloud sync → Copy setup code**. On the new device: paste it into *Setup code*, enter the same email and password, and press **Sign in**. It downloads your data and keeps itself in step from then on.

## How it behaves

- Changes upload a few seconds after you make them, and download when you open the app or come back to it.
- Works offline; it catches up when you're back online.
- Two devices edited at once: workout logs are merged session by session (newest edit of each session wins), saved programmes and archived blocks are combined, and if you edited the **plan** on both before they synced, the most recent plan edit wins. Logged sets are never dropped by a merge.
- The cloud keeps up to 100 snapshots of older versions (at most one every 30 minutes) in `bp5_history` as a safety net.

## If something goes wrong

- "the cloud table is missing" → step 2 wasn't run (or was run in another project).
- "Invalid login credentials" → wrong email or password; reset the password under **Authentication → Users** in Supabase.
- To restore a snapshot, find its `id` in **Table editor → bp5_history**, then in the SQL editor run:
  `update public.bp5_state set data = (select data from public.bp5_history where id = <ID>), rev = rev + 1;`
  and open the app on each device.

The anon key is designed to be public: it can do nothing except what your row level security rules allow, and those only let you read and change your own row.
