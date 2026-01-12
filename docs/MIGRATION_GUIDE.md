# Migration Guide for Database Schema v2.0

This guide helps developers migrate from the previous database implementation to the new schema v2.0.

## Overview

Schema v2.0 introduces:
- Proper UUID support with uuid-ossp extension
- Automatic timestamp triggers for updated_at columns
- Complete set of Flutter models for all tables
- Enhanced SupabaseService with methods for all operations
- Row-Level Security (RLS) policies for data protection
- Performance-optimized indexes

## Step-by-Step Migration

### Step 1: Backup Your Data

Before making any changes:

```sql
-- In Supabase SQL Editor, backup your data
-- Example for users table
SELECT * FROM users;
-- Export as CSV or JSON from Supabase dashboard
```

### Step 2: Deploy the New Schema

1. Open Supabase Dashboard
2. Navigate to SQL Editor
3. Copy contents from `supabase/schema_v2.sql`
4. Execute the SQL

The schema uses `IF NOT EXISTS` clauses, so it won't break existing tables.

### Step 3: Verify Schema Deployment

Check that all components are in place:

```sql
-- Check tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Check triggers exist
SELECT trigger_name, event_object_table 
FROM information_schema.triggers 
WHERE trigger_schema = 'public';

-- Check indexes exist
SELECT indexname, tablename 
FROM pg_indexes 
WHERE schemaname = 'public' 
ORDER BY tablename, indexname;

-- Check RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';
```

### Step 4: Update Your Flutter Code

#### A. Import New Models

Add imports for the new models where needed:

```dart
// Add these imports to files that need them
import 'package:SMSindia/models/task_model.dart';
import 'package:SMSindia/models/withdrawal_model.dart';
import 'package:SMSindia/models/sim_settings_model.dart';
import 'package:SMSindia/models/invite_model.dart';
import 'package:SMSindia/models/wheel_prize_model.dart';
import 'package:SMSindia/models/faq_model.dart';
import 'package:SMSindia/models/system_notification_model.dart';
import 'package:SMSindia/models/support_links_model.dart';
```

#### B. Update UserModel Usage

The UserModel now includes `totalEarn` field:

**Before:**
```dart
final user = UserModel(
  id: id,
  phone: phone,
  inviteCode: inviteCode,
  referrerCode: referrerCode,
  balance: balance,
  spinsAvailable: spins,
  totalSms: sms,
  totalInvites: invites,
);
```

**After:**
```dart
final user = UserModel(
  id: id,
  phone: phone,
  inviteCode: inviteCode,
  referrerCode: referrerCode,
  balance: balance,
  spinsAvailable: spins,
  totalSms: sms,
  totalInvites: invites,
  totalEarn: totalEarn, // New field
);
```

#### C. Use SupabaseService Methods

Replace direct Supabase client calls with service methods:

**Before:**
```dart
// Direct database call
final data = await supabase
    .from('sms_tasks')
    .select()
    .eq('user_id', userId);
```

**After:**
```dart
// Using SupabaseService
final supabaseService = SupabaseService();
final data = await supabaseService.getUserSmsTasks(userId);

// Parse into models
final tasks = data?.map((json) => TaskModel.fromJson(json)).toList();
```

### Step 5: Update Registration Flow

Update your register screen to use the new validation:

**Before:**
```dart
// Direct signup without validation
await supabase.auth.signUp(
  email: email,
  password: password,
);
```

**After:**
```dart
// Using SupabaseService with validation
final supabaseService = SupabaseService();

// Validate referrer code first
final isValid = await supabaseService.validateInviteCode(referrerCode);
if (!isValid) {
  // Show error
  return;
}

// Register user
final error = await supabaseService.registerUser(
  phone: phone,
  password: password,
  parentInviteCode: referrerCode,
);

if (error != null) {
  // Show error
} else {
  // Success
}
```

### Step 6: Implement SMS Task Tracking

Use the new SMS task methods:

```dart
final supabaseService = SupabaseService();

// Create task when SMS is sent
await supabaseService.createSmsTask(
  userId: currentUser.id,
  simSlot: 0, // or 1
);

// Update task status
await supabaseService.updateSmsTaskStatus(
  taskId: taskId,
  status: 'sent', // or 'failed'
);

// Get user's tasks
final tasks = await supabaseService.getUserSmsTasks(currentUser.id);
```

### Step 7: Implement Withdrawal Flow

Use the new withdrawal methods:

```dart
final supabaseService = SupabaseService();

// Create withdrawal request
final error = await supabaseService.createWithdrawal(
  userId: currentUser.id,
  amount: amount,
  upiId: upiId,
);

// Get user's withdrawals
final withdrawals = await supabaseService.getUserWithdrawals(currentUser.id);
final models = withdrawals?.map((json) => 
    WithdrawalModel.fromJson(json)).toList();
```

### Step 8: Implement SIM Settings

Use the new SIM settings methods:

```dart
final supabaseService = SupabaseService();

// Get SIM settings
final settings = await supabaseService.getSimSettings(currentUser.id);
final models = settings?.map((json) => 
    SimSettingsModel.fromJson(json)).toList();

// Update SIM settings
await supabaseService.upsertSimSettings(
  userId: currentUser.id,
  simSlot: 0,
  simName: 'Jio SIM',
  dailyLimit: 100,
  isActive: true,
);

// Increment SMS count
await supabaseService.incrementSmsSentToday(
  userId: currentUser.id,
  simSlot: 0,
);

// Reset at midnight
await supabaseService.resetDailySmsCount(currentUser.id);
```

