# ReadersHaven 📖

> A mobile platform for writers and readers to create, share, and connect.

ReadersHaven is a full-stack mobile application built with Flutter and Supabase, designed as an alternative to platforms like Wattpad. It supports a full content lifecycle — from writing and publishing to community discussion and mentorship — with role-based access control and real-time features throughout.

---

## Features

### For Everyone
- Discover and read stories with genre filtering and search
- Bookmark stories and track reading progress
- Comment on stories and engage with writers
- Community forum with posts, upvotes, and threaded comments
- Public chatrooms (General, Writing Tips, Book Club)
- Direct messaging between users
- Mentor application system

### For Writers
- In-app story editor with draft saving
- Chapter management and cover image upload
- Story submission and publishing workflow (pending admin approval)

### For Admins
- Admin dashboard for content moderation
- Approve or reject story publishing applications
- Manage user access and roles
- Remove posts and stories

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile Frontend | Flutter (Dart) |
| Architecture | MVVM |
| Backend | Supabase (PostgreSQL) |
| Auth | Supabase Auth (email/password) |
| Real-time | Supabase Realtime (RealtimeChannel) |
| Storage | Supabase Storage (avatars, covers) |
| Testing | Flutter Test (unit + widget tests) |

---

## Architecture

The app follows **MVVM (Model-View-ViewModel)** — UI widgets send input to ViewModels, which interact with Models, which read/write to Supabase via the `supabase-flutter` SDK.

```
View (Flutter Widgets)
  └── ViewModel (Providers)
        └── Model (Data classes)
              └── Supabase (PostgreSQL + Realtime + Storage + Auth)
```

### Database Schema (key tables)

- `profiles` — user info, role (`reader` / `writer` / `mentor`), admin flag
- `stories` — title, genre, language, audience rating, publish status
- `chapters` — story content, linked to stories
- `bookmarks`, `reading_progress`, `comments` — reader interaction
- `direct_messages`, `messages`, `chatrooms` — real-time messaging
- `forum_posts`, `post_reactions`, `post_comments` — community features
- `role_applications` — writer/mentor upgrade requests reviewed by admins

### Security

All tables use **Row Level Security (RLS)**. Users can only access data they own. Admin permissions are granted via a security definer function to avoid recursive policy evaluation.

---

## User Roles

| Role | Capabilities |
|---|---|
| Reader | Read, bookmark, comment, chat, post |
| Writer | Everything above + write, draft, publish stories |
| Mentor | Everything above + appear in mentorship chatrooms |
| Admin | Everything above + dashboard, moderation, user management |

Role upgrades (Reader → Writer → Mentor) are applied for in-app and reviewed by admins.

---

## Testing

22 automated tests across unit and widget levels.

**Unit tests** (`test/unit/logic_test.dart`) — 15/15 passing:
- Genre filter logic (5 tests)
- Reading progress calculation (6 tests)
- Role application validation (4 tests)

**Widget tests** (`test/widget/login_test.dart`) — 5/7 passing:
- Login/signup form validation behaviour
- 2 failures due to off-screen rendering in 800×600 test environment (not a runtime issue)

---

## My Contributions

- Admin Dashboard (sole owner)
- Profile Page (sole owner)
- Home Page (70%)
- Discover Page (50%)
- Library Page (60%)
- Community Pages (50%)

---

## Getting Started

```bash
git clone https://github.com/YOUR_USERNAME/readershaven.git
cd readershaven
flutter pub get
flutter run
```

> Requires a Supabase project. Set your `SUPABASE_URL` and `SUPABASE_ANON_KEY` in your environment config.
