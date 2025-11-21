import { UserCollection } from './UserCollection';
import { ProductCollection } from './ProductCollection';
import { OrderCollection } from './OrderCollection';
import { CollectionManager } from './CollectionManager';
import { User, Product, Order } from './types';

function basicUsageExample() {
  console.log('=== Basic CRUD Operations ===\n');

  const users = new UserCollection();

  const user1 = users.create({
    name: 'John Doe',
    email: 'john@example.com',
    role: 'user',
  });
  console.log('Created user:', user1);

  const user2 = users.create({
    name: 'Jane Smith',
    email: 'jane@example.com',
    role: 'admin',
  });
  console.log('Created user:', user2);

  const foundUser = users.read(user1.id);
  console.log('Found user by ID:', foundUser);

  const updatedUser = users.update(user1.id, {
    name: 'John Updated',
  });
  console.log('Updated user:', updatedUser);

  console.log('All users:', users.findAll());
  console.log('Total users:', users.count());
}

function productManagementExample() {
  console.log('\n=== Product Management ===\n');

  const products = new ProductCollection();

  products.create({
    name: 'Laptop',
    description: 'High-performance laptop',
    price: 1299.99,
    stock: 50,
    category: 'Electronics',
  });

  products.create({
    name: 'Mouse',
    description: 'Wireless mouse',
    price: 29.99,
    stock: 200,
    category: 'Electronics',
  });

  products.create({
    name: 'Desk Chair',
    description: 'Ergonomic office chair',
    price: 349.99,
    stock: 30,
    category: 'Furniture',
  });

  products.create({
    name: 'Keyboard',
    description: 'Mechanical keyboard',
    price: 89.99,
    stock: 0,
    category: 'Electronics',
  });

  console.log('Electronics:', products.findByCategory('Electronics'));
  console.log('Price range $20-$100:', products.findByPriceRange(20, 100));
  console.log('In stock:', products.findInStock());
  console.log('Out of stock:', products.findOutOfStock());
  console.log('All categories:', products.getAllCategories());
  console.log('Total inventory value:', products.getTotalInventoryValue());
}

function orderProcessingExample() {
  console.log('\n=== Order Processing ===\n');

  const users = new UserCollection();
  const products = new ProductCollection();
  const orders = new OrderCollection();

  const user = users.create({
    name: 'Alice Johnson',
    email: 'alice@example.com',
    role: 'user',
  });

  const product1 = products.create({
    name: 'Smartphone',
    description: 'Latest model',
    price: 799.99,
    stock: 100,
    category: 'Electronics',
  });

  const product2 = products.create({
    name: 'Phone Case',
    description: 'Protective case',
    price: 19.99,
    stock: 500,
    category: 'Accessories',
  });

  const order = orders.create({
    userId: user.id,
    productIds: [product1.id, product2.id],
    totalAmount: 819.98,
    status: 'pending',
    shippingAddress: '123 Main St, City, State 12345',
  });

  console.log('Created order:', order);

  orders.markAsProcessing(order.id);
  console.log('Order marked as processing');

  orders.markAsShipped(order.id);
  console.log('Order marked as shipped');

  orders.markAsDelivered(order.id);
  console.log('Order marked as delivered');

  console.log('User orders:', orders.findByUserId(user.id));
  console.log('User total spent:', orders.getUserTotalSpent(user.id));
  console.log('Total revenue:', orders.getTotalRevenue());
  console.log('Average order value:', orders.getAverageOrderValue());
}

function searchAndFilterExample() {
  console.log('\n=== Search and Filter ===\n');

  const products = new ProductCollection();

  for (let i = 1; i <= 20; i++) {
    products.create({
      name: `Product ${i}`,
      description: `Description for product ${i}`,
      price: Math.random() * 1000,
      stock: Math.floor(Math.random() * 100),
      category: i % 2 === 0 ? 'Electronics' : 'Furniture',
    });
  }

  const searchResults = products.search({
    filters: [
      { field: 'category', operator: 'eq', value: 'Electronics' },
      { field: 'price', operator: 'lt', value: 500 },
    ],
    sortBy: 'price',
    sortOrder: 'desc',
    limit: 5,
    offset: 0,
  });

  console.log('Search results:', searchResults);
  console.log('Total matching items:', searchResults.total);
  console.log('Returned items:', searchResults.data.length);
}

