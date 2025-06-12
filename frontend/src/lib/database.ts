// Import the LibSQL implementation
import libsqlDb, { initializeDatabase as initLibSQL } from './database-libsql';

const db = libsqlDb;

export async function initializeDatabase() {
  return await initLibSQL();
}

export default db;