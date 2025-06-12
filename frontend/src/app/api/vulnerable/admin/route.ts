import { NextRequest, NextResponse } from 'next/server';
import db, { initializeDatabase } from '@/lib/database';

initializeDatabase();

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { query: sqlQuery, action } = body;

    if (action === 'execute') {
      console.log('Executing admin SQL:', sqlQuery);
      
      if (sqlQuery.toLowerCase().includes('select')) {
        const result = db.prepare(sqlQuery).all() as any[];
        return NextResponse.json({ result, message: 'Query executed successfully' });
      } else {
        const result = db.prepare(sqlQuery).run() as { lastInsertRowid?: number; changes: number };
        return NextResponse.json({ result, message: 'Command executed successfully' });
      }
    }

    if (action === 'backup') {
      const tables = ['users', 'products', 'orders'];
      const backup: Record<string, any[]> = {};
      
      for (const table of tables) {
        const query = `SELECT * FROM ${table}`;
        console.log('Executing backup SQL:', query);
        backup[table] = db.prepare(query).all() as any[];
      }
      
      return NextResponse.json({ backup, message: 'Backup completed' });
    }

    return NextResponse.json({ error: 'Invalid action' }, { status: 400 });
  } catch (error) {
    console.error('Database error:', error);
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.json({ error: 'Database error', details: errorMessage }, { status: 500 });
  }
}