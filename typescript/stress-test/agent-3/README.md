# Collection Management System

A comprehensive, type-safe collection management system for handling multiple entity types (Users, Products, Orders) with full CRUD operations, search/filter functionality, and robust error handling.

## Features

- **Type-Safe Generic Collections**: Fully typed generic classes that work with any entity type
- **Complete CRUD Operations**: Create, Read, Update, Delete with validation
- **Advanced Search & Filter**: Powerful filtering with multiple operators (eq, neq, gt, lt, gte, lte, contains, in)
- **Pagination & Sorting**: Built-in pagination and sorting capabilities
- **Specialized Collections**: Entity-specific collections with domain methods
- **Error Handling**: Custom error types for better error management
- **Collection Manager**: Centralized management of multiple collections
- **Data Import/Export**: JSON serialization support

## Architecture

### Core Components

1. **Collection\<T\>** - Generic collection class with CRUD operations
2. **CollectionManager** - Manages multiple collections
3. **UserCollection** - Specialized collection for User entities
4. **ProductCollection** - Specialized collection for Product entities
5. **OrderCollection** - Specialized collection for Order entities

### Entity Types

- **User**: name, email, role (admin/user/guest)
- **Product**: name, description, price, stock, category
- **Order**: userId, productIds[], totalAmount, status, shippingAddress

## Installation

```typescript
import {
  Collection,
  CollectionManager,
  UserCollection,
  ProductCollection,
  OrderCollection,
  User,
  Product,
  Order,
} from './index';
```

## Usage

### Basic CRUD Operations

```typescript
const users = new UserCollection();

const user = users.create({
  name: 'John Doe',
  email: 'john@example.com',
  role: 'user',
});

const foundUser = users.read(user.id);

const updatedUser = users.update(user.id, {
  name: 'John Updated',
});

const deletedUser = users.delete(user.id);
```

### Search and Filter

```typescript
const products = new ProductCollection();

const results = products.search({
  filters: [
    { field: 'category', operator: 'eq', value: 'Electronics' },
    { field: 'price', operator: 'lt', value: 500 },
  ],
  sortBy: 'price',
  sortOrder: 'desc',
  limit: 10,
  offset: 0,
});
```

### User Collection

```typescript
const users = new UserCollection();

const user = users.create({
  name: 'Jane Smith',
  email: 'jane@example.com',
  role: 'user',
});

const admin = users.promoteToAdmin(user.id);

const allAdmins = users.getAdmins();

const userByEmail = users.findByEmail('jane@example.com');
```

### Product Collection

```typescript
const products = new ProductCollection();

const product = products.create({
  name: 'Laptop',
  description: 'High-performance laptop',
  price: 1299.99,
  stock: 50,
  category: 'Electronics',
});

products.decrementStock(product.id, 5);

const inStock = products.findInStock();

const electronics = products.findByCategory('Electronics');

const totalValue = products.getTotalInventoryValue();
```

### Order Collection

```typescript
const orders = new OrderCollection();

const order = orders.create({
  userId: 'user-123',
  productIds: ['product-1', 'product-2'],
  totalAmount: 1329.98,
  status: 'pending',
  shippingAddress: '123 Main St',
});

orders.markAsProcessing(order.id);
orders.markAsShipped(order.id);
orders.markAsDelivered(order.id);

const userOrders = orders.findByUserId('user-123');

const totalRevenue = orders.getTotalRevenue();
```

### Collection Manager

```typescript
const manager = new CollectionManager();

const users = manager.registerCollection<User>('users');
const products = manager.registerCollection<Product>('products');
const orders = manager.registerCollection<Order>('orders');

const stats = manager.getStats();

const exportedData = manager.exportAll();

manager.importAll(exportedData);
```

## Filter Operators

- **eq**: Equal to
- **neq**: Not equal to
- **gt**: Greater than
- **lt**: Less than
- **gte**: Greater than or equal to
- **lte**: Less than or equal to
- **contains**: String contains (case-insensitive) or array includes
- **in**: Value is in array

## Error Types

- **EntityNotFoundError**: Entity with given ID not found
- **ValidationError**: Entity validation failed
- **DuplicateEntityError**: Entity with given ID already exists

## Advanced Features

### Functional Operations

```typescript
const emails = users.map(user => user.email);

const filteredUsers = users.filter(user => user.role === 'admin');

const totalCount = users.reduce((count, user) => count + 1, 0);

const hasAdmin = users.some(user => user.role === 'admin');

const allActive = users.every(user => user.email.includes('@'));
```

### Collection Cloning

```typescript
const clonedCollection = users.clone();
```

### Data Serialization

```typescript
const data = users.toJSON();

users.fromJSON(data);
```

## Type Safety

All operations are fully type-safe with TypeScript:

```typescript
const user: User = users.create({
  name: 'John',
  email: 'john@example.com',
  role: 'user',
});

users.update(user.id, {
  name: 'Jane',
});
```

## Error Handling

