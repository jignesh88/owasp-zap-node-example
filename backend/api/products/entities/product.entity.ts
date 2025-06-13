export interface Product {
  id: number;
  name: string;
  description: string;
  price: number;
  category: string;
  inStock: boolean;
  createdAt: Date;
}

export interface Review {
  id: number;
  productId: number;
  rating: number;
  comment: string;
  author: string;
}
