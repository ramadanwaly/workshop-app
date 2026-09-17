'use client'

import { useEffect, useState, useTransition } from 'react'
import type { FormEvent } from 'react'
// import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import {
  deletePortfolioPhoto,
  getProjectGalleryPhotos,
  uploadPortfolioPhoto,
  type PortfolioPhotoDto,
} from '@/actions/portfolio'
import { generateIdempotencyKey } from '@/lib/idempotency-key'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'

const ACCEPTED_TYPES = ['image/jpeg', 'image/png', 'image/webp'] as const
const MAX_FILE_SIZE = 10 * 1024 * 1024

type ManagePhotosProps = {
  projectId: string
  projectName: string
  projectStatus: string
}

type EntryInfo = {
  id: string
  display_title: string
  public_description: string | null
}

function fileExtension(name: string): string {
  const dot = name.lastIndexOf('.')
  if (dot < 0) return 'jpg'
  const ext = name.slice(dot + 1).toLowerCase()
  if (ext === 'jpeg' || ext === 'jpg') return 'jpg'
  if (ext === 'png') return 'png'
  if (ext === 'webp') return 'webp'
  return 'jpg'
}

export function ManagePhotos({ projectId, projectName, projectStatus }: ManagePhotosProps) {
  const [isPending, startTransition] = useTransition()
  const [loading, setLoading] = useState(true)
  const [loadError, setLoadError] = useState<string | null>(null)
  const [, setEntry] = useState<EntryInfo | null>(null)
  const [photos, setPhotos] = useState<PortfolioPhotoDto[]>([])
  const [deletingId, setDeletingId] = useState<string | null>(null)
  const [displayTitle, setDisplayTitle] = useState(projectName)
  const [publicDescription, setPublicDescription] = useState('')
  const [altText, setAltText] = useState('')
  const [file, setFile] = useState<File | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [notice, setNotice] = useState<string | null>(null)
  const [uploading, setUploading] = useState(false)

  const isCompleted = projectStatus === 'completed'

  async function refresh() {
    try {
      const res = await getProjectGalleryPhotos(projectId)
      setEntry(res.entry as EntryInfo | null)
      setPhotos(res.photos)
      if (res.entry) {
        setDisplayTitle((res.entry as EntryInfo).display_title)
        setPublicDescription((res.entry as EntryInfo).public_description || '')
      }
    } catch {
      setLoadError('تعذّر تحميل صور المعرض، يرجى المحاولة مرة أخرى لاحقاً')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    refresh()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [projectId])

  async function handleUpload(e: FormEvent) {
    e.preventDefault()
    if (!file) {
      setError('يرجى اختيار صورة')
      return
    }
    if (!displayTitle.trim()) {
      setError('يرجى كتابة عنوان العرض')
      return
    }
    if (file.size > MAX_FILE_SIZE) {
      setError('حجم الصورة يجب أن لا يتجاوز 10 ميجابايت')
      return
    }
    if (!ACCEPTED_TYPES.includes(file.type as typeof ACCEPTED_TYPES[number])) {
      setError('الأنواع المدعومة فقط هي JPEG, PNG, WEBP')
      return
    }
    setError(null)
    setNotice(null)
    setUploading(true)
    
    try {
      const supabase = createClient()
      const ext = fileExtension(file.name)
      const fileName = `${Date.now()}-${Math.random().toString(36).substring(7)}.${ext}`
      const storagePath = `completed/${projectId}/${fileName}`
      
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('portfolio')
        .upload(storagePath, file, { cacheControl: '3600', upsert: false })

      if (uploadError) {
        setError('تعذّر رفع الصورة إلى التخزين: ' + uploadError.message)
        setUploading(false)
        return
      }

      const sortOrder = photos.length
      const idempotencyKey = generateIdempotencyKey()
      
      startTransition(async () => {
        const res = await uploadPortfolioPhoto({
          projectId,
          displayTitle: displayTitle.trim(),
          publicDescription: publicDescription.trim() || undefined,
          storagePath: uploadData.path,
          sortOrder,
          altText: altText.trim() || undefined,
          idempotencyKey,
        })
        if (!res.success) {
          setError(res.error || 'حدث خطأ غير متوقع أثناء الحفظ')
        } else {
          setNotice('تمت إضافة الصورة بنجاح')
          setFile(null)
          setAltText('')
          refresh()
        }
        setUploading(false)
      })
    } catch (err: unknown) {
      setError('خطأ: ' + (err instanceof Error ? err.message : String(err)))
      setUploading(false)
    }
  }

  async function handleDelete(photoId: string) {
    if (!confirm('هل أنت متأكد من حذف هذه الصورة؟')) return
    setDeletingId(photoId)
    setError(null)
    setNotice(null)
    
    const idempotencyKey = generateIdempotencyKey()
    startTransition(async () => {
      const res = await deletePortfolioPhoto({ photoId, idempotencyKey })
      if (!res.success) {
        setError(res.error || 'حدث خطأ أثناء الحذف')
      } else {
        setNotice(res.error || 'تم حذف الصورة بنجاح')
        refresh()
      }
      setDeletingId(null)
    })
  }

  if (loading) return <div className="p-4">جاري التحميل...</div>
  if (loadError) return <div className="p-4 text-red-600">{loadError}</div>

  if (!isCompleted) {
    return (
      <div className="p-4 bg-orange-50 border border-orange-200 rounded text-orange-800">
        المشروع غير مكتمل. لا يمكن إدارة أو عرض الصور في المعرض إلا بعد اكتمال المشروع.
      </div>
    )
  }

  const supabase = createClient()

  return (
    <div className="space-y-8">
      {error && <div className="p-3 bg-red-50 text-red-700 border border-red-200 rounded">{error}</div>}
      {notice && <div className="p-3 bg-green-50 text-green-700 border border-green-200 rounded">{notice}</div>}
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
        <div>
          <h2 className="text-xl font-bold mb-4">إضافة صورة جديدة</h2>
          <form onSubmit={handleUpload} className="space-y-4">
            <div>
              <Label htmlFor="file">الصورة (أقل من 10MB، نوع JPG/PNG/WEBP)</Label>
              <Input
                id="file"
                type="file"
                accept="image/jpeg, image/png, image/webp"
                onChange={(e) => setFile(e.target.files?.[0] || null)}
                disabled={isPending || uploading}
                required
              />
            </div>
            <div>
              <Label htmlFor="displayTitle">عنوان العرض</Label>
              <Input
                id="displayTitle"
                value={displayTitle}
                onChange={(e) => setDisplayTitle(e.target.value)}
                disabled={isPending || uploading}
                required
                maxLength={200}
              />
            </div>
            <div>
              <Label htmlFor="publicDescription">الوصف العام (اختياري)</Label>
              <Textarea
                id="publicDescription"
                value={publicDescription}
                onChange={(e) => setPublicDescription(e.target.value)}
                disabled={isPending || uploading}
                maxLength={1000}
                rows={4}
              />
            </div>
            <div>
              <Label htmlFor="altText">نص بديل للصورة (SEO)</Label>
              <Input
                id="altText"
                value={altText}
                onChange={(e) => setAltText(e.target.value)}
                disabled={isPending || uploading}
              />
            </div>
            <Button type="submit" disabled={isPending || uploading || !file}>
              {uploading ? 'جاري الرفع...' : isPending ? 'جاري الحفظ...' : 'رفع الصورة'}
            </Button>
          </form>
        </div>

        <div>
          <h2 className="text-xl font-bold mb-4">الصور الحالية ({photos.length}/10)</h2>
          {photos.length === 0 ? (
            <div className="text-gray-500 italic">لا توجد صور في المعرض.</div>
          ) : (
            <div className="grid grid-cols-2 gap-4">
              {photos.map(photo => {
                const url = supabase.storage.from('portfolio').getPublicUrl(photo.storage_path).data.publicUrl
                return (
                  <div key={photo.id} className="border rounded relative overflow-hidden group">
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img src={url} alt={photo.alt_text || 'صورة المشروع'} className="w-full h-32 object-cover" />
                    <div className="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                      <Button
                        variant="destructive"
                        size="sm"
                        onClick={() => handleDelete(photo.id)}
                        disabled={isPending || deletingId === photo.id}
                      >
                        {deletingId === photo.id ? 'يُحذف...' : 'حذف'}
                      </Button>
                    </div>
                  </div>
                )
              })}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