```typescript
try {
  const user = users.read('non-existent-id');
} catch (error) {
  if (error instanceof EntityNotFoundError) {
    console.log('User not found');
  }
}

try {
  users.create({
    name: 'Invalid',
    email: 'invalid-email',
    role: 'user',
  });
} catch (error) {
  if (error instanceof ValidationError) {
    console.log('Validation failed:', error.message);
  }
}
```

## Edge Cases Handled

- Missing items return null or throw EntityNotFoundError
- Duplicate IDs throw DuplicateEntityError
- Invalid data throws ValidationError
- Email uniqueness validation
- Stock quantity validation (cannot go negative)
- Order status transition validation
- Price and amount validation (cannot be negative)

## Examples

Run the examples file to see all features in action:

```bash
ts-node examples.ts
```

## API Reference

### Collection\<T\>

- `create(entity, id?)`: Create new entity
- `read(id)`: Read entity by ID (throws if not found)
- `readOrNull(id)`: Read entity by ID (returns null if not found)
- `update(id, updates)`: Update entity
- `delete(id)`: Delete entity
- `deleteAll()`: Delete all entities
- `exists(id)`: Check if entity exists
- `count()`: Get total count
- `findById(id)`: Find by ID (returns null if not found)
- `findByIds(ids[])`: Find multiple by IDs
- `findAll()`: Get all entities
- `search(options)`: Search with filters, sorting, and pagination
- `filter(predicate)`: Filter entities
- `map(mapper)`: Map entities
- `reduce(reducer, initial)`: Reduce entities
- `some(predicate)`: Check if any entity matches
- `every(predicate)`: Check if all entities match
- `toJSON()`: Export to JSON
- `fromJSON(data)`: Import from JSON
- `clone()`: Clone collection

### UserCollection (extends Collection\<User\>)

- `findByEmail(email)`: Find user by email
- `findByRole(role)`: Find users by role
- `findByName(name)`: Search users by name
- `isEmailTaken(email, excludeId?)`: Check email availability
- `getAdmins()`: Get all admin users
- `promoteToAdmin(userId)`: Promote user to admin
- `demoteToUser(userId)`: Demote admin to user

### ProductCollection (extends Collection\<Product\>)

- `findByCategory(category)`: Find products by category
- `findByPriceRange(min, max)`: Find products in price range
- `findInStock()`: Find products in stock
- `findOutOfStock()`: Find out-of-stock products
- `findByName(name)`: Search products by name
- `searchByDescription(query)`: Search by description
- `getAllCategories()`: Get unique categories
- `updateStock(id, quantity)`: Update stock
- `decrementStock(id, quantity)`: Decrease stock
- `incrementStock(id, quantity)`: Increase stock
- `updatePrice(id, price)`: Update price
- `getTotalInventoryValue()`: Calculate total inventory value
- `getTotalStockCount()`: Get total stock count

### OrderCollection (extends Collection\<Order\>)

- `findByUserId(userId)`: Find orders by user
- `findByStatus(status)`: Find orders by status
- `findByProductId(productId)`: Find orders containing product
- `findPending()`: Get pending orders
- `findProcessing()`: Get processing orders
- `findShipped()`: Get shipped orders
- `findDelivered()`: Get delivered orders
- `findCancelled()`: Get cancelled orders
- `findByAmountRange(min, max)`: Find orders by amount
- `updateStatus(id, status)`: Update order status
- `markAsProcessing(id)`: Mark as processing
- `markAsShipped(id)`: Mark as shipped
- `markAsDelivered(id)`: Mark as delivered
- `cancelOrder(id)`: Cancel order
- `getTotalRevenue()`: Calculate total revenue
- `getRevenueByStatus(status)`: Revenue by status
- `getUserOrderCount(userId)`: Count user orders
- `getUserTotalSpent(userId)`: Calculate user total spent
- `getAverageOrderValue()`: Calculate average order value

### CollectionManager

- `registerCollection<T>(name)`: Register new collection
- `getCollection<T>(name)`: Get registered collection
- `hasCollection(name)`: Check if collection exists
- `removeCollection(name)`: Remove collection
- `clearAll()`: Clear all collections
- `getAllCollectionNames()`: Get all collection names
- `getStats()`: Get count statistics
- `exportAll()`: Export all collections
- `importAll(data)`: Import all collections

## Files

- `/Users/daniel/Projects/claude-configs/stress-test/agent-3/types.ts` - Type definitions
- `/Users/daniel/Projects/claude-configs/stress-test/agent-3/Collection.ts` - Generic collection class
- `/Users/daniel/Projects/claude-configs/stress-test/agent-3/CollectionManager.ts` - Collection manager
- `/Users/daniel/Projects/claude-configs/stress-test/agent-3/UserCollection.ts` - User collection
- `/Users/daniel/Projects/claude-configs/stress-test/agent-3/ProductCollection.ts` - Product collection
- `/Users/daniel/Projects/claude-configs/stress-test/agent-3/OrderCollection.ts` - Order collection
- `/Users/daniel/Projects/claude-configs/stress-test/agent-3/index.ts` - Main exports
- `/Users/daniel/Projects/claude-configs/stress-test/agent-3/examples.ts` - Usage examples
