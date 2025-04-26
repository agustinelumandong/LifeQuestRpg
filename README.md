# LifeQuestRPG

## Overview

- ??

## Key Features
- ??

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
