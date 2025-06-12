import { NextRequest, NextResponse } from 'next/server';
import db, { initializeDatabase } from '@/lib/database';

initializeDatabase();

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const category = searchParams.get('category');
    const minPrice = searchParams.get('minPrice');
    const maxPrice = searchParams.get('maxPrice');
    const search = searchParams.get('search');
    const orderBy = searchParams.get('orderBy');

    let query = 'SELECT * FROM products WHERE 1=1';
    
    if (category) {
      query += ` AND category = '${category}'`;
    }
    
    if (minPrice) {
      query += ` AND price >= ${minPrice}`;
    }
    
    if (maxPrice) {
      query += ` AND price <= ${maxPrice}`;
    }
    
    if (search) {
      query += ` AND (name LIKE '%${search}%' OR description LIKE '%${search}%')`;
    }
    
    if (orderBy) {
      query += ` ORDER BY ${orderBy}`;
    }

    console.log('Executing SQL:', query);
    const products = db.prepare(query).all() as { id: number; name: string; description: string; price: number; category: string; inStock: boolean; created_at: string }[];
    
    return NextResponse.json(products);
  } catch (error) {
    console.error('Database error:', error);
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.json({ error: 'Database error', details: errorMessage }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { name, description, price, category, stock = 0 } = body;

    const query = `INSERT INTO products (name, description, price, category, stock) VALUES ('${name}', '${description}', ${price}, '${category}', ${stock})`;
    console.log('Executing SQL:', query);
    
    const result = db.prepare(query).run() as { lastInsertRowid: number; changes: number };
    
    const newProduct = db.prepare(`SELECT * FROM products WHERE id = ${result.lastInsertRowid}`).get() as { id: number; name: string; description: string; price: number; category: string; stock: number; created_at: string };
    
    return NextResponse.json({ message: 'Product created successfully', product: newProduct }, { status: 201 });
  } catch (error) {
    console.error('Database error:', error);
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.json({ error: 'Database error', details: errorMessage }, { status: 500 });
  }
}