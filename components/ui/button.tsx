import * as React from 'react'

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'default' | 'destructive' | 'outline' | 'secondary' | 'ghost' | 'link'
  size?: 'default' | 'sm' | 'lg' | 'icon'
}

export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className = '', variant = 'default', size = 'default', ...props }, ref) => {
    let classes = 'inline-flex items-center justify-center whitespace-nowrap rounded-md font-bold transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 '
    
    switch (variant) {
      case 'default':
        classes += 'bg-primary text-background hover:bg-primary/90 '
        break
      case 'destructive':
        classes += 'bg-danger text-background hover:bg-danger/90 '
        break
      case 'outline':
        classes += 'border border-input bg-background hover:bg-muted hover:text-ink '
        break
      case 'secondary':
        classes += 'bg-secondary text-background hover:bg-secondary/90 '
        break
      case 'ghost':
        classes += 'hover:bg-muted hover:text-ink '
        break
      case 'link':
        classes += 'text-primary underline-offset-4 hover:underline '
        break
    }
    
    switch (size) {
      case 'default':
        classes += 'h-10 px-4 py-2'
        break
      case 'sm':
        classes += 'h-9 px-3'
        break
      case 'lg':
        classes += 'h-11 px-8'
        break
      case 'icon':
        classes += 'h-10 w-10'
        break
    }
    
    return (
      <button ref={ref} className={classes + ' ' + className} {...props} />
    )
  }
)
Button.displayName = 'Button'
