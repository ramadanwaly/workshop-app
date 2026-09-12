import { redirect } from 'next/navigation'

// الصفحة الرئيسية: تُحوّل فوراً للوحة التحكم.
// الزائر غير المسجل يُعاد توجيهه إلى /login عبر الـ Proxy قبل الوصول لهنا.
export default function HomePage() {
  redirect('/dashboard')
}