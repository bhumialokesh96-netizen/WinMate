# Supabase Database Schema

This directory contains the database schema files for the WinMate application.

## Files

- **schema_v2.sql**: Complete database schema v2.0 with all tables, triggers, indexes, and RLS policies

## Setup Instructions

1. Open your Supabase project dashboard
2. Navigate to the SQL Editor
3. Copy and paste the contents of `schema_v2.sql`
4. Execute the SQL to create all tables and configurations

## Schema v2.0 Features

### 1. UUID Support
- Enables `uuid-ossp` extension for UUID generation
- All primary keys use UUID type with auto-generation

### 2. Automatic Timestamps
- Trigger function `update_updated_at_column()` auto-updates `updated_at` fields
- Applied to: users, sim_settings, wheel_prizes, faqs, support_links

### 3. Tables (9 total)
- **users**: Core user accounts with authentication and statistics
- **sms_tasks**: SMS mining activities and earnings tracking
- **withdrawals**: User withdrawal requests and processing
- **sim_settings**: Dual SIM configuration for mining
- **invites**: Email-based referral tracking
- **wheel_prizes**: Lucky wheel prize configuration
- **faqs**: Frequently asked questions with categories
- **system_notifications**: Admin broadcast messages
- **support_links**: Contact and support information

### 4. Row-Level Security (RLS)
- All tables have RLS enabled
- Users can only access their own data
- Public read access for configuration tables (wheel_prizes, faqs, etc.)

### 5. Performance Indexes
- Optimized indexes on frequently queried columns
- Composite indexes for multi-column queries
- Total: 30+ indexes for optimal performance

### 6. Data Integrity
- Foreign key constraints with CASCADE/SET NULL options
- Check constraints for data validation
- Unique constraints for business logic

## Notes

- The schema uses `IF NOT EXISTS` clauses, making it safe to run multiple times
- All timestamps default to `NOW()` automatically
- RLS policies align with Supabase Auth for secure data access
- The schema is designed for PostgreSQL 12+

## Related Documentation

- Full schema documentation: `/docs/database_schema.md`
- Schema summary: `/docs/DATABASE_SCHEMA_SUMMARY.md`
- ERD diagrams: `/docs/DATABASE_ERD.md`
- Implementation guide: `/docs/implementation_guide.md`
