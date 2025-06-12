'use client'

import { useEffect, useState } from 'react'

interface Product {
  id: number
  name: string
  description: string
  price: number
  category: string
  inStock: boolean
  createdAt: string
}

export default function Products() {
  const [products, setProducts] = useState<Product[]>([])
  const [loading, setLoading] = useState(true)
  const [category, setCategory] = useState('')
  const [minPrice, setMinPrice] = useState('')

  useEffect(() => {
    fetchProducts()
  }, [category, minPrice])

  const fetchProducts = async () => {
    try {
      let url = '/api/products'
      const params = new URLSearchParams()
      if (category) params.append('category', category)
      if (minPrice) params.append('minPrice', minPrice)
      if (params.toString()) url += `?${params.toString()}`
      
      const response = await fetch(url)
      const data = await response.json()
      setProducts(data)
    } catch (error) {
      console.error('Failed to fetch products:', error)
    } finally {
      setLoading(false)
    }
  }

  if (loading) return <div>Loading products...</div>

  return (
    <div className="space-y-6">
      <div className="bg-white rounded-lg shadow-md p-6">
        <h1 className="text-2xl font-bold mb-4">Product Catalog</h1>
        
        <div className="mb-6 flex gap-4">
          <div>
            <label className="block text-sm font-medium mb-1">Category</label>
            <select
              value={category}
              onChange={(e) => setCategory(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-md"
            >
              <option value="">All Categories</option>
              <option value="electronics">Electronics</option>
              <option value="books">Books</option>
              <option value="clothing">Clothing</option>
            </select>
          </div>
          
          <div>
            <label className="block text-sm font-medium mb-1">Min Price</label>
            <input
              type="number"
              placeholder="0"
              value={minPrice}
              onChange={(e) => setMinPrice(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-md"
            />
          </div>
        </div>

        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {products.map((product) => (
            <div key={product.id} className="border border-gray-200 rounded-lg p-4">
              <h3 className="text-lg font-semibold mb-2">{product.name}</h3>
              <p className="text-gray-600 mb-2">{product.description}</p>
              <div className="flex justify-between items-center mb-2">
                <span className="text-xl font-bold text-green-600">
                  ${product.price}
                </span>
                <span className={`px-2 py-1 rounded text-sm ${
                  product.inStock 
                    ? 'bg-green-100 text-green-800' 
                    : 'bg-red-100 text-red-800'
                }`}>
                  {product.inStock ? 'In Stock' : 'Out of Stock'}
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-500 capitalize">
                  {product.category}
                </span>
                <button className="px-3 py-1 bg-blue-600 text-white rounded hover:bg-blue-700">
                  View Details
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}