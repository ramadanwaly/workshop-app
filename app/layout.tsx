import type { Metadata } from 'next'
import { Cairo } from 'next/font/google'
import './globals.css'

const cairo = Cairo({
  subsets: ['arabic', 'latin'],
  weight: ['400', '600', '700'],
  variable: '--font-cairo',
})

export const metadata: Metadata = {
  title: 'نظام إدارة الورشة | Workshop Management System',
  description: 'نظام متكامل لإدارة التكاليف والمشاريع والخزينة وعمالة الورشة',
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="ar" dir="rtl" className={cairo.variable}>
    <body className="font-sans antialiased bg-background text-ink min-h-screen">
    {children}
    </body>
    </html>
  )
}
