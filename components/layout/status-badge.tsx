type StatusBadgeProps = {
  label: string
  className?: string
}

export function StatusBadge({ label, className }: StatusBadgeProps) {
  return (
    <span
      className={`inline-block shrink-0 whitespace-nowrap rounded-full border px-3 py-1 text-xs font-semibold ${className ?? ''}`}
    >
      {label}
    </span>
  )
}