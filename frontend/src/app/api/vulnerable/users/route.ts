import { NextRequest, NextResponse } from 'next/server';
import db, { initializeDatabase } from '@/lib/database';

initializeDatabase();

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const search = searchParams.get('search');
    const id = searchParams.get('id');
    const role = searchParams.get('role');

    if (id) {
      const query = `SELECT * FROM users WHERE id = ${id}`;
      console.log('Executing SQL:', query);
      const user = db.prepare(query).get() as { id: number; username: string; email: string; role: string; created_at: string } | undefined;
      return NextResponse.json(user || { message: 'User not found' });
    }

    if (search) {
      const query = `SELECT * FROM users WHERE username LIKE '%${search}%' OR email LIKE '%${search}%'`;
      console.log('Executing SQL:', query);
      const users = db.prepare(query).all() as { id: number; username: string; email: string; role: string; created_at: string }[];
      return NextResponse.json(users);
    }

    if (role) {
      const query = `SELECT * FROM users WHERE role = '${role}'`;
      console.log('Executing SQL:', query);
      const users = db.prepare(query).all() as { id: number; username: string; email: string; role: string; created_at: string }[];
      return NextResponse.json(users);
    }

    const allUsers = db.prepare('SELECT id, username, email, role, created_at FROM users').all() as { id: number; username: string; email: string; role: string; created_at: string }[];
    return NextResponse.json(allUsers);
  } catch (error) {
    console.error('Database error:', error);
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.json({ error: 'Database error', details: errorMessage }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { username, email, password, role = 'user' } = body;

    const query = `INSERT INTO users (username, email, password, role) VALUES ('${username}', '${email}', '${password}', '${role}')`;
    console.log('Executing SQL:', query);
    
    const result = db.prepare(query).run() as { lastInsertRowid: number; changes: number };
    
    const newUser = db.prepare(`SELECT id, username, email, role, created_at FROM users WHERE id = ${result.lastInsertRowid}`).get() as { id: number; username: string; email: string; role: string; created_at: string };
    
    return NextResponse.json({ message: 'User created successfully', user: newUser }, { status: 201 });
  } catch (error) {
    console.error('Database error:', error);
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.json({ error: 'Database error', details: errorMessage }, { status: 500 });
  }
}