-- زيادة الحد الأقصى لحجم صور المعرض إلى 10 ميجابايت (10485760)

UPDATE storage.buckets
SET file_size_limit = 10485760
WHERE id = 'portfolio';
