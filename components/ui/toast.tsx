'use client'

import { createContext, useContext, useState, useCallback, ReactNode } from 'react'

export type ToastType = 'success' | 'error' | 'info'

export interface ToastMessage {
  id: string
  message: string
  type: ToastType
  isExiting?: boolean
}

interface ToastContextType {
  showToast: (message: string, type?: ToastType) => void
  removeToast: (id: string) => void
  toasts: ToastMessage[]
}

const ToastContext = createContext<ToastContextType | undefined>(undefined)

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<ToastMessage[]>([])

  const removeToast = useCallback((id: string) => {
    setToasts((prev) =>
      prev.map((toast) => (toast.id === id ? { ...toast, isExiting: true } : toast))
    )
    setTimeout(() => {
      setToasts((prev) => prev.filter((toast) => toast.id !== id))
    }, 300)
  }, [])

  const showToast = useCallback(
    (message: string, type: ToastType = 'info') => {
      const id = Math.random().toString(36).substring(2, 9)
      setToasts((prev) => [...prev, { id, message, type }])

      setTimeout(() => {
        removeToast(id)
      }, 4000)
    },
    [removeToast]
  )

  return (
    <ToastContext.Provider value={{ showToast, removeToast, toasts }}>
      {children}
      <ToastContainerInternal toasts={toasts} removeToast={removeToast} />
    </ToastContext.Provider>
  )
}

function ToastItemCard({
  toast,
  onClose,
}: {
  toast: ToastMessage
  onClose: () => void
}) {
  const typeStyles: Record<ToastType, string> = {
    success: 'bg-success text-white border border-[#4a6431]',
    error: 'bg-danger text-white border border-[#933420]',
    info: 'bg-accent text-white border border-[#966c2d]',
  }

  const icons: Record<ToastType, React.ReactNode> = {
    success: (
      <svg className="w-5 h-5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
      </svg>
    ),
    error: (
      <svg className="w-5 h-5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
      </svg>
    ),
    info: (
      <svg className="w-5 h-5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
    ),
  }

  return (
    <div
      className={`flex items-center gap-3 px-4 py-3 rounded-xl shadow-lg transition-all duration-300 transform ${
        toast.isExiting
          ? 'opacity-0 translate-x-8 scale-95'
          : 'opacity-100 translate-x-0 scale-100'
      } ${typeStyles[toast.type]}`}
      role="alert"
    >
      {icons[toast.type]}
      <span className="text-sm font-medium leading-snug flex-1">{toast.message}</span>
      <button
        onClick={onClose}
        className="p-1 rounded-lg hover:bg-card/20 transition-colors shrink-0 text-white/80 hover:text-white"
        aria-label="إغلاق"
      >
        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    </div>
  )
}

function ToastContainerInternal({
  toasts,
  removeToast,
}: {
  toasts: ToastMessage[]
  removeToast: (id: string) => void
}) {
  if (toasts.length === 0) return null

  return (
    <div className="fixed top-4 end-4 z-50 flex flex-col gap-2 max-w-sm w-full pointer-events-none px-4 sm:px-0 dir-rtl">
      {toasts.map((toast) => (
        <div key={toast.id} className="pointer-events-auto">
          <ToastItemCard toast={toast} onClose={() => removeToast(toast.id)} />
        </div>
      ))}
    </div>
  )
}

export function ToastContainer() {
  const context = useContext(ToastContext)
  if (!context) return null
  return <ToastContainerInternal toasts={context.toasts} removeToast={context.removeToast} />
}

export function useToast() {
  const context = useContext(ToastContext)
  if (!context) {
    throw new Error('useToast must be used within a ToastProvider')
  }
  return {
    showToast: context.showToast,
    ToastContainer,
  }
}
