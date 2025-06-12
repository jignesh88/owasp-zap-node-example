let db: any;
let usingSimpleDb = false;

// Check if we should force simple database
if (process.env.USE_SIMPLE_DB === 'true') {
  console.log('Forcing simple database mode via environment variable');
  const simpleDb = require('./database-simple');
  db = simpleDb.default;
  usingSimpleDb = true;
} else {
  try {
    // Try to use better-sqlite3 first
    const Database = require('better-sqlite3');
    const { join } = require('path');
    const dbPath = join(process.cwd(), 'database.sqlite');
    db = new Database(dbPath);
    console.log('Using better-sqlite3 database');
  } catch (error: any) {
    // Fallback to simple in-memory database
    console.warn('better-sqlite3 failed to load, using simple fallback database:', error.message);
    const simpleDb = require('./database-simple');
    db = simpleDb.default;
    usingSimpleDb = true;
  }
}

export function initializeDatabase() {
  if (usingSimpleDb) {
    // Simple database is already initialized
    console.log('Simple database initialized');
    return;
  }

  // Only run SQL DDL if using real SQLite
  db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE NOT NULL,
      email TEXT NOT NULL,
      password TEXT NOT NULL,
      role TEXT DEFAULT 'user',
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      description TEXT,
      price REAL NOT NULL,
      category TEXT,
      stock INTEGER DEFAULT 0,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS orders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      product_id INTEGER,
      quantity INTEGER,
      total_price REAL,
      status TEXT DEFAULT 'pending',
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id),
      FOREIGN KEY (product_id) REFERENCES products(id)
    );
  `);

  const userCount = db.prepare('SELECT COUNT(*) as count FROM users').get() as { count: number };
  
  if (userCount.count === 0) {
    const insertUser = db.prepare(`
      INSERT INTO users (username, email, password, role) VALUES (?, ?, ?, ?)
    `);
    
    insertUser.run('admin', 'admin@example.com', 'admin123', 'admin');
    insertUser.run('john_doe', 'john@example.com', 'password123', 'user');
    insertUser.run('jane_smith', 'jane@example.com', 'secret456', 'user');
    insertUser.run('bob_wilson', 'bob@example.com', 'qwerty789', 'user');

    const insertProduct = db.prepare(`
      INSERT INTO products (name, description, price, category, stock) VALUES (?, ?, ?, ?, ?)
    `);
    
    insertProduct.run('Laptop Pro', 'High-performance laptop', 1299.99, 'electronics', 10);
    insertProduct.run('Security Book', 'Web Application Security Guide', 49.99, 'books', 25);
    insertProduct.run('Wireless Mouse', 'Ergonomic wireless mouse', 29.99, 'accessories', 50);
    insertProduct.run('Keyboard', 'Mechanical gaming keyboard', 89.99, 'accessories', 15);
  }
}

export default db;