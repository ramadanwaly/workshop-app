type Profile = {
  id: string
  full_name: string
  role: string
  created_at: string
  updated_at?: string
}

type UserListProps = {
  profiles: Profile[]
}

export function UserList({ profiles }: UserListProps) {
  return (
    <div className="space-y-6">
      {/* جدول/قائمة المستخدمين الحاليين */}
      <div className="rounded-md border border-border bg-card p-5 shadow-sm sm:p-6">
        <div className="mb-4">
          <h2 className="text-lg font-bold text-foreground sm:text-xl">المستخدمون الحاليون في النظام</h2>
          <p className="mt-1 text-sm text-muted-foreground">
            قائمة بالمستخدمين المسجلين وأدوارهم وصلاحياتهم.
          </p>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-start text-sm">
            <thead>
              <tr className="border-b border-border text-xs font-semibold text-muted-foreground">
                <th className="pb-3 text-start">الاسم الكامل</th>
                <th className="pb-3 text-start">الدور / الصلاحية</th>
                <th className="pb-3 text-start">معرّف المستخدم (UUID)</th>
                <th className="pb-3 text-start">تاريخ الإضافة</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {profiles.map((p) => {
                const isOwner = p.role === 'owner'
                return (
                  <tr key={p.id} className="transition hover:bg-muted/50">
                    <td className="py-3 font-bold text-foreground">{p.full_name}</td>
                    <td className="py-3">
                      <span
                        className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-bold ${
                          isOwner
                            ? 'bg-accent/20 text-accent border border-accent/40'
                            : 'bg-primary/10 text-primary border border-primary/20'
                        }`}
                      >
                        {isOwner ? 'المالك (Owner)' : 'مدير (Manager)'}
                      </span>
                    </td>
                    <td className="py-3 font-mono text-xs text-muted-foreground truncate max-w-[140px] sm:max-w-none">
                      {p.id}
                    </td>
                    <td className="py-3 text-muted-foreground text-xs">
                      {new Date(p.created_at).toLocaleDateString('ar-EG', {
                        year: 'numeric',
                        month: 'short',
                        day: 'numeric',
                      })}
                    </td>
                  </tr>
                )
              })}
              {profiles.length === 0 && (
                <tr>
                  <td colSpan={4} className="py-6 text-center text-muted-foreground">
                    لا يوجد مستخدمون حالياً
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* بطاقة تعليمات إضافة مستخدم جديد */}
      <div className="rounded-md border border-border bg-card p-5 shadow-sm sm:p-6">
        <div className="flex items-start gap-3">
          <div className="rounded-md bg-accent/20 p-2 text-accent">
            <svg
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
              className="h-6 w-6"
              aria-hidden="true"
            >
              <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
              <circle cx="9" cy="7" r="4" />
              <line x1="19" y1="8" x2="19" y2="14" />
              <line x1="16" y1="11" x2="22" y2="11" />
            </svg>
          </div>
          <div>
            <h3 className="text-base font-bold text-foreground sm:text-lg">
              تعليمات إضافة مستخدم جديد
            </h3>
            <p className="mt-1 text-sm font-semibold text-primary">
              أضف المستخدم عبر Supabase Dashboard ثم أضف ملفه بـ SQL
            </p>
          </div>
        </div>

        <div className="mt-4 space-y-3 text-xs sm:text-sm text-foreground/80 leading-relaxed">
          <ol className="list-decimal list-inside space-y-2 font-medium">
            <li>
              افتح لوحة تحكم Supabase (Dashboard) وانتقل إلى قسم <strong className="text-foreground">Authentication &gt; Users</strong> ثم انقر على <strong className="text-foreground">Add user</strong> لإثبات بريده وكلمة مروره.
            </li>
            <li>
              انسخ معرّف المستخدم الجديد (<code className="rounded bg-muted px-1.5 py-0.5 font-mono text-xs text-primary">User ID / UUID</code>).
            </li>
            <li>
              افتح محرر SQL (<strong className="text-foreground">SQL Editor</strong>) ونفّذ الاستعلام التالي لإضافة ملفه الشخصي ودوره:
            </li>
          </ol>

          <div className="overflow-x-auto rounded-md border border-border bg-muted p-4 text-foreground dir-ltr text-start font-mono text-xs">
            <pre>{`INSERT INTO public.profiles (id, full_name, role)
VALUES (
    '<USER_ID_HERE>',
    'اسم المدير الجديد',
    'manager'
)
ON CONFLICT (id) DO UPDATE SET role = EXCLUDED.role;`}</pre>
          </div>

          <p className="text-xs text-muted-foreground italic">
            ملاحظة أمان: تم إغلاق التسجيل الذاتي المفتوح لمنع أي زائر من الحصول على صلاحيات الإدارة تلقائياً. منح الصلاحيات يتم حكراً بواسطة مالك الورشة.
          </p>
        </div>
      </div>
    </div>
  )
}
