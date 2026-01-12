# WinMate - Gamified SMS Mining Platform

A Flutter-based mobile application that gamifies SMS mining with rewards, referrals, and an engaging user experience.

## Features

- 🎮 **Gamified UI**: Modern, vibrant interface with progress bars, badges, and animations
- 💰 **Mining System**: Dual SIM support for SMS mining with daily limits
- 🎡 **Lucky Wheel**: Spin to win prizes and rewards
- 👥 **Referral System**: Invite friends and earn rewards through multi-level referrals
- 💳 **Wallet**: Manage balance, view transaction history, and withdraw earnings
- 🏆 **Leaderboards**: Compete with other users on weekly rankings
- 📊 **Real-time Stats**: Track SMS sent, earnings, and team performance

## Tech Stack

- **Framework**: Flutter 3.0+
- **Database**: Supabase (PostgreSQL)
- **State Management**: Provider
- **UI/Animations**: Google Fonts, Lottie, Confetti, Fortune Wheel

## Recent Improvements

- ✅ Project structure reorganized following Flutter best practices
- ✅ Database optimizations with caching and retry logic
- ✅ Modern gamified UI with animations and 3D effects
- ✅ Comprehensive theme system
- ✅ Reusable widget components

## Setup

1. Clone the repository
2. Run `flutter pub get`
3. Configure Supabase in `lib/core/constants.dart`
4. Run `flutter run`

## Documentation

- **[Database Schema](docs/database_schema.md)** - Complete database schema with 9 tables, relationships, and optimization strategies
- **[Database Schema Summary](docs/DATABASE_SCHEMA_SUMMARY.md)** - Quick reference guide for developers
- **[Database ERD](docs/DATABASE_ERD.md)** - Visual entity relationship diagrams and data flow
- **[Implementation Guide](docs/implementation_guide.md)** - Developer migration guide
- **[Security Best Practices](docs/security_best_practices.md)** - Security checklist
