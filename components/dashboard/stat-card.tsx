interface StatCardProps {
  title: string
  value: string
  subtitle?: string
  accent: 'accent' | 'primary' | 'danger' | 'success' | 'secondary'
}

const accentClasses: Record<
  StatCardProps['accent'],
  { chip: string; border: string; dot: string }
> = {
  accent: { chip: 'bg-accent/10 text-accent', border: 'border-accent/40', dot: 'bg-accent' },
  primary: { chip: 'bg-primary/10 text-primary', border: 'border-primary/40', dot: 'bg-primary' },
  danger: { chip: 'bg-danger/10 text-danger', border: 'border-danger/40', dot: 'bg-danger' },
  success: { chip: 'bg-success/10 text-success', border: 'border-success/40', dot: 'bg-success' },
  secondary: {
    chip: 'bg-secondary/10 text-secondary',
    border: 'border-secondary/40',
    dot: 'bg-secondary',
  },
}

export default function StatCard({ title, value, subtitle, accent }: StatCardProps) {
  const { chip, border, dot } = accentClasses[accent]

  return (
    <div className={`rounded-2xl border ${border} bg-white p-5 shadow-sm sm:p-6`}>
      <div className={`mb-4 flex items-center gap-2 ${chip}`}>
        <span className={`h-2 w-2 rounded-full ${dot}`} />
        <h2 className="text-sm font-semibold">{title}</h2>
      </div>
      <p className="text-2xl font-bold tabular-nums text-ink sm:text-3xl">{value}</p>
      {subtitle ? <p className="mt-2 text-xs text-secondary">{subtitle}</p> : null}
    </div>
  )
}