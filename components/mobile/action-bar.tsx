'use client'

import { useState } from 'react'
import dynamic from 'next/dynamic'

const ExpenseDialog = dynamic(() => import('./expense-dialog').then(mod => mod.ExpenseDialog))
const AttendanceDialog = dynamic(() => import('./attendance-dialog').then(mod => mod.AttendanceDialog))
const SurplusDialog = dynamic(() => import('./surplus-dialog').then(mod => mod.SurplusDialog))
const FundInjectionDialog = dynamic(() => import('@/components/treasury/fund-injection-dialog').then(mod => mod.FundInjectionDialog))

type SelectOption = { id: string; name: string }

type DialogKind = 'expense' | 'attendance' | 'surplus' | 'fund' | null

type MobileActionBarProps = {
  projects: SelectOption[]
  workers: SelectOption[]
  userRole?: string
}

export function MobileActionBar({ projects, workers, userRole }: MobileActionBarProps) {
  const [openDialog, setOpenDialog] = useState<DialogKind>(null)

  return (
    <>
      <nav
        aria-label="إجراءات سريعة"
        className="fixed inset-x-0 bottom-[calc(3.75rem+env(safe-area-inset-bottom))] z-40 border-t border-accent/20 bg-primary/95 backdrop-blur lg:bottom-0 lg:start-64"
      >
        <div className={`grid gap-2 p-2 pb-[max(0.5rem,env(safe-area-inset-bottom))] ${userRole === 'owner' ? 'grid-cols-4' : 'grid-cols-3'}`}>
          <BarButton label="+ مصروف" onClick={() => setOpenDialog('expense')} />
          <BarButton label="+ يومية" onClick={() => setOpenDialog('attendance')} />
          <BarButton label="+ فائض" onClick={() => setOpenDialog('surplus')} />
          {userRole === 'owner' && <BarButton label="+ تمويل" onClick={() => setOpenDialog('fund')} />}
        </div>
      </nav>

      {openDialog === 'expense' && (
        <ExpenseDialog projects={projects} onClose={() => setOpenDialog(null)} />
      )}
      {openDialog === 'attendance' && (
        <AttendanceDialog
          workers={workers}
          projects={projects}
          onClose={() => setOpenDialog(null)}
        />
      )}
      {openDialog === 'surplus' && (
        <SurplusDialog projects={projects} onClose={() => setOpenDialog(null)} />
      )}
      {openDialog === 'fund' && (
        <FundInjectionDialog onClose={() => setOpenDialog(null)} />
      )}
    </>
  )
}

function BarButton({ label, onClick }: { label: string; onClick: () => void }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="flex min-h-12 min-w-0 flex-col items-center justify-center rounded-xl bg-primary/70 p-2 text-sm font-bold text-background transition active:bg-accent active:text-primary"
    >
      {label}
    </button>
  )
}