function collectionManagerExample() {
  console.log('\n=== Collection Manager ===\n');

  const manager = new CollectionManager();

  const users = manager.registerCollection<User>('users');
  const products = manager.registerCollection<Product>('products');
  const orders = manager.registerCollection<Order>('orders');

  users.create({
    name: 'Bob Wilson',
    email: 'bob@example.com',
    role: 'user',
  });

  products.create({
    name: 'Tablet',
    description: 'Portable tablet',
    price: 499.99,
    stock: 75,
    category: 'Electronics',
  });

  console.log('Collection stats:', manager.getStats());
  console.log('All collections:', manager.getAllCollectionNames());

  const exportedData = manager.exportAll();
  console.log('Exported data:', exportedData);

  manager.clearAll();
  console.log('After clearing:', manager.getStats());

  manager.importAll(exportedData);
  console.log('After importing:', manager.getStats());
}

function errorHandlingExample() {
  console.log('\n=== Error Handling ===\n');

  const users = new UserCollection();

  try {
    users.read('non-existent-id');
  } catch (error) {
    console.log('Caught error:', error.message);
  }

  try {
    users.create({
      name: 'Invalid User',
      email: 'invalid-email',
      role: 'user',
    });
  } catch (error) {
    console.log('Caught error:', error.message);
  }

  const user = users.create({
    name: 'Valid User',
    email: 'valid@example.com',
    role: 'user',
  });

  try {
    users.create({
      name: 'Another User',
      email: 'valid@example.com',
      role: 'user',
    });
  } catch (error) {
    console.log('Caught error:', error.message);
  }

  try {
    users.update(user.id, { name: '' });
  } catch (error) {
    console.log('Caught error:', error.message);
  }

  const products = new ProductCollection();

  try {
    products.create({
      name: 'Product',
      description: 'Test',
      price: -10,
      stock: 5,
      category: 'Test',
    });
  } catch (error) {
    console.log('Caught error:', error.message);
  }

  const product = products.create({
    name: 'Valid Product',
    description: 'Test',
    price: 100,
    stock: 5,
    category: 'Test',
  });

  try {
    products.decrementStock(product.id, 10);
  } catch (error) {
    console.log('Caught error:', error.message);
  }
}

function advancedQueriesExample() {
  console.log('\n=== Advanced Queries ===\n');

  const users = new UserCollection();

  users.create({ name: 'Admin User', email: 'admin@example.com', role: 'admin' });
  users.create({ name: 'Regular User 1', email: 'user1@example.com', role: 'user' });
  users.create({ name: 'Regular User 2', email: 'user2@example.com', role: 'user' });
  users.create({ name: 'Guest User', email: 'guest@example.com', role: 'guest' });

  console.log('All admins:', users.getAdmins());
  console.log('Users by role (user):', users.findByRole('user'));

  const userEmails = users.map(user => user.email);
  console.log('All user emails:', userEmails);

  const hasAdmin = users.some(user => user.role === 'admin');
  console.log('Has at least one admin:', hasAdmin);

  const allHaveEmails = users.every(user => user.email.includes('@'));
  console.log('All users have valid emails:', allHaveEmails);

  const totalUsers = users.reduce((count, user) => count + 1, 0);
  console.log('Total users (via reduce):', totalUsers);
}

export function runAllExamples() {
  basicUsageExample();
  productManagementExample();
  orderProcessingExample();
  searchAndFilterExample();
  collectionManagerExample();
  errorHandlingExample();
  advancedQueriesExample();
}

if (require.main === module) {
  runAllExamples();
}
