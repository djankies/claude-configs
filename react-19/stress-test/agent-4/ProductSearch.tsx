import { useState, useTransition, useDeferredValue, useMemo } from 'react';

interface Product {
  id: string;
  name: string;
  category: string;
  price: number;
  description: string;
}

const CATEGORIES = ['Electronics', 'Clothing', 'Books', 'Home', 'Sports', 'Toys'];

function generateMockProducts(count: number): Product[] {
  const products: Product[] = [];
  const productNames = [
    'Laptop', 'Smartphone', 'Headphones', 'T-Shirt', 'Jeans', 'Novel',
    'Cookbook', 'Lamp', 'Sofa', 'Basketball', 'Yoga Mat', 'Action Figure',
    'Monitor', 'Keyboard', 'Mouse', 'Sneakers', 'Jacket', 'Tablet'
  ];

  for (let i = 0; i < count; i++) {
    const category = CATEGORIES[i % CATEGORIES.length];
    const baseName = productNames[i % productNames.length];
    products.push({
      id: `product-${i}`,
      name: `${baseName} ${Math.floor(i / productNames.length) + 1}`,
      category,
      price: Math.floor(Math.random() * 500) + 10,
      description: `High-quality ${baseName.toLowerCase()} for your ${category.toLowerCase()} needs`
    });
  }
  return products;
}

const ALL_PRODUCTS = generateMockProducts(2000);

export default function ProductSearch() {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategories, setSelectedCategories] = useState<Set<string>>(new Set());
  const [isPending, startTransition] = useTransition();

  const deferredSearchQuery = useDeferredValue(searchQuery);
  const deferredCategories = useDeferredValue(selectedCategories);

  const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    startTransition(() => {
      setSearchQuery(value);
    });
  };

  const handleCategoryToggle = (category: string) => {
    startTransition(() => {
      setSelectedCategories(prev => {
        const newSet = new Set(prev);
        if (newSet.has(category)) {
          newSet.delete(category);
        } else {
          newSet.add(category);
        }
        return newSet;
      });
    });
  };

  const filteredProducts = useMemo(() => {
    const query = deferredSearchQuery.toLowerCase();
    const categories = deferredCategories;

    return ALL_PRODUCTS.filter(product => {
      const matchesSearch = query === '' ||
        product.name.toLowerCase().includes(query) ||
        product.description.toLowerCase().includes(query);

      const matchesCategory = categories.size === 0 || categories.has(product.category);

      return matchesSearch && matchesCategory;
    });
  }, [deferredSearchQuery, deferredCategories]);

  return (
    <div className="product-search">
      <header className="search-header">
        <h1>Product Catalog</h1>
        <div className="search-stats">
          {filteredProducts.length} of {ALL_PRODUCTS.length} products
        </div>
      </header>

      <div className="search-controls">
        <div className="search-input-wrapper">
          <input
            type="text"
            value={searchQuery}
            onChange={handleSearchChange}
            placeholder="Search products..."
            className="search-input"
          />
          {isPending && (
            <div className="loading-indicator" aria-label="Filtering...">
              <div className="spinner" />
            </div>
          )}
        </div>

        <div className="category-filters">
          <h3>Categories</h3>
          <div className="checkbox-group">
            {CATEGORIES.map(category => (
              <label key={category} className="checkbox-label">
                <input
                  type="checkbox"
                  checked={selectedCategories.has(category)}
                  onChange={() => handleCategoryToggle(category)}
                />
                <span>{category}</span>
              </label>
            ))}
          </div>
        </div>
      </div>

      <div className={`product-grid ${isPending ? 'filtering' : ''}`}>
        {filteredProducts.map(product => (
          <ProductCard key={product.id} product={product} />
        ))}
        {filteredProducts.length === 0 && (
          <div className="no-results">
            <p>No products found matching your criteria.</p>
            <p>Try adjusting your search or filters.</p>
          </div>
        )}
      </div>
    </div>
  );
}

function ProductCard({ product }: { product: Product }) {
  return (
    <article className="product-card">
      <div className="product-image">
        <div className="image-placeholder">{product.category[0]}</div>
      </div>
      <div className="product-info">
        <h3 className="product-name">{product.name}</h3>
        <p className="product-category">{product.category}</p>
        <p className="product-description">{product.description}</p>
        <div className="product-footer">
          <span className="product-price">${product.price}</span>
          <button className="add-to-cart">Add to Cart</button>
        </div>
      </div>
    </article>
  );
}
