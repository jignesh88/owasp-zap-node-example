import { Injectable, NotFoundException } from '@nestjs/common';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { Product, Review } from './entities/product.entity';

@Injectable()
export class ProductsService {
  private products: Product[] = [
    { id: 1, name: 'Laptop', description: 'High-performance laptop', price: 999.99, category: 'electronics', inStock: true, createdAt: new Date() },
    { id: 2, name: 'Book', description: 'Programming book', price: 29.99, category: 'books', inStock: true, createdAt: new Date() },
    { id: 3, name: 'Headphones', description: 'Wireless headphones', price: 199.99, category: 'electronics', inStock: false, createdAt: new Date() },
  ];

  private reviews: Review[] = [
    { id: 1, productId: 1, rating: 5, comment: 'Great laptop!', author: 'John' },
    { id: 2, productId: 1, rating: 4, comment: 'Good performance', author: 'Jane' },
    { id: 3, productId: 2, rating: 5, comment: 'Very informative', author: 'Bob' },
  ];

  create(createProductDto: CreateProductDto): Product {
    const newProduct: Product = {
      id: this.products.length + 1,
      ...createProductDto,
      createdAt: new Date(),
    };
    this.products.push(newProduct);
    return newProduct;
  }

  findAll(category?: string, minPrice?: number): Product[] {
    let filtered = this.products;
    
    if (category) {
      filtered = filtered.filter(product => product.category === category);
    }
    
    if (minPrice !== undefined) {
      filtered = filtered.filter(product => product.price >= minPrice);
    }
    
    return filtered;
  }

  findOne(id: number): Product {
    const product = this.products.find(product => product.id === id);
    if (!product) {
      throw new NotFoundException(`Product with ID ${id} not found`);
    }
    return product;
  }

  update(id: number, updateProductDto: UpdateProductDto): Product {
    const productIndex = this.products.findIndex(product => product.id === id);
    if (productIndex === -1) {
      throw new NotFoundException(`Product with ID ${id} not found`);
    }
    
    this.products[productIndex] = { ...this.products[productIndex], ...updateProductDto };
    return this.products[productIndex];
  }

  remove(id: number): void {
    const productIndex = this.products.findIndex(product => product.id === id);
    if (productIndex === -1) {
      throw new NotFoundException(`Product with ID ${id} not found`);
    }
    this.products.splice(productIndex, 1);
  }

  getReviews(productId: number): Review[] {
    this.findOne(productId);
    return this.reviews.filter(review => review.productId === productId);
  }
}
