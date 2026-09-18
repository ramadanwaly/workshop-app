'use client'

import { useState, useEffect, useRef } from 'react'
import { useRouter, usePathname, useSearchParams } from 'next/navigation'
import { Input } from '@/components/ui/input'
import { useDebounce } from '@/lib/hooks/use-debounce'

type DebouncedSearchInputProps = {
  initialValue?: string
  placeholder?: string
  className?: string
  paramName?: string
}

export function DebouncedSearchInput({
  initialValue = '',
  placeholder = 'بحث...',
  className = '',
  paramName = 'q',
}: DebouncedSearchInputProps) {
  const router = useRouter()
  const pathname = usePathname()
  const searchParams = useSearchParams()
  
  const isInitialMount = useRef(true)

  const [value, setValue] = useState(initialValue)
  const debouncedValue = useDebounce(value, 300)

  // Only update URL when debounced value changes after mount
  useEffect(() => {
    if (isInitialMount.current) {
      isInitialMount.current = false
      return
    }

    const params = new URLSearchParams(searchParams.toString())
    if (debouncedValue) {
      params.set(paramName, debouncedValue)
    } else {
      params.delete(paramName)
    }
    
    // Always reset to page 1 on new search if a page param exists
    if (params.has('page')) {
        params.delete('page')
    }

    router.replace(`${pathname}?${params.toString()}`, { scroll: false })
  }, [debouncedValue, pathname, router, searchParams, paramName])

  return (
    <div className="relative w-full">
      <Input
        type="search"
        value={value}
        onChange={(e) => setValue(e.target.value)}
        placeholder={placeholder}
        className={className}
      />
    </div>
  )
}
