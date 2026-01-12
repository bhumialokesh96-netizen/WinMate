-- ============================================
-- WinMate Database Schema v2.0
-- PostgreSQL via Supabase
-- ============================================

-- ============================================
-- 1. Enable UUID Extension
-- ============================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 2. Create Trigger Function for updated_at
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

-- ============================================
-- 3. Create Tables
-- ============================================

-- 3.1 Users Table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone VARCHAR NOT NULL UNIQUE,
    invite_code VARCHAR(6) NOT NULL UNIQUE,
    referrer_code VARCHAR(6),
    device_id VARCHAR,
    balance DECIMAL(10,2) NOT NULL DEFAULT 0.0 CHECK (balance >= 0),
    spins_available INTEGER NOT NULL DEFAULT 1 CHECK (spins_available >= 0),
    total_sms_sent INTEGER NOT NULL DEFAULT 0 CHECK (total_sms_sent >= 0),
    total_invites INTEGER NOT NULL DEFAULT 0 CHECK (total_invites >= 0),
    total_earn DECIMAL(10,2) NOT NULL DEFAULT 0.0 CHECK (total_earn >= 0),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP
);

-- 3.2 SMS Tasks Table
CREATE TABLE IF NOT EXISTS sms_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed')),
    amount DECIMAL(10,2) NOT NULL DEFAULT 2.0,
    sim_slot INTEGER CHECK (sim_slot IN (0, 1)),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMP
);

-- 3.3 Withdrawals Table
CREATE TABLE IF NOT EXISTS withdrawals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    upi_id VARCHAR NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'completed')),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    processed_at TIMESTAMP,
    admin_notes TEXT
);

-- 3.4 SIM Settings Table
CREATE TABLE IF NOT EXISTS sim_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    sim_slot INTEGER NOT NULL CHECK (sim_slot IN (0, 1)),
    sim_name VARCHAR(50) NOT NULL DEFAULT 'SIM 1',
    daily_limit INTEGER NOT NULL DEFAULT 100 CHECK (daily_limit >= 0),
    sent_today INTEGER NOT NULL DEFAULT 0 CHECK (sent_today >= 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, sim_slot)
);

-- 3.5 Invites Table
CREATE TABLE IF NOT EXISTS invites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    invited_email VARCHAR NOT NULL,
    invited_at TIMESTAMP NOT NULL DEFAULT NOW(),
    is_joined BOOLEAN NOT NULL DEFAULT FALSE,
    joined_user_id UUID REFERENCES users(id) ON DELETE SET NULL
);

-- 3.6 Wheel Prizes Table
CREATE TABLE IF NOT EXISTS wheel_prizes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('cash', 'spin', 'bonus')),
    value DECIMAL(10,2) NOT NULL,
    probability DECIMAL(5,2) NOT NULL CHECK (probability >= 0 AND probability <= 100),
    color VARCHAR(7) NOT NULL DEFAULT '#00C853',
    icon VARCHAR(50),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP
);

-- 3.7 FAQs Table
CREATE TABLE IF NOT EXISTS faqs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category VARCHAR(50) NOT NULL,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    priority INTEGER NOT NULL DEFAULT 100,
    is_visible BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP
);

-- 3.8 System Notifications Table
CREATE TABLE IF NOT EXISTS system_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(20) NOT NULL DEFAULT 'info' CHECK (type IN ('info', 'warning', 'urgent', 'promo')),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP
);

