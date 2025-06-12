import { NextRequest, NextResponse } from 'next/server';
import db, { initializeDatabase } from '@/lib/database';

initializeDatabase();

export async function GET(request: NextRequest) {
  try {
    await initializeDatabase();
    
    const { searchParams } = new URL(request.url);
    const userId = searchParams.get('userId');
    const status = searchParams.get('status');
    const dateFrom = searchParams.get('dateFrom');

    let query = `
      SELECT o.*, u.username, p.name as product_name 
      FROM orders o 
      JOIN users u ON o.user_id = u.id 
      JOIN products p ON o.product_id = p.id 
      WHERE 1=1
    `;
    
    if (userId) {
      query += ` AND o.user_id = ${userId}`;
    }
    
    if (status) {
      query += ` AND o.status = '${status}'`;
    }
    
    if (dateFrom) {
      query += ` AND o.created_at >= '${dateFrom}'`;
    }

    console.log('Executing SQL:', query);
    const orders = await db.prepare(query).all() as { id: number; user_id: number; product_id: number; quantity: number; total_price: number; status: string; created_at: string; username: string; product_name: string }[];
    
    return NextResponse.json(orders);
  } catch (error) {
    console.error('Database error:', error);
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.json({ error: 'Database error', details: errorMessage }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    await initializeDatabase();
    
    const body = await request.json();
    const { userId, productId, quantity, totalPrice } = body;

    const query = `INSERT INTO orders (user_id, product_id, quantity, total_price) VALUES (${userId}, ${productId}, ${quantity}, ${totalPrice})`;
    console.log('Executing SQL:', query);
    
    const result = await db.prepare(query).run() as { lastInsertRowid: number; changes: number };
    
    const newOrder = await db.prepare(`
      SELECT o.*, u.username, p.name as product_name 
      FROM orders o 
      JOIN users u ON o.user_id = u.id 
      JOIN products p ON o.product_id = p.id 
      WHERE o.id = ${result.lastInsertRowid}
    `).get() as { id: number; user_id: number; product_id: number; quantity: number; total_price: number; status: string; created_at: string; username: string; product_name: string };
    
    return NextResponse.json({ message: 'Order created successfully', order: newOrder }, { status: 201 });
  } catch (error) {
    console.error('Database error:', error);
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.json({ error: 'Database error', details: errorMessage }, { status: 500 });
  }
}