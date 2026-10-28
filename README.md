# Recruitment HQ

> **A unified, role-based recruitment operations platform designed for UAE hiring workflows.**

[![Platform](https://img.shields.io/badge/Platform-Web%20%7C%20Desktop%20%26%20Mobile-081B33?style=for-the-badge&logo=googlechrome&logoColor=C7A45B)](https://github.com/Ajay19domi/Recruitment_HQ)
[![Backend](https://img.shields.io/badge/Backend-Supabase%20%2F%20PostgreSQL-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Deployment](https://img.shields.io/badge/Deployment-Cloudflare%20Workers-F38020?style=for-the-badge&logo=cloudflare&logoColor=white)](https://workers.cloudflare.com)
[![License](https://img.shields.io/badge/License-Proprietary-informational?style=for-the-badge)](#)

---

## 📌 Executive Summary

**Recruitment HQ** is an enterprise-grade recruitment management workspace crafted to streamline candidate sourcing, vacancy distribution, interview pipelines, and CV document management. Built to address the operational friction of scattered Excel spreadsheets, fragmented messaging apps, and lost candidate resumes, Recruitment HQ unifies end-to-end recruitment operations into a single, high-performance web platform.

The system combines zero-dependency, ultra-fast vanilla web technologies with a hardened **PostgreSQL / Supabase** backend featuring strict **Row Level Security (RLS)**, role-based access control, atomic mutations, private document storage, and real-time dashboard analytics.

---

## 🎯 The Challenge & The Solution

### The Challenge
Prior to Recruitment HQ, hiring operations across the UAE relied on disparate spreadsheets, detached CV files, and manual coordination. This resulted in:
- Unsynchronized candidate statuses across recruiters.
- Data vulnerability and missing audit trails.
- Difficulty tracking hiring pipelines across regional locations (Dubai, Abu Dhabi, Sharjah, etc.).
- High latency and friction when handling candidate CVs and scheduling interviews.

### The Solution
Recruitment HQ introduces a consolidated recruitment operations center featuring:
- **Centralized Candidate Directory**: Instant search, stage filters, and complete applicant profiles.
- **Role-Based Workspaces**: Multi-tiered permissions distinguishing Super Admin, Manager, and Recruiter tiers.
- **Integrated Vacancy Management**: Open requisition tracking tied directly to applicant counts and salary brackets.
- **Interactive Kanban Pipeline**: Visual stages from initial sourcing to interview and final selection.
- **Private Document Vault**: Authenticated CV upload, signed-URL streaming, and in-app zero-leakage PDF preview.
- **Audit Logging & Activity Streams**: Automatic database triggers logging every candidate and vacancy lifecycle change.

---

## ✨ Core Features & Capabilities

### 1. Operations Dashboard & Analytics
- **Live KPI Metric Cards**: Visual cards displaying total candidate pool, candidates in interview stage, active vacancies, and selected hires.
- **Interactive Sourcing Trends**: Dynamic SVG vector area-line charts visualizing sourcing velocity over 3-month and 6-month horizons with precise data point inspection.
- **Pipeline Health Widget**: Proportional breakdown of candidate distribution across all stages.
- **Quick Action Bar**: Direct triggers for rapid candidate onboarding, interview scheduling, and data export.

### 2. Candidate Management
- **Instant Search & Filter**: Real-time filtering across candidate names, target positions, experience levels, and locations.
- **Detailed Candidate Profiles**: Contact info, WhatsApp/phone links, notes, assigned recruiter, and status badges.
- **Recruiter Assignment**: Managers and Admins can delegate candidates to specific recruiters. Recruiters only access their assigned portfolios.

### 3. Open Vacancy Management
- **Structured Job Briefs**: Tracks job title, location, employment type (Full-time, Part-time, Contract), currency (`AED`, `INR`, `USD`), salary bands, and minimum/maximum experience requirements.
- **Automatic Pipeline Mapping**: Open vacancies dynamically link candidate applications and show real-time applicant density per requisition.
- **Managerial Controls**: Only Super Admins and Managers have authorization to post, modify, or archive vacancies.

### 4. Kanban Pipeline Tracker
- **Stage Progression Columns**: 5 defined recruitment stages:
  1. `New` — Sourced candidate leads.
  2. `Contacted` — Initial screening and recruiter outreach.
  3. `Interview` — Technical assessment and client/stakeholder rounds.
  4. `Selected` — Offer extended or accepted.
  5. `Rejected` — Archived or ineligible profiles.
- **Single-Click Inspection**: Deep links from Kanban cards straight into detailed candidate modal sheets.

### 5. Interview Calendar & Scheduling
- **Context-Aware Scheduler**: Select candidate, interview date, local time, and meeting format (Video Call, Phone Call, In-Person).
- **Automatic State Synchronization**: Scheduling an interview automatically transitions candidate status to `Interview` across the entire workspace.
- **Upcoming Agenda**: Organized chronological timeline highlighting pending conversations.

### 6. Private CV & Document Vault
- **Supported Formats**: Strictly validated PDF (`.pdf`), Word (`.doc`, `.docx`) up to 10 MB per file.
- **In-App PDF Viewer**: View resumes directly inside the dashboard using secure `Blob` Object URLs with zero external data sharing.
- **Time-Limited Signed URLs**: Documents are stored in an encrypted private Supabase bucket (`candidate-cvs`) and retrieved via expiring signed URLs.
- **Admin Document Governance**: Super Admins retain exclusive rights to permanently delete candidate CV records and underlying storage objects.

### 7. Structured Data Portability
- **Secure CSV Export**: Exports complete candidate rosters with sanitized field formatting.
- **Formula Injection Defense**: Automatically strips and escapes risky spreadsheet formulas (`=`, `+`, `-`, `@`) to protect downstream Excel users against CSV injection attacks.

### 8. Theme Engine & Responsive Architecture
- **Palette**: Built around deep navy (`#081B33`), muted gold (`#C7A45B`), and warm white (`#F6F4EE`).
- **Dark / Light Mode**: Instant one-click theme toggling with persistent user preference storage in `localStorage`.
- **Mobile-First UX**: Responsive drawer sidebar, accessible modal focus trapping (`Escape`, `Tab` navigation), and universal shortcut search (`Ctrl + K` / `Cmd + K`).

---

## 🔐 Security & Role-Based Access Control (RBAC)

Recruitment HQ implements defense-in-depth security enforced at both the UI layer and PostgreSQL database level via Row Level Security (RLS).

| Capability | Super Admin (`admin`) | Manager (`manager`) | Recruiter (`recruiter`) |
|:---|:---:|:---:|:---:|
| **View All Candidates** | ✅ Full Access | ✅ Full Access | 🔒 Assigned Only |
| **Create Candidates** | ✅ Yes | ✅ Yes | ✅ Yes (Auto-assigned) |
| **Edit Candidates** | ✅ Full Access | ✅ Full Access | 🔒 Assigned Only |
| **Reassign Candidate Owner** | ✅ Yes | ✅ Yes | ❌ Denied |
| **Delete Candidate Records** | ✅ Yes | ❌ Denied | ❌ Denied |
| **Manage Vacancies** | ✅ Yes | ✅ Yes | 👁️ Read-Only |
| **Delete Vacancies** | ✅ Yes | ❌ Denied | ❌ Denied |
| **Upload / View Candidate CVs** | ✅ Yes | ✅ Yes | 🔒 Assigned Only |
| **Delete Candidate CVs** | ✅ Yes | ❌ Denied | ❌ Denied |
| **User Role & Access Management** | ✅ Yes | ❌ Denied | ❌ Denied |

### Row Level Security (RLS) Highlights:
- **`profiles` table**: Users can view their own profile; Admins & Managers can view team profiles; only Admins can alter roles or active status.
- **`candidates` table**: Recruiter visibility is strictly bounded by `assigned_to = auth.uid()`. Database triggers guard against recruiters altering candidate creation metadata or reassigning owners.
- **`vacancies` table**: Read permissions granted to active team members; creation/editing restricted to `admin` and `manager`; deletions restricted to `admin`.
- **`storage.objects` & `candidate_cvs`**: Storage buckets are private; read/write access validates candidate assignment; file deletion requires `admin` privileges.
- **Atomic Transactions (`save_changes` RPC)**: Batch mutations execute inside an invoker-security PostgreSQL function ensuring multi-record consistency under caller RLS policies.

---

## 🛠️ Technology Stack

| Domain | Technology / Specification |
|:---|:---|
| **Frontend Runtime** | Modern Vanilla JavaScript (ES6+ Modules, zero bundle dependencies) |
| **UI Styling** | Vanilla CSS3, CSS Custom Properties (Design Tokens), Flexbox / Grid |
| **Typography** | `DM Sans` & `Inter` via Google Fonts |
| **Database & Auth** | [Supabase](https://supabase.com) (PostgreSQL 15+, Supabase Auth, Row Level Security) |
| **Cloud Storage** | Supabase Storage (`candidate-cvs` private bucket, signed URLs) |
| **Hosting & Edge** | [Cloudflare Workers](https://workers.cloudflare.com) / Static Web Hosting |
| **Data Interchange** | REST API via PostgREST, JSON RPC, RFC 4180 CSV |

---

## 📂 Project Directory Structure

```plaintext
Recruitment_HQ/
├── index.html              # Main application shell, markup, semantic layout & dialogs
├── setup.html              # Visual database & Super Admin setup onboarding guide
├── style.css               # Core styling, responsive typography, layout rules & animations
├── theme.css               # Design system tokens, color palettes, dark/light theme overrides
├── app.js                  # Frontend core: state store, router, UI rendering, CSV export, dialogs
├── backend.js              # Supabase API client, authentication lifecycle, RLS UI permissions
├── vacancies.js            # Vacancy management, job filtering, salary formatting & pipeline binding
├── cv.js                   # Private CV upload pipeline, MIME validation, signed URLs, PDF viewer
├── analytics.js            # Sourcing analytics engine, timeline aggregation & dynamic SVG charts
├── appearance.js           # Theme toggle controller, SVG icon system & DOM mutation observer
├── mobile.js               # Mobile drawer navigation, keyboard trap, accessibility & profile menu
├── setup.sql               # Base database migration: profiles, candidates, interviews, RLS policies
├── vacancies.sql           # Vacancy schema migration: vacancies table, constraints, audit triggers
├── cv-uploads.sql          # Storage bucket configuration, CV metadata table & security policies
├── cv-permissions-fix.sql  # Storage folder prefix resolution fix for authenticated CV uploads
├── .gitignore              # Git ignore rules for system, IDE, and temporary files
└── README.md               # Comprehensive project documentation & architecture guide
```

---

## 🚀 Getting Started & Setup Guide

### 1. Local Development
Because Recruitment HQ is engineered with zero build tools or complex bundler dependencies, you can run it using any local static file server:

```bash
# Using Python 3
python -m http.server 8080

# Or using Node.js npx serve
npx serve .

# Or using PHP
php -S localhost:8080
```
Open `http://localhost:8080` in your browser.

> **Offline / Demo Mode**: The application includes a self-contained local demo workspace (`localStorage`) allowing instant UI inspection without connecting Supabase credentials.

---

### 2. Supabase Backend Setup

To connect Recruitment HQ to your own live database backend:

#### Step A: Configure Credentials
In [`backend.js`](backend.js), update the Supabase endpoint and publishable key:
```javascript
const SB_URL = 'https://YOUR_PROJECT_ID.supabase.co';
const SB_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

#### Step B: Run Database Migrations
Open your Supabase Project Dashboard, navigate to **SQL Editor**, and run the migration scripts in the following order:

1. **[`setup.sql`](setup.sql)**:
   - Sets up `profiles`, `candidates`, `interviews`, and `activity` audit tables.
   - Creates `team_role()`, `new_profile()` auth trigger, and `save_changes()` RPC.
   - Configures comprehensive Row Level Security (RLS) rules.

2. **[`vacancies.sql`](vacancies.sql)**:
   - Creates `vacancies` table with salary/experience validation.
   - Adds `vacancy_id` foreign key linkage to `candidates`.
   - Adds vacancy audit triggers and updates `save_changes()`.

3. **[`cv-uploads.sql`](cv-uploads.sql)**:
   - Configures private `candidate-cvs` storage bucket (10 MB limit).
   - Creates `candidate_cvs` metadata table with RLS.
   - Configures storage object security policies.

4. *(Optional / If needed)* **[`cv-permissions-fix.sql`](cv-permissions-fix.sql)**:
   - Applies folder path prefix resolution for storage policies.

---

### 3. Provisioning the Super Admin Account

1. In Supabase Dashboard, go to **Authentication** → **Users** → **Add user**.
2. Create your user account with your desired email and password.
3. In **SQL Editor**, elevate your user account to Super Admin:
   ```sql
   UPDATE public.profiles
   SET role = 'admin', active = true, name = 'Your Name'
   WHERE id = (SELECT id FROM auth.users WHERE email = 'your-email@example.com');
   ```
4. Sign in via the Recruitment HQ login modal. Your live, synchronized workspace is now active!

---

### 4. Deploying to Cloudflare Workers / Static Web

Recruitment HQ can be deployed across global edge networks in seconds:

#### Option A: Cloudflare Workers / Pages
- Connect your GitHub repository to Cloudflare Pages.
- Build command: *(leave empty)*
- Build output directory: `.` (root directory)
- Click **Save and Deploy**.

#### Option B: Any Static Host (Vercel, Netlify, GitHub Pages, AWS S3)
- Point the static deploy root to this folder. All assets, scripts, and stylesheets will load instantly with edge caching.

---

## ⌨️ Accessibility & Keyboard Shortcuts

- <kbd>Ctrl</kbd> + <kbd>K</kbd> / <kbd>Cmd</kbd> + <kbd>K</kbd> — Instant candidate search.
- <kbd>Esc</kbd> — Dismiss open dialogs, candidate detail sheets, or mobile drawer.
- <kbd>Tab</kbd> / <kbd>Shift</kbd> + <kbd>Tab</kbd> — Trapped focus navigation within modals and sidebar.
- <kbd>Enter</kbd> / <kbd>Space</kbd> — Select and inspect candidate cards and table rows.

---

## 📄 License & Case Study Notice

*This repository contains the production code and architecture for **Recruitment HQ**.*  
Designed & Developed by **Ajay Prakashan** (2026).  
All rights reserved. Proprietary enterprise software.
