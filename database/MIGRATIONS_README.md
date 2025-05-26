# LifeQuestRPG Migration System

This migration system allows you to manage your database schema changes in a organized and version-controlled way.

## Setup

1. **Database Configuration**: Your database credentials are read from your existing configuration file:
   ```
   config/database.php
   ```

2. **Create the database**: Run the database creation script first:
   ```bash
   php create_database.php
   ```

3. **Run migrations**: Apply all pending migrations:
   ```bash
   php migrate.php run
   ```

4. **For complex migrations**: If you encounter issues with triggers or stored procedures, use:
   ```bash
   php run_complex_migrations.php
   ```

## Usage

### Windows (Command Prompt/PowerShell)
```bash
# Run all pending migrations
php migrate.php run

# Check migration status
php migrate.php status

# Show help
php migrate.php help

# For complex migrations with DELIMITER directives
php run_complex_migrations.php
```

### Using the batch file (Windows)
```bash
# Run all pending migrations
migrate.bat run

# Check migration status
migrate.bat status

# Show help
migrate.bat help
```

## Migration Files

Migration files are located in `database/migrations/` and follow this naming convention:
- `001_create_users_table.sql`
- `002_create_avatars_table.sql`
- `003_create_userstats_table.sql`
- etc.

## Creating New Migrations

1. Use the migration creator script:
   ```bash
   php create_migration.php "your_migration_description"
   ```

   Example:
   ```bash
   php create_migration.php "add_settings_table"
   ```

   This will create a new migration file with proper sequential numbering:
   ```
   027_add_settings_table.sql
   ```

2. Edit the newly created migration file with your SQL code
3. Run `php migrate.php run` to execute

### Example Migration File
```sql
-- 027_add_new_feature.sql
ALTER TABLE users ADD COLUMN last_login TIMESTAMP NULL;

CREATE INDEX idx_users_last_login ON users(last_login);
```

## Migration Features

- ✅ **Automatic tracking**: Migrations are tracked to prevent re-execution
- ✅ **Transaction safety**: Each migration runs in a transaction
- ✅ **Error handling**: Detailed error messages if migrations fail
- ✅ **Status checking**: See which migrations have been executed
- ✅ **Multi-statement support**: Handle complex SQL with procedures, triggers, etc.

## Current Migration List

1. **001_create_users_table.sql** - Core users table
2. **002_create_avatars_table.sql** - Avatar system
3. **003_create_userstats_table.sql** - User statistics and levels
4. **004_create_activity_log_table.sql** - Activity logging
5. **005_create_tasks_table.sql** - Task management
6. **006_create_dailytasks_table.sql** - Daily tasks
7. **007_create_goodhabits_table.sql** - Good habits tracking
8. **008_create_badhabits_table.sql** - Bad habits tracking
9. **009_create_streaks_table.sql** - Streak tracking
10. **010_create_journals_table.sql** - Journal entries
11. **011_create_item_categories_table.sql** - Item categorization
12. **012_create_marketplace_items_table.sql** - Marketplace items
13. **013_create_user_inventory_table.sql** - User inventory
14. **014_create_item_usage_history_table.sql** - Item usage tracking
15. **015_create_user_active_boosts_table.sql** - Active boosts
16. **016_create_user_event_table.sql** - User events
17. **017_create_user_event_completions_table.sql** - Event completions
18. **018_create_test_data_table.sql** - Test data table
19. **019_insert_default_avatars.sql** - Default avatar data
20. **020_insert_default_item_categories.sql** - Default categories
21. **021_insert_default_marketplace_items.sql** - Default marketplace items
22. **022_create_triggers.sql** - Database triggers for activity logging
23. **023_create_inventory_triggers.sql** - Inventory-related triggers
24. **024_create_procedures_part1.sql** - Stored procedures (part 1)
25. **025_create_use_inventory_procedure.sql** - UseInventoryItem procedure
26. **026_add_userstats_unique_constraint.sql** - Add unique constraints

## Troubleshooting

### Common Issues

1. **Database connection failed**: Check your database credentials and ensure MySQL is running
2. **Migration failed**: Check the error message and fix the SQL syntax
3. **Table already exists**: The migration may have been partially executed. Check the database state

### Manual Fix
If you need to manually mark a migration as executed:
```sql
INSERT INTO migrations (migration) VALUES ('001_create_users_table');
```

### Reset All Migrations (⚠️ DANGEROUS)
```sql
DROP TABLE migrations;
-- This will cause all migrations to run again
```

## Best Practices

1. **Always backup** your database before running migrations
2. **Test migrations** on a development database first
3. **Keep migrations atomic** - one logical change per file
4. **Use descriptive names** for migration files
5. **Don't modify existing migrations** that have been executed in production

## Integration with Your Application

The migration system is separate from your main application, but you can integrate it by:

1. Adding migration commands to your deployment process
2. Running migrations as part of your CI/CD pipeline
3. Creating a web interface for migrations (advanced)

Happy migrating! 🚀
