import type { Metadata } from 'next'
import { Cairo } from 'next/font/google'
import './globals.css'

const cairo = Cairo({
  subsets: ['arabic', 'latin'],
  weight: ['400', '600', '700'],
  variable: '--font-cairo',
})

import { ThemeProvider } from '@/components/theme-provider'

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
    <html lang="ar" dir="rtl" className={cairo.variable} suppressHydrationWarning>
      <body className="min-h-screen bg-background font-sans text-ink antialiased">
        <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
          {children}
        </ThemeProvider>
      </body>
    </html>
  )
}
