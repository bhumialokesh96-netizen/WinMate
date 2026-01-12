# WinMate Database Entity Relationship Diagram (ERD)

## Visual Schema Overview

This document provides visual representations of the WinMate database schema relationships.

---

## Complete ERD (All Tables)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          WINMATE DATABASE SCHEMA                             │
│                         PostgreSQL via Supabase                              │
└─────────────────────────────────────────────────────────────────────────────┘


┌──────────────────────────────┐
│         users                │  ← Core Table (Referenced by many)
├──────────────────────────────┤
│ PK  id (UUID)                │
│ UQ  phone                    │
│ UQ  invite_code              │
│     referrer_code  ───┐      │  ← Self-referencing (referral tree)
│     device_id         │      │
│     balance           │      │
│     spins_available   │      │
│     total_sms_sent    │      │
│     total_invites     │      │
│     total_earn        │      │
│     created_at        │      │
│     updated_at        │      │
└───────────┬───────────┴──────┘
            │           └──────────────┐
            │                          ↓
            │              ┌──────────────────────┐
            │              │   Referral Tree      │
            │              │  (Self-Reference)    │
            │              └──────────────────────┘
            │
            ├─────────────────────────────────────────────┐
            │                                             │
            ↓                                             ↓
┌────────────────────────┐                  ┌────────────────────────┐
│     sms_tasks          │                  │     withdrawals        │
├────────────────────────┤                  ├────────────────────────┤
│ PK  id                 │                  │ PK  id                 │
│ FK  user_id  ──────────┼──────────────────┼─→   user_id            │
│     status             │                  │     amount             │
│     amount             │                  │     upi_id             │
│     sim_slot           │                  │     status             │
│     created_at         │                  │     created_at         │
│     completed_at       │                  │     processed_at       │
└────────────────────────┘                  │     admin_notes        │
                                            └────────────────────────┘
            ↓
┌────────────────────────┐
│    sim_settings        │
├────────────────────────┤
│ PK  id                 │
│ FK  user_id  ──────────┤
│     sim_slot           │  ← UNIQUE(user_id, sim_slot)
│     sim_name           │
│     daily_limit        │
│     sent_today         │
│     is_active          │
│     created_at         │
│     updated_at         │
└────────────────────────┘

            ↓
┌────────────────────────┐
│       invites          │
├────────────────────────┤
│ PK  id                 │
│ FK  user_id  ──────────┤  ← Inviter
│     invited_email      │
│     invited_at         │
│     is_joined          │
│ FK  joined_user_id ────┤  ← Invitee (when joined)
└────────────────────────┘


┌──────────────────────────────────────────────────────────────┐
│           INDEPENDENT TABLES (No Foreign Keys)               │
└──────────────────────────────────────────────────────────────┘

┌────────────────────────┐   ┌────────────────────────┐
│    wheel_prizes        │   │         faqs           │
├────────────────────────┤   ├────────────────────────┤
│ PK  id                 │   │ PK  id                 │
│     name               │   │     category           │
│     type               │   │     question           │
│     value              │   │     answer             │
│     probability        │   │     priority           │
│     color              │   │     is_visible         │
│     icon               │   │     created_at         │
│     is_active          │   │     updated_at         │
│     created_at         │   └────────────────────────┘
│     updated_at         │
└────────────────────────┘

┌────────────────────────┐   ┌────────────────────────┐
│ system_notifications   │   │    support_links       │
├────────────────────────┤   ├────────────────────────┤
│ PK  id                 │   │ PK  id                 │
│     title              │   │     whatsapp_link      │
│     message            │   │     telegram_link      │
│     type               │   │     email              │
│     is_active          │   │     phone              │
│     created_at         │   │     website            │
│     expires_at         │   │     updated_at         │
└────────────────────────┘   └────────────────────────┘
                             (Single Row Config)
```

---

## Relationship Cardinality

### One-to-Many (1:N) Relationships

```
users (1) ──────→ (N) sms_tasks
users (1) ──────→ (N) withdrawals
users (1) ──────→ (2) sim_settings    [Max 2: slot 0 & 1]
users (1) ──────→ (N) invites          [as inviter]
```

### Self-Referencing Relationship

```
        ┌──────────────┐
        │    users     │
        └──────┬───────┘
               │
    referrer_code
               │
               ↓
        ┌──────────────┐
        │    users     │
        │ (invite_code)│
        └──────────────┘

Example:
User A (invite_code: WM1234) refers User B
User B (referrer_code: WM1234, invite_code: WM5678) refers User C
User C (referrer_code: WM5678, invite_code: WM9012)

