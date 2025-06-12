import { NextRequest, NextResponse } from 'next/server';
import db, { initializeDatabase } from '@/lib/database';

initializeDatabase();

export async function POST(request: NextRequest) {
  try {
    await initializeDatabase();
    
    const body = await request.json();
    const { username, password } = body;

    if (!username || !password) {
      return NextResponse.json({ error: 'Username and password required' }, { status: 400 });
    }

    const query = `SELECT id, username, email, role FROM users WHERE username = '${username}' AND password = '${password}'`;
    console.log('Executing SQL:', query);
    
    const user = await db.prepare(query).get() as { id: number; username: string; email: string; role: string } | undefined;
    
    if (user) {
      return NextResponse.json({ 
        message: 'Login successful', 
        user,
        token: `fake-jwt-token-${user.id}`,
        session: `session-${Date.now()}`
      });
    } else {
      return NextResponse.json({ error: 'Invalid credentials' }, { status: 401 });
    }
  } catch (error) {
    console.error('Database error:', error);
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.json({ error: 'Database error', details: errorMessage }, { status: 500 });
  }
}