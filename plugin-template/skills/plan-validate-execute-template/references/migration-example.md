# Database Migration Example

Complete example of database schema migration with validation gates and rollback capability.

## Scenario: User Address Normalization

**Current State:**
- Users table has address fields (street, city, state, zip)
- No address reuse across users
- No validation on address data

**Desired State:**
- Separate addresses table
- Foreign key relationship
- Address validation and normalization
- Support for multiple addresses per user

## Phase 1: Plan

### Analysis
```sql
SELECT COUNT(*) FROM users WHERE street IS NOT NULL;
-- Result: 1,245 users with addresses

SELECT street, city, COUNT(*)
FROM users
GROUP BY street, city
HAVING COUNT(*) > 1;
-- Result: 23 duplicate addresses (opportunity for deduplication)
```

### Migration Steps
1. Create `addresses` table with validation
2. Insert unique addresses from users table
3. Add `address_id` column to users table
4. Update users with address_id foreign keys
5. Verify all relationships established
6. Drop old address columns from users

### Rollback Plan
```sql
-- Backup current state
CREATE TABLE users_backup AS SELECT * FROM users;

-- Rollback procedure
DROP TABLE IF EXISTS addresses;
ALTER TABLE users DROP COLUMN address_id;
-- Restore from backup if needed
```

## Phase 2: Validate Plan

### Sample Data Test
```javascript
const testUsers = [
  { id: 1, street: '123 Main St', city: 'Boston', state: 'MA', zip: '02101' },
  { id: 2, street: '123 Main St', city: 'Boston', state: 'MA', zip: '02101' }
];

const addresses = deduplicateAddresses(testUsers);
// Expected: 1 unique address
// Result: ✓ Passed
```

### Constraint Testing
```sql
-- Test foreign key constraint
INSERT INTO users (name, address_id) VALUES ('Test', 999);
-- Expected: Foreign key violation
-- Result: ✓ Constraint works
```

## Phase 3: Execute

### Step 1: Create Addresses Table
```sql
CREATE TABLE addresses (
  id SERIAL PRIMARY KEY,
  street VARCHAR(255) NOT NULL,
  city VARCHAR(100) NOT NULL,
  state CHAR(2) NOT NULL,
  zip VARCHAR(10) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(street, city, state, zip)
);
```

### Step 2: Migrate Address Data
```sql
INSERT INTO addresses (street, city, state, zip)
SELECT DISTINCT street, city, state, zip
FROM users
WHERE street IS NOT NULL;
-- Result: 1,222 unique addresses inserted
```

### Step 3: Add Foreign Key
```sql
ALTER TABLE users ADD COLUMN address_id INTEGER REFERENCES addresses(id);

UPDATE users u
SET address_id = a.id
FROM addresses a
WHERE u.street = a.street
  AND u.city = a.city
  AND u.state = a.state
  AND u.zip = a.zip;
-- Result: 1,245 users updated
```

### Step 4: Drop Old Columns
```sql
ALTER TABLE users
  DROP COLUMN street,
  DROP COLUMN city,
  DROP COLUMN state,
  DROP COLUMN zip;
```

## Phase 4: Verify

### Data Integrity Checks
```sql
-- Verify no orphaned users
SELECT COUNT(*) FROM users WHERE address_id IS NULL;
-- Result: 0 (all users have addresses)

-- Verify no orphaned addresses
SELECT COUNT(*) FROM addresses a
WHERE NOT EXISTS (SELECT 1 FROM users WHERE address_id = a.id);
-- Result: 0 (all addresses referenced)

-- Verify deduplication worked
SELECT 1245 - 1222 AS space_saved;
-- Result: 23 duplicate addresses eliminated
```

### Application Tests
```bash
npm test -- users.test.js
# Result: All tests passing ✓
```

## Results

- ✓ Migration completed in 4 minutes 32 seconds
- ✓ All 1,245 records migrated successfully
- ✓ 23 duplicate addresses deduplicated
- ✓ Zero data loss
- ✓ All integrity constraints satisfied
- ✓ Application tests passing