### Step 9: Implement Configuration Queries

Use the new configuration methods:

```dart
final supabaseService = SupabaseService();

// Get wheel prizes
final prizes = await supabaseService.getActiveWheelPrizes();
final prizeModels = prizes?.map((json) => 
    WheelPrizeModel.fromJson(json)).toList();

// Get FAQs
final faqs = await supabaseService.getFaqs(category: 'mining');
final faqModels = faqs?.map((json) => 
    FaqModel.fromJson(json)).toList();

// Get notifications
final notifications = await supabaseService.getSystemNotifications();
final notifModels = notifications?.map((json) => 
    SystemNotificationModel.fromJson(json)).toList();

// Get support links
final supportLinks = await supabaseService.getSupportLinks();
final model = supportLinks != null 
    ? SupportLinksModel.fromJson(supportLinks) 
    : null;
```

### Step 10: Implement Leaderboard

Use the new leaderboard method:

```dart
final supabaseService = SupabaseService();

// Get top 10 earners
final leaderboard = await supabaseService.getLeaderboard(limit: 10);
final models = leaderboard?.map((json) => 
    LeaderboardModel.fromJson(json)).toList();
```

### Step 11: Implement Referral Tree

Use the new referral methods:

```dart
final supabaseService = SupabaseService();

// Get user's direct referrals
final referrals = await supabaseService.getUserReferrals(
    currentUser.inviteCode);
final models = referrals?.map((json) => 
    InviteTreeModel.fromJson(json)).toList();
```

## Common Migration Issues

### Issue 1: RLS Blocking Queries

**Problem**: Queries fail after enabling RLS
**Solution**: Ensure users are authenticated before querying:

```dart
// Check authentication
final user = supabase.auth.currentUser;
if (user == null) {
  // Redirect to login
  return;
}

// Query will now work with RLS
final data = await supabase.from('users').select();
```

### Issue 2: Trigger Not Updating updated_at

**Problem**: updated_at field not updating automatically
**Solution**: Verify trigger is installed:

```sql
-- Check trigger exists
SELECT * FROM information_schema.triggers 
WHERE trigger_name = 'update_users_updated_at';

-- If not, run the trigger creation SQL from schema_v2.sql
```

### Issue 3: UUID Generation Failing

**Problem**: Cannot insert records with UUID
**Solution**: Verify uuid-ossp extension is enabled:

```sql
-- Check extension
SELECT * FROM pg_extension WHERE extname = 'uuid-ossp';

-- If not present, enable it
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

### Issue 4: Index Not Being Used

**Problem**: Queries are slow despite indexes
**Solution**: Verify indexes exist and are being used:

```sql
-- Check indexes
SELECT * FROM pg_indexes WHERE tablename = 'users';

-- Analyze query plan
EXPLAIN ANALYZE 
SELECT * FROM users WHERE invite_code = 'WM1234';
```

## Testing Your Migration

### 1. Test User Registration
```dart
final error = await supabaseService.registerUser(
  phone: '9999999999',
  password: 'test123',
  parentInviteCode: 'WM0000', // Use valid code
);
assert(error == null);
```

### 2. Test Data Retrieval
```dart
final user = await supabaseService.getCurrentUser();
assert(user != null);
assert(user.totalEarn >= 0);
```

### 3. Test RLS Policies
```dart
// Should only return current user's data
final tasks = await supabaseService.getUserSmsTasks(currentUserId);
for (var task in tasks) {
  assert(task['user_id'] == currentUserId);
}
```

### 4. Test Triggers
```dart
// Update user balance
await supabaseService.updateBalance(userId, 100.0);

// Check updated_at changed
final user = await supabaseService.getCurrentUser(forceRefresh: true);
// user.updatedAt should be recent
```

## Rollback Plan

If you need to rollback:

1. Restore data from backup
2. Drop new tables if needed:
```sql
-- Only if necessary
DROP TABLE IF EXISTS sms_tasks CASCADE;
DROP TABLE IF EXISTS withdrawals CASCADE;
-- etc.
```

3. Remove triggers:
```sql
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
DROP FUNCTION IF EXISTS update_updated_at_column();
```

4. Disable RLS:
```sql
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
-- Repeat for other tables
```

## Performance Monitoring

After migration, monitor these metrics:

1. **Query Performance**
```sql
-- Check slow queries
SELECT query, mean_exec_time, calls
FROM pg_stat_statements
WHERE mean_exec_time > 1000
ORDER BY mean_exec_time DESC;
```

2. **Index Usage**
```sql
-- Check index usage
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;
```

3. **Table Sizes**
```sql
-- Check table sizes
SELECT schemaname, tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

## Getting Help

If you encounter issues:

1. Check `docs/SCHEMA_V2_IMPLEMENTATION.md` for implementation details
2. Review `docs/database_schema.md` for schema reference
3. See `supabase/README.md` for setup instructions
4. Check Supabase logs in dashboard for errors
5. Test SQL queries in Supabase SQL Editor

## Next Steps After Migration

1. Update all screens to use new models and service methods
2. Add loading states for async operations
3. Implement error handling for all database operations
4. Add unit tests for models
5. Add integration tests for service methods
6. Monitor performance and optimize as needed
7. Document any custom changes or extensions

---

**Migration Version**: 2.0  
**Last Updated**: 2026-01-12  
**Compatibility**: Supabase PostgreSQL 12+
