'use client'

import { useEffect, useRef } from 'react'
import type { ReactNode } from 'react'

type DialogShellProps = {
  title: string
  onClose: () => void
  children: ReactNode
}

export function DialogShell({ title, onClose, children }: DialogShellProps) {
  const dialogRef = useRef<HTMLDivElement>(null)
  const returnFocusRef = useRef<HTMLElement | null>(null)

  useEffect(() => {
    returnFocusRef.current = document.activeElement instanceof HTMLElement ? document.activeElement : null
    dialogRef.current?.focus()

    function onKeyDown(event: KeyboardEvent) {
      if (event.key === 'Escape') {
        onClose()
        return
      }

      if (event.key !== 'Tab' || !dialogRef.current) return

      const focusable = Array.from(
        dialogRef.current.querySelectorAll<HTMLElement>(
          'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'
        )
      )

      if (focusable.length === 0) {
        event.preventDefault()
        dialogRef.current.focus()
        return
      }

      const first = focusable[0]
      const last = focusable[focusable.length - 1]
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault()
        last.focus()
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault()
        first.focus()
      }
    }

    document.addEventListener('keydown', onKeyDown)
    return () => {
      document.removeEventListener('keydown', onKeyDown)
      returnFocusRef.current?.focus()
    }
  }, [onClose])

  return (
    <div
      className="fixed inset-0 z-50 flex items-end justify-center bg-black/60 sm:items-center"
      role="dialog"
      aria-modal="true"
      aria-labelledby="dialog-shell-title"
      onClick={onClose}
    >
      <div
        ref={dialogRef}
        tabIndex={-1}
        className="max-h-[92dvh] w-full max-w-md overflow-y-auto rounded-t-2xl border border-secondary/40 bg-card p-5 shadow-xl shadow-primary/10 sm:rounded-2xl"
        onClick={(event) => event.stopPropagation()}
      >
        <div className="mb-4 flex items-center justify-between">
          <h2 id="dialog-shell-title" className="text-lg font-bold text-primary">{title}</h2>
          <button
            type="button"
            onClick={onClose}
            aria-label="إغلاق"
            className="flex h-10 w-10 items-center justify-center rounded-full text-secondary transition hover:bg-secondary/10 hover:text-primary"
          >
            ✕
          </button>
        </div>
        {children}
      </div>
    </div>
  )
}
