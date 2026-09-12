'use client'

export interface ConfirmDialogProps {
  isOpen?: boolean
  title: string
  message: string
  confirmLabel?: string
  cancelLabel?: string
  onConfirm: () => void | Promise<void>
  onCancel: () => void
  isDestructive?: boolean
  isLoading?: boolean
}

export function ConfirmDialog({
  isOpen = true,
  title,
  message,
  confirmLabel = 'تأكيد',
  cancelLabel = 'إلغاء',
  onConfirm,
  onCancel,
  isDestructive = false,
  isLoading = false,
}: ConfirmDialogProps) {
  if (!isOpen) return null

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-xs p-4 transition-opacity"
      onClick={onCancel}
    >
      <div
        className="w-full max-w-md rounded-2xl bg-background p-6 shadow-2xl border border-secondary/20 space-y-4 text-ink dir-rtl transition-all transform scale-100"
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
        aria-labelledby="confirm-dialog-title"
        aria-describedby="confirm-dialog-message"
      >
        <h3 id="confirm-dialog-title" className="text-xl font-bold text-primary">
          {title}
        </h3>
        <p id="confirm-dialog-message" className="text-sm text-secondary/90 leading-relaxed">
          {message}
        </p>

        <div className="flex items-center justify-end gap-3 pt-4 border-t border-secondary/10">
          <button
            type="button"
            onClick={onCancel}
            disabled={isLoading}
            className="px-4 py-2.5 rounded-xl text-sm font-medium text-secondary hover:text-ink hover:bg-secondary/10 transition-colors disabled:opacity-50 cursor-pointer"
          >
            {cancelLabel}
          </button>
          <button
            type="button"
            onClick={onConfirm}
            disabled={isLoading}
            className={`px-5 py-2.5 rounded-xl text-sm font-bold text-white shadow-sm transition-all disabled:opacity-50 cursor-pointer ${
              isDestructive
                ? 'bg-danger hover:bg-danger/90 active:scale-95'
                : 'bg-primary hover:bg-primary/90 active:scale-95'
            }`}
          >
            {isLoading ? 'جارٍ المعالجة...' : confirmLabel}
          </button>
        </div>
      </div>
    </div>
  )
}
