import * as React from 'react'

export type StatusBadgeProps = React.HTMLAttributes<HTMLSpanElement> & {
  label: string
}

export function StatusBadge({ label, className, ...props }: StatusBadgeProps) {
  return (
    <span
      className={`inline-flex items-center shrink-0 whitespace-nowrap rounded-md border px-2 py-0.5 text-[11px] font-bold transition-colors ${className ?? ''}`}
      {...props}
    >
      {label}
    </span>
  )
}