-- 3.9 Support Links Table
CREATE TABLE IF NOT EXISTS support_links (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    whatsapp_link VARCHAR(500),
    telegram_link VARCHAR(500),
    email VARCHAR(100),
    phone VARCHAR(20),
    website VARCHAR(500),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ============================================
-- 4. Create Triggers for updated_at
-- ============================================

-- Trigger for users table
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for sim_settings table
DROP TRIGGER IF EXISTS update_sim_settings_updated_at ON sim_settings;
CREATE TRIGGER update_sim_settings_updated_at
    BEFORE UPDATE ON sim_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for wheel_prizes table
DROP TRIGGER IF EXISTS update_wheel_prizes_updated_at ON wheel_prizes;
CREATE TRIGGER update_wheel_prizes_updated_at
    BEFORE UPDATE ON wheel_prizes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for faqs table
DROP TRIGGER IF EXISTS update_faqs_updated_at ON faqs;
CREATE TRIGGER update_faqs_updated_at
    BEFORE UPDATE ON faqs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for support_links table
DROP TRIGGER IF EXISTS update_support_links_updated_at ON support_links;
CREATE TRIGGER update_support_links_updated_at
    BEFORE UPDATE ON support_links
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 5. Create Indexes for Performance
-- ============================================

-- Users Table Indexes
CREATE INDEX IF NOT EXISTS idx_users_invite_code ON users(invite_code);
CREATE INDEX IF NOT EXISTS idx_users_referrer_code ON users(referrer_code);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_users_total_earn ON users(total_earn DESC);

-- SMS Tasks Table Indexes
CREATE INDEX IF NOT EXISTS idx_sms_tasks_user_id ON sms_tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_sms_tasks_status ON sms_tasks(status);
CREATE INDEX IF NOT EXISTS idx_sms_tasks_created_at ON sms_tasks(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sms_tasks_user_status ON sms_tasks(user_id, status);

-- Withdrawals Table Indexes
CREATE INDEX IF NOT EXISTS idx_withdrawals_user_id ON withdrawals(user_id);
CREATE INDEX IF NOT EXISTS idx_withdrawals_status ON withdrawals(status);
CREATE INDEX IF NOT EXISTS idx_withdrawals_created_at ON withdrawals(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_withdrawals_user_status ON withdrawals(user_id, status);

-- SIM Settings Table Indexes
CREATE INDEX IF NOT EXISTS idx_sim_settings_user_id ON sim_settings(user_id);

-- Invites Table Indexes
CREATE INDEX IF NOT EXISTS idx_invites_user_id ON invites(user_id);
CREATE INDEX IF NOT EXISTS idx_invites_email ON invites(invited_email);
CREATE INDEX IF NOT EXISTS idx_invites_joined_user ON invites(joined_user_id);

-- Wheel Prizes Table Indexes
CREATE INDEX IF NOT EXISTS idx_wheel_prizes_active ON wheel_prizes(is_active);
CREATE INDEX IF NOT EXISTS idx_wheel_prizes_probability ON wheel_prizes(probability DESC);

-- FAQs Table Indexes
CREATE INDEX IF NOT EXISTS idx_faqs_category ON faqs(category);
CREATE INDEX IF NOT EXISTS idx_faqs_priority ON faqs(priority ASC);
CREATE INDEX IF NOT EXISTS idx_faqs_visible ON faqs(is_visible);

-- System Notifications Table Indexes
CREATE INDEX IF NOT EXISTS idx_notifications_active ON system_notifications(is_active);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON system_notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_expires ON system_notifications(expires_at);

-- ============================================
-- 6. Row-Level Security (RLS) Policies
-- ============================================

-- Enable RLS on tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE sms_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE withdrawals ENABLE ROW LEVEL SECURITY;
ALTER TABLE sim_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE wheel_prizes ENABLE ROW LEVEL SECURITY;
ALTER TABLE faqs ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_links ENABLE ROW LEVEL SECURITY;

-- Users Table Policies
DROP POLICY IF EXISTS "Users can view own data" ON users;
CREATE POLICY "Users can view own data"
    ON users FOR SELECT
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own data" ON users;
CREATE POLICY "Users can update own data"
    ON users FOR UPDATE
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own data" ON users;
CREATE POLICY "Users can insert own data"
    ON users FOR INSERT
    WITH CHECK (auth.uid() = id);

-- SMS Tasks Table Policies
DROP POLICY IF EXISTS "Users can view own tasks" ON sms_tasks;
CREATE POLICY "Users can view own tasks"
    ON sms_tasks FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own tasks" ON sms_tasks;
CREATE POLICY "Users can insert own tasks"
    ON sms_tasks FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own tasks" ON sms_tasks;
CREATE POLICY "Users can update own tasks"
    ON sms_tasks FOR UPDATE
    USING (auth.uid() = user_id);

-- Withdrawals Table Policies
DROP POLICY IF EXISTS "Users can view own withdrawals" ON withdrawals;
CREATE POLICY "Users can view own withdrawals"
    ON withdrawals FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own withdrawals" ON withdrawals;
CREATE POLICY "Users can insert own withdrawals"
    ON withdrawals FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- SIM Settings Table Policies
DROP POLICY IF EXISTS "Users can view own sim settings" ON sim_settings;
CREATE POLICY "Users can view own sim settings"
    ON sim_settings FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own sim settings" ON sim_settings;
CREATE POLICY "Users can insert own sim settings"
    ON sim_settings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own sim settings" ON sim_settings;
CREATE POLICY "Users can update own sim settings"
    ON sim_settings FOR UPDATE
    USING (auth.uid() = user_id);

-- Invites Table Policies
DROP POLICY IF EXISTS "Users can view own invites" ON invites;
CREATE POLICY "Users can view own invites"
    ON invites FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own invites" ON invites;
CREATE POLICY "Users can insert own invites"
    ON invites FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own invites" ON invites;
CREATE POLICY "Users can update own invites"
    ON invites FOR UPDATE
    USING (auth.uid() = user_id);

-- Public Read Policies for Configuration Tables
DROP POLICY IF EXISTS "Public read wheel_prizes" ON wheel_prizes;
CREATE POLICY "Public read wheel_prizes"
    ON wheel_prizes FOR SELECT
    USING (is_active = true);

DROP POLICY IF EXISTS "Public read FAQs" ON faqs;
CREATE POLICY "Public read FAQs"
    ON faqs FOR SELECT
    USING (is_visible = true);

DROP POLICY IF EXISTS "Public read notifications" ON system_notifications;
CREATE POLICY "Public read notifications"
    ON system_notifications FOR SELECT
    USING (is_active = true);

DROP POLICY IF EXISTS "Public read support links" ON support_links;
CREATE POLICY "Public read support links"
    ON support_links FOR SELECT
    USING (true);

-- ============================================
-- 7. Comments for Documentation
-- ============================================

COMMENT ON TABLE users IS 'Core user accounts with authentication details and statistics';
COMMENT ON TABLE sms_tasks IS 'Tracks individual SMS mining activities and earnings';
COMMENT ON TABLE withdrawals IS 'User withdrawal requests and their processing status';
COMMENT ON TABLE sim_settings IS 'Per-user, per-SIM configuration for mining operations';
COMMENT ON TABLE invites IS 'Email-based invite tracking for bonus spins';
COMMENT ON TABLE wheel_prizes IS 'Admin-configurable prizes for the lucky wheel game';
COMMENT ON TABLE faqs IS 'Frequently asked questions with categorization';
COMMENT ON TABLE system_notifications IS 'Admin-broadcasted system-wide notifications';
COMMENT ON TABLE support_links IS 'Contact and support link configuration (single row)';

-- ============================================
-- Schema v2.0 Complete
-- ============================================
