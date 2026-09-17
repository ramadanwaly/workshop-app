// ----------------------------------------------------------------------------
// P2-08 — تنقية مسار العودة بعد الدخول: لا نثق بقيمة ?next= القادمة من الرابط.
// المسموح فقط مسار داخلي يبدأ بشرطة واحدة (مثل /dashboard)؛ أي شيء آخر
// (روابط خارجية أو // أو فارغ) يسقط على /dashboard.
// ----------------------------------------------------------------------------

export function safeNextPath(raw: unknown): string {
    if (typeof raw !== 'string') return '/dashboard';
    const trimmed = raw.trim();
    // Must start with '/' followed by alphanumeric, strictly disallow '\' or '//'
    if (!/^\/[a-zA-Z0-9\-_]/.test(trimmed) || trimmed.includes('\\')) {
        return '/dashboard';
    }
    return trimmed;
}
