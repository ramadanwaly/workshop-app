import * as React from 'react'

export type LabelProps = React.LabelHTMLAttributes<HTMLLabelElement>

export const Label = React.forwardRef<HTMLLabelElement, LabelProps>(
  ({ className = '', ...props }, ref) => {
    return (
      <label
        ref={ref}
        className={
          'text-sm font-bold leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70 text-ink ' +
          className
        }
        {...props}
      />
    )
  }
)
Label.displayName = 'Label'
