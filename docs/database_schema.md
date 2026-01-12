# Database Schema and Optimization Guide

## Database Optimization Strategies

### 1. Indexing
- Create indexes on frequently queried columns (user_id, invite_code, etc.)
- Add indexes on foreign keys for better JOIN performance
- Create composite indexes where needed for multi-column queries

### 2. Query Optimization
- Use `.select()` with specific columns instead of selecting all
- Implement pagination for large result sets
- Use `.maybeSingle()` for queries expecting single results
- Add proper error handling for all database operations

### 3. Caching Strategy
- Implemented in-memory caching for user data (5-minute TTL)
- Cache invalidation on data updates
- Force refresh option for critical operations

### 4. Performance Best Practices
- Batch operations where possible
- Use transactions for multiple related operations
- Implement retry logic for failed operations
- Add proper validation before database calls

## Recommended Database Indexes

```sql
-- Users table indexes
CREATE INDEX idx_users_invite_code ON users(invite_code);
CREATE INDEX idx_users_referrer_code ON users(referrer_code);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_created_at ON users(created_at DESC);

-- SMS Tasks table indexes
CREATE INDEX idx_sms_tasks_user_id ON sms_tasks(user_id);
CREATE INDEX idx_sms_tasks_status ON sms_tasks(status);
CREATE INDEX idx_sms_tasks_created_at ON sms_tasks(created_at DESC);

-- Transactions table indexes
CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_type ON transactions(type);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_transactions_created_at ON transactions(created_at DESC);
```
