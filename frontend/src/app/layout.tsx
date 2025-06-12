import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'OWASP ZAP Showcase',
  description: 'Demo application for OWASP ZAP security testing',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <nav className="bg-blue-600 text-white p-4">
          <div className="container mx-auto flex justify-between items-center">
            <h1 className="text-xl font-bold">OWASP ZAP Showcase</h1>
            <div className="space-x-4">
              <a href="/" className="hover:underline">Home</a>
              <a href="/users" className="hover:underline">Users</a>
              <a href="/products" className="hover:underline">Products</a>
            </div>
          </div>
        </nav>
        <main className="container mx-auto p-4">
          {children}
        </main>
      </body>
    </html>
  )
}