Forms multi-level referral tree
```

---

## Data Flow Diagrams

### 1. User Registration & Referral Flow

```
┌─────────┐
│ Client  │
└────┬────┘
     │
     │ 1. validateInviteCode(referrer_code)
     ├───────────────────────────────────────────────┐
     │                                               │
     │                                  ┌────────────▼─────────┐
     │                                  │       users          │
     │                                  │  WHERE invite_code = │
     │                                  │    referrer_code     │
     │                                  └────────────┬─────────┘
     │                                               │
     │ 2. ◄──── Valid? ───────────────────────────────┘
     │
     │ 3. createAuthUser(phone, password)
     ├───────────────────────────────────────────────┐
     │                                               │
     │                                  ┌────────────▼─────────┐
     │                                  │   Supabase Auth      │
     │                                  │  (email/password)    │
     │                                  └────────────┬─────────┘
     │                                               │
     │ 4. ◄──── Auth ID ──────────────────────────────┘
     │
     │ 5. INSERT INTO users
     │    (id, phone, invite_code, referrer_code, ...)
     ├───────────────────────────────────────────────┐
     │                                               │
     │                                  ┌────────────▼─────────┐
     │                                  │       users          │
     │                                  │   + New User Row     │
     │                                  └──────────────────────┘
     │
     └──── Registration Complete
```

### 2. SMS Mining & Balance Update Flow

```
┌─────────────┐
│ Mining App  │
└──────┬──────┘
       │
       │ 1. Check daily limit
       ├────────────────────────────────────────┐
       │                                        │
       │                           ┌────────────▼──────────┐
       │                           │    sim_settings       │
       │                           │  WHERE user_id = X    │
       │                           │  AND sim_slot = 0     │
       │                           └────────────┬──────────┘
       │                                        │
       │ 2. ◄──── sent_today < daily_limit ─────┘
       │
       │ 3. Send SMS (Native Android)
       │
       │ 4. INSERT INTO sms_tasks (status='sent', amount=2.0)
       ├────────────────────────────────────────┐
       │                                        │
       │                           ┌────────────▼──────────┐
       │                           │      sms_tasks        │
       │                           │    + New Task Row     │
       │                           └───────────────────────┘
       │
       │ 5. UPDATE users SET balance = balance + 2.0
       │              SET total_sms_sent = total_sms_sent + 1
       ├────────────────────────────────────────┐
       │                                        │
       │                           ┌────────────▼──────────┐
       │                           │        users          │
       │                           │   Balance Updated     │
       │                           └───────────────────────┘
       │
       │ 6. UPDATE sim_settings SET sent_today = sent_today + 1
       ├────────────────────────────────────────┐
       │                                        │
       │                           ┌────────────▼──────────┐
       │                           │    sim_settings       │
       │                           │   Counter Updated     │
       │                           └───────────────────────┘
       │
       └──── Mining Complete (+₹2.00)
```

### 3. Withdrawal Request Flow

```
┌──────────┐
│  Wallet  │
└────┬─────┘
     │
     │ 1. Check balance >= amount
     ├────────────────────────────────────────┐
     │                                        │
     │                           ┌────────────▼──────────┐
     │                           │        users          │
     │                           │  WHERE id = user_id   │
     │                           └────────────┬──────────┘
     │                                        │
     │ 2. ◄──── balance = X ───────────────────┘
     │
     │ 3. UPDATE users SET balance = balance - amount
     ├────────────────────────────────────────┐
     │                                        │
     │                           ┌────────────▼──────────┐
     │                           │        users          │
     │                           │   Balance Deducted    │
     │                           └───────────────────────┘
     │
     │ 4. INSERT INTO withdrawals
     │    (user_id, amount, upi_id, status='pending')
     ├────────────────────────────────────────┐
     │                                        │
     │                           ┌────────────▼──────────┐
     │                           │     withdrawals       │
     │                           │  + Pending Request    │
     │                           └───────────────────────┘
     │
     └──── Withdrawal Requested
              │
              │ (Later: Admin approval)
              ↓
     ┌────────────────────┐
     │  UPDATE withdrawals│
     │  SET status =      │
     │  'approved' or     │
     │  'rejected'        │
     └────────────────────┘
```

---

## Table Dependencies Graph

```
┌─────────────────────────────────────────────────────────┐
│               DEPENDENCY HIERARCHY                      │
└─────────────────────────────────────────────────────────┘

