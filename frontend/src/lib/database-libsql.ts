import { createClient } from '@libsql/client';

// LibSQL Database implementation for OWASP ZAP vulnerability testing
// This maintains SQL injection vulnerabilities for security testing

let client: any;
let usingSimpleDb = false;

// Initialize LibSQL client
function initializeLibSQLClient() {
  try {
    // For local development, use a local SQLite file
    // In production, this could connect to Turso or other LibSQL-compatible services
    client = createClient({
      url: process.env.LIBSQL_URL || 'file:local.db',
      authToken: process.env.LIBSQL_AUTH_TOKEN
    });
    console.log('Using LibSQL database');
    return true;
  } catch (error) {
    console.warn('LibSQL failed to initialize:', error);
    return false;
  }
}

// Try to initialize LibSQL, fallback to simple database if needed
if (process.env.USE_SIMPLE_DB === 'true') {
  console.log('Forcing simple database mode via environment variable');
  const simpleDb = require('./database-simple');
  client = simpleDb.default;
  usingSimpleDb = true;
} else {
  if (!initializeLibSQLClient()) {
    // Fallback to simple in-memory database
    console.warn('LibSQL failed to load, using simple fallback database');
    const simpleDb = require('./database-simple');
    client = simpleDb.default;
    usingSimpleDb = true;
  }
}

export async function initializeDatabase() {
  if (usingSimpleDb) {
    console.log('Simple database initialized');
    return;
  }

  try {
    // Create tables if using LibSQL
    await client.execute(`
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        email TEXT NOT NULL,
        password TEXT NOT NULL,
        role TEXT DEFAULT 'user',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await client.execute(`
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        category TEXT,
        stock INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await client.execute(`
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
      )
    `);

    // Check if we need to seed data
    const userCount = await client.execute('SELECT COUNT(*) as count FROM users');
    const count = userCount.rows[0]?.count || 0;

    if (count === 0) {
      // Insert sample data
      await client.execute(`
        INSERT INTO users (username, email, password, role) VALUES 
        ('admin', 'admin@example.com', 'admin123', 'admin'),
        ('john_doe', 'john@example.com', 'password123', 'user'),
        ('jane_smith', 'jane@example.com', 'secret456', 'user'),
        ('bob_wilson', 'bob@example.com', 'qwerty789', 'user')
      `);

      await client.execute(`
        INSERT INTO products (name, description, price, category, stock) VALUES 
        ('Laptop Pro', 'High-performance laptop', 1299.99, 'electronics', 10),
        ('Security Book', 'Web Application Security Guide', 49.99, 'books', 25),
        ('Wireless Mouse', 'Ergonomic wireless mouse', 29.99, 'accessories', 50),
        ('Keyboard', 'Mechanical gaming keyboard', 89.99, 'accessories', 15)
      `);

      console.log('Database seeded with sample data');
    }
  } catch (error) {
    console.error('Database initialization error:', error);
  }
}

// Create a wrapper object that mimics better-sqlite3 API for compatibility
const db = {
  prepare: (query: string) => ({
    get: async () => {
      if (usingSimpleDb) {
        return client.prepare(query).get();
      }
      try {
        const result = await client.execute(query);
        return result.rows[0] || undefined;
      } catch (error) {
        console.error('Database query error:', error);
        throw error;
      }
    },
    all: async () => {
      if (usingSimpleDb) {
        return client.prepare(query).all();
      }
      try {
        const result = await client.execute(query);
        return result.rows || [];
      } catch (error) {
        console.error('Database query error:', error);
        throw error;
      }
    },
    run: async () => {
      if (usingSimpleDb) {
        return client.prepare(query).run();
      }
      try {
        const result = await client.execute(query);
        return {
          lastInsertRowid: result.lastInsertRowid || 0,
          changes: result.rowsAffected || 0
        };
      } catch (error) {
        console.error('Database query error:', error);
        throw error;
      }
    }
  }),
  
  // Direct execute method for LibSQL
  execute: async (query: string) => {
    if (usingSimpleDb) {
      // For simple db, use the executeQuery method
      return client.executeQuery(query);
    }
    return await client.execute(query);
  }
};

export default db;