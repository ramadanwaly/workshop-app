'use client'

import { useEffect } from 'react'
import type { ReactNode } from 'react'

type DialogShellProps = {
  title: string
  onClose: () => void
  children: ReactNode
}

export function DialogShell({ title, onClose, children }: DialogShellProps) {
  useEffect(() => {
    function onKeyDown(event: KeyboardEvent) {
      if (event.key === 'Escape') onClose()
    }
    document.addEventListener('keydown', onKeyDown)
    return () => document.removeEventListener('keydown', onKeyDown)
  }, [onClose])

  return (
    <div
      className="fixed inset-0 z-50 flex items-end justify-center bg-black/60 sm:items-center"
      role="dialog"
      aria-modal="true"
      aria-label={title}
      onClick={onClose}
    >
      <div
        className="max-h-[92dvh] w-full max-w-md overflow-y-auto rounded-t-2xl border border-secondary/40 bg-white p-5 shadow-xl shadow-primary/10 sm:rounded-2xl"
        onClick={(event) => event.stopPropagation()}
      >
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-lg font-bold text-primary">{title}</h2>
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