LEVEL 0 (No Dependencies):
├── wheel_prizes
├── faqs
├── system_notifications
└── support_links

LEVEL 1 (Depends on users only):
└── users ────┐
              │
LEVEL 2 (Depends on LEVEL 1):
              ├── sms_tasks
              ├── withdrawals
              ├── sim_settings
              └── invites

CASCADE DELETE IMPLICATIONS:
If users.id is deleted:
├─> All sms_tasks for that user
├─> All withdrawals for that user
├─> All sim_settings for that user
└─> All invites (both as inviter and invitee)
```

---

## Index Coverage Map

```
┌──────────────────────────────────────────────────────────┐
│                  INDEXED COLUMNS                         │
└──────────────────────────────────────────────────────────┘

users:
├── PRIMARY: id
├── UNIQUE:  phone
├── UNIQUE:  invite_code
├── INDEX:   referrer_code        [For referral tree lookups]
├── INDEX:   created_at DESC      [For registration timeline]
└── INDEX:   total_earn DESC      [For leaderboard queries]

sms_tasks:
├── PRIMARY: id
├── INDEX:   user_id              [Foreign key]
├── INDEX:   status               [Filter by status]
├── INDEX:   created_at DESC      [Chronological sorting]
└── INDEX:   (user_id, status)    [Composite for user history]

withdrawals:
├── PRIMARY: id
├── INDEX:   user_id              [Foreign key]
├── INDEX:   status               [Filter pending/approved]
├── INDEX:   created_at DESC      [Chronological sorting]
└── INDEX:   (user_id, status)    [Composite for user history]

sim_settings:
├── PRIMARY: id
├── INDEX:   user_id              [Foreign key]
└── UNIQUE:  (user_id, sim_slot)  [Composite unique constraint]

invites:
├── PRIMARY: id
├── INDEX:   user_id              [Inviter lookup]
├── INDEX:   invited_email        [Check duplicates]
└── INDEX:   joined_user_id       [Invitee lookup]

wheel_prizes:
├── PRIMARY: id
├── INDEX:   is_active            [Filter active prizes]
└── INDEX:   probability DESC     [Ordered selection]

faqs:
├── PRIMARY: id
├── INDEX:   category             [Category filtering]
├── INDEX:   priority ASC         [Sort order]
└── INDEX:   is_visible           [Published filter]

system_notifications:
├── PRIMARY: id
├── INDEX:   is_active            [Filter active]
├── INDEX:   created_at DESC      [Chronological]
└── INDEX:   expires_at           [Check expiration]

support_links:
└── PRIMARY: id                   [Single row, no indexes needed]
```

---

## Query Optimization Patterns

### Pattern 1: User Dashboard (Most Common)
```sql
-- Single query with all needed data
SELECT 
  id, phone, balance, spins_available, 
  total_sms_sent, total_invites
FROM users
WHERE id = $1;

-- Indexes used:
-- ✓ PRIMARY KEY on id
```

### Pattern 2: Transaction History
```sql
-- Income (from SMS)
SELECT created_at, status, 2.0 as amount
FROM sms_tasks
WHERE user_id = $1 AND status = 'sent'
ORDER BY created_at DESC;

-- Expenses (withdrawals)
SELECT created_at, amount, status
FROM withdrawals
WHERE user_id = $1
ORDER BY created_at DESC;

-- Indexes used:
-- ✓ idx_sms_tasks_user_status (user_id, status)
-- ✓ idx_withdrawals_user_id
-- ✓ idx_sms_tasks_created_at DESC
-- ✓ idx_withdrawals_created_at DESC
```

### Pattern 3: Leaderboard
```sql
SELECT phone, total_earn
FROM users
ORDER BY total_earn DESC
LIMIT 10;

-- Index used:
-- ✓ idx_users_total_earn DESC
```

### Pattern 4: Referral Tree
```sql
-- Get direct referrals
SELECT id, phone, created_at
FROM users
WHERE referrer_code = $1
ORDER BY created_at DESC;

-- Index used:
-- ✓ idx_users_referrer_code
```

---

## Related Documentation

- **Full Schema Details**: [database_schema.md](./database_schema.md)
- **Quick Reference**: [DATABASE_SCHEMA_SUMMARY.md](./DATABASE_SCHEMA_SUMMARY.md)
- **Implementation Guide**: [implementation_guide.md](./implementation_guide.md)

---

**Last Updated**: 2026-01-12  
**Version**: 2.0  
**Format**: ASCII ERD (Universal Compatibility)
