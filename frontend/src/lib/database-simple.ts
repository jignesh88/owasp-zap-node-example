// Simple in-memory database for Docker environments where better-sqlite3 fails
// This maintains the same vulnerable SQL injection patterns for testing

interface User {
  id: number;
  username: string;
  email: string;
  password: string;
  role: string;
  created_at: string;
}

interface Product {
  id: number;
  name: string;
  description: string;
  price: number;
  category: string;
  stock: number;
  created_at: string;
}

interface Order {
  id: number;
  user_id: number;
  product_id: number;
  quantity: number;
  total_price: number;
  status: string;
  created_at: string;
}

class SimpleDatabase {
  private users: User[] = [];
  private products: Product[] = [];
  private orders: Order[] = [];
  private nextUserId = 1;
  private nextProductId = 1;
  private nextOrderId = 1;

  constructor() {
    this.initializeData();
  }

  private initializeData() {
    // Initialize with sample data
    this.users = [
      { id: 1, username: 'admin', email: 'admin@example.com', password: 'admin123', role: 'admin', created_at: new Date().toISOString() },
      { id: 2, username: 'john_doe', email: 'john@example.com', password: 'password123', role: 'user', created_at: new Date().toISOString() },
      { id: 3, username: 'jane_smith', email: 'jane@example.com', password: 'secret456', role: 'user', created_at: new Date().toISOString() },
      { id: 4, username: 'bob_wilson', email: 'bob@example.com', password: 'qwerty789', role: 'user', created_at: new Date().toISOString() },
    ];

    this.products = [
      { id: 1, name: 'Laptop Pro', description: 'High-performance laptop', price: 1299.99, category: 'electronics', stock: 10, created_at: new Date().toISOString() },
      { id: 2, name: 'Security Book', description: 'Web Application Security Guide', price: 49.99, category: 'books', stock: 25, created_at: new Date().toISOString() },
      { id: 3, name: 'Wireless Mouse', description: 'Ergonomic wireless mouse', price: 29.99, category: 'accessories', stock: 50, created_at: new Date().toISOString() },
      { id: 4, name: 'Keyboard', description: 'Mechanical gaming keyboard', price: 89.99, category: 'accessories', stock: 15, created_at: new Date().toISOString() },
    ];

    this.nextUserId = this.users.length + 1;
    this.nextProductId = this.products.length + 1;
  }

  // Simulate SQL injection vulnerable queries
  executeQuery(query: string): any {
    console.log('Executing vulnerable query:', query);
    
    const lowerQuery = query.toLowerCase().trim();

    // Simulate SELECT queries
    if (lowerQuery.startsWith('select')) {
      if (lowerQuery.includes('from users')) {
        return this.handleUserQuery(query);
      } else if (lowerQuery.includes('from products')) {
        return this.handleProductQuery(query);
      } else if (lowerQuery.includes('from orders')) {
        return this.handleOrderQuery(query);
      }
    }

    // Simulate INSERT queries
    if (lowerQuery.startsWith('insert')) {
      if (lowerQuery.includes('into users')) {
        return this.handleUserInsert(query);
      } else if (lowerQuery.includes('into products')) {
        return this.handleProductInsert(query);
      } else if (lowerQuery.includes('into orders')) {
        return this.handleOrderInsert(query);
      }
    }

    return [];
  }

  private handleUserQuery(query: string): any {
    // Check for SQL injection patterns that would return all users
    if (query.includes("'1'='1") || query.includes("1=1") || query.includes("OR") || query.includes("UNION")) {
      console.log('SQL Injection detected in user query!');
      return this.users; // Return all users to simulate successful injection
    }

    // Try to extract ID from query
    const idMatch = query.match(/id\s*=\s*(\d+)/i);
    if (idMatch) {
      const id = parseInt(idMatch[1]);
      return this.users.find(u => u.id === id);
    }

    // Try to extract search terms
    const searchMatch = query.match(/LIKE\s*'%([^%]+)%'/i);
    if (searchMatch) {
      const searchTerm = searchMatch[1];
      return this.users.filter(u => 
        u.username.includes(searchTerm) || u.email.includes(searchTerm)
      );
    }

    // Try to extract role
    const roleMatch = query.match(/role\s*=\s*'([^']+)'/i);
    if (roleMatch) {
      const role = roleMatch[1];
      return this.users.filter(u => u.role === role);
    }

