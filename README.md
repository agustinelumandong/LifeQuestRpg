# LifeQuestRPG

## Overview

LifeQuestRPG is a gamified task management system that helps users build productive habits through RPG mechanics.

## Key Features
- Task Management with RPG elements
- Habit tracking with streaks
- XP and level progression
- Virtual marketplace with items and rewards
- Database migration system

## Database Migration System

This project includes a database migration system that allows you to set up the database in a structured, version-controlled manner. Key features:

- Split migrations by functionality (tables, data, triggers, etc.)
- Track executed migrations in a dedicated table
- Support for complex SQL (triggers, stored procedures)
- Command-line tools for easy execution

### Usage

```bash
# Create the database
php create_database.php

# Run all migrations
php migrate.php run

# Check migration status
php migrate.php status

# For complex migrations (triggers, procedures)
php run_complex_migrations.php
```

See `database/MIGRATIONS_README.md` for more details.

## Installation

### Prerequisites
- PHP 8.1 or higher
- Composer
- MySQL/MariaDB (or your preferred database)
- npm

### Step 1: Clone the Repository
```bash
- ?

cd my-project
```

### Step 2: Install Dependencies
```bash
composer install
```

### Step 3: Configure Environment
Copy the example environment file and adjust settings for your environment:
```bash
cp .env.example .env
```

Edit the `.env` file with your database credentials and application settings:

```env
APP_NAME=LifeQuestRPG
APP_ENV=development
APP_DEBUG=true
APP_URL=http://localhost:8000
APP_TIMEZONE=UTC

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=your_database
DB_USERNAME=your_username
DB_PASSWORD=your_password
DB_CHARSET=utf8mb4
```

### Step 4: Set Permissions (OPTIONAL)
Ensure storage directories are writable:
```bash
chmod -R 775 storage/
```

### Step 5: Create Database
Create your database and import schema:
```bash
mysql -u username -p database_name < database/schema.sql
```

### Step 6: Run Development Server
```bash
php -S localhost:8000 -t public/
```

Visit `http://localhost:8000` in your browser to see the application running.

## License

This App is open-sourced software licensed under the MIT license.

## Author

Sean Agustine L. Esparagoza  
Github: [agustinelumandong](https://github.com/agustinelumandong)
