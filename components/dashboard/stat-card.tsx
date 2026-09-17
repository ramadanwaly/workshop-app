interface StatCardProps {
  title: string
  value: string
  subtitle?: string
  accent: 'accent' | 'primary' | 'danger' | 'success' | 'secondary' | 'warning'
}

const accentClasses: Record<
  StatCardProps['accent'],
  { border: string; text: string; bg: string; title: string }
> = {
  accent: { border: 'border-border', text: 'text-ink', bg: 'bg-card', title: 'text-secondary' },
  primary: { border: 'border-border', text: 'text-ink', bg: 'bg-card', title: 'text-secondary' },
  danger: { border: 'border-danger/30', text: 'text-danger', bg: 'bg-danger/5', title: 'text-danger' },
  success: { border: 'border-success/30', text: 'text-success', bg: 'bg-success/5', title: 'text-success' },
  warning: { border: 'border-warning/30', text: 'text-warning-foreground', bg: 'bg-warning/5', title: 'text-warning-foreground' },
  secondary: { border: 'border-border', text: 'text-ink', bg: 'bg-card', title: 'text-secondary' },
}

export default function StatCard({ title, value, subtitle, accent }: StatCardProps) {
  const { border, text, bg, title: titleColor } = accentClasses[accent]

  return (
    <div className={`flex flex-col rounded-md border ${border} ${bg} p-5 sm:p-6`}>
      <h2 className={`text-sm font-bold ${titleColor}`}>{title}</h2>
      <p className={`mt-3 text-2xl font-black tabular-nums tracking-tight ${text} sm:text-3xl`}>{value}</p>
      {subtitle ? <p className="mt-2 text-xs leading-relaxed text-muted-foreground">{subtitle}</p> : null}
    </div>
  )
}