    return this.users;
  }

  private handleProductQuery(query: string): any {
    if (query.includes("'1'='1") || query.includes("1=1")) {
      return this.products;
    }

    // Handle category filter
    const categoryMatch = query.match(/category\s*=\s*'([^']+)'/i);
    let filtered = this.products;
    
    if (categoryMatch) {
      const category = categoryMatch[1];
      filtered = filtered.filter(p => p.category === category);
    }

    // Handle price filters
    const minPriceMatch = query.match(/price\s*>=\s*(\d+(?:\.\d+)?)/i);
    if (minPriceMatch) {
      const minPrice = parseFloat(minPriceMatch[1]);
      filtered = filtered.filter(p => p.price >= minPrice);
    }

    const maxPriceMatch = query.match(/price\s*<=\s*(\d+(?:\.\d+)?)/i);
    if (maxPriceMatch) {
      const maxPrice = parseFloat(maxPriceMatch[1]);
      filtered = filtered.filter(p => p.price <= maxPrice);
    }

    return filtered;
  }

  private handleOrderQuery(query: string): any {
    // Simulate JOIN with users and products
    return this.orders.map(order => {
      const user = this.users.find(u => u.id === order.user_id);
      const product = this.products.find(p => p.id === order.product_id);
      return {
        ...order,
        username: user?.username || 'unknown',
        product_name: product?.name || 'unknown'
      };
    });
  }

  private handleUserInsert(query: string): any {
    // Extract values from INSERT query
    const valuesMatch = query.match(/VALUES\s*\('([^']+)',\s*'([^']+)',\s*'([^']+)',\s*'([^']+)'\)/i);
    if (valuesMatch) {
      const [, username, email, password, role] = valuesMatch;
      const newUser: User = {
        id: this.nextUserId++,
        username,
        email,
        password,
        role,
        created_at: new Date().toISOString()
      };
      this.users.push(newUser);
      return { lastInsertRowid: newUser.id, changes: 1 };
    }
    return { lastInsertRowid: 0, changes: 0 };
  }

  private handleProductInsert(query: string): any {
    const valuesMatch = query.match(/VALUES\s*\('([^']+)',\s*'([^']+)',\s*([^,]+),\s*'([^']+)',\s*([^)]+)\)/i);
    if (valuesMatch) {
      const [, name, description, priceStr, category, stockStr] = valuesMatch;
      const newProduct: Product = {
        id: this.nextProductId++,
        name,
        description,
        price: parseFloat(priceStr),
        category,
        stock: parseInt(stockStr),
        created_at: new Date().toISOString()
      };
      this.products.push(newProduct);
      return { lastInsertRowid: newProduct.id, changes: 1 };
    }
    return { lastInsertRowid: 0, changes: 0 };
  }

  private handleOrderInsert(query: string): any {
    const valuesMatch = query.match(/VALUES\s*\(([^,]+),\s*([^,]+),\s*([^,]+),\s*([^)]+)\)/i);
    if (valuesMatch) {
      const [, userIdStr, productIdStr, quantityStr, totalPriceStr] = valuesMatch;
      const newOrder: Order = {
        id: this.nextOrderId++,
        user_id: parseInt(userIdStr),
        product_id: parseInt(productIdStr),
        quantity: parseInt(quantityStr),
        total_price: parseFloat(totalPriceStr),
        status: 'pending',
        created_at: new Date().toISOString()
      };
      this.orders.push(newOrder);
      return { lastInsertRowid: newOrder.id, changes: 1 };
    }
    return { lastInsertRowid: 0, changes: 0 };
  }
}

// Create a global instance
const simpleDb = new SimpleDatabase();

// Export functions that match the better-sqlite3 API
export function initializeDatabase() {
  console.log('Using simple in-memory database (fallback mode)');
}

export default {
  prepare: (query: string) => ({
    get: () => simpleDb.executeQuery(query),
    all: () => {
      const result = simpleDb.executeQuery(query);
      return Array.isArray(result) ? result : [result].filter(Boolean);
    },
    run: () => simpleDb.executeQuery(query)
  })
};