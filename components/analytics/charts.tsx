'use client'

import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  ComposedChart,
  Line
} from 'recharts'

export function formatCurrency(value: number | string | null | undefined): string {
    return `${Number(value ?? 0).toLocaleString('ar-EG')} ج.م`
}

type TreasuryData = { month: string; total_in: number; total_out: number; [key: string]: unknown }
export function TreasuryChart({ data }: { data: TreasuryData[] }) {
    const formattedData = data.map(item => ({
        ...item,
        displayMonth: new Date(item.month).toLocaleDateString('ar-EG', { month: 'short', year: 'numeric' })
    }))

    const chartData = [...formattedData].reverse()

    return (
        <div className="mt-6 h-[400px] w-full" dir="ltr">
            <ResponsiveContainer width="100%" height="100%">
                <BarChart data={chartData} margin={{ top: 20, right: 30, left: 40, bottom: 5 }}>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="var(--brand-border)" />
                    <XAxis dataKey="displayMonth" tick={{ fill: 'var(--brand-muted-foreground)' }} axisLine={{ stroke: 'var(--brand-border)' }} />
                    <YAxis 
                        tickFormatter={(val) => Number(val).toLocaleString('en-US')} 
                        tick={{ fill: 'var(--brand-muted-foreground)' }} 
                        axisLine={{ stroke: 'var(--brand-border)' }} 
                    />
                    <Tooltip 
                        formatter={(value: unknown) => [formatCurrency(value as number), '']}
                        contentStyle={{ backgroundColor: 'var(--brand-card)', borderColor: 'var(--brand-border)', borderRadius: '0.375rem', color: 'var(--brand-card-foreground)' }}
                    />
                    <Legend />
                    <Bar dataKey="total_in" name="الإيرادات" fill="var(--brand-success)" radius={[4, 4, 0, 0]} />
                    <Bar dataKey="total_out" name="المصروفات" fill="var(--brand-danger)" radius={[4, 4, 0, 0]} />
                </BarChart>
            </ResponsiveContainer>
        </div>
    )
}

type ProjectProfitabilityData = { project_name: string; total_revenue: number; estimated_total_cost: number; net_profit: number; [key: string]: unknown }
export function ProjectProfitabilityChart({ data }: { data: ProjectProfitabilityData[] }) {
    return (
        <div className="mt-6 h-[400px] w-full" dir="ltr">
            <ResponsiveContainer width="100%" height="100%">
                <ComposedChart data={data} margin={{ top: 20, right: 30, left: 40, bottom: 5 }}>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="var(--brand-border)" />
                    <XAxis dataKey="project_name" tick={{ fill: 'var(--brand-muted-foreground)' }} axisLine={{ stroke: 'var(--brand-border)' }} />
                    <YAxis 
                        tickFormatter={(val) => Number(val).toLocaleString('en-US')} 
                        tick={{ fill: 'var(--brand-muted-foreground)' }} 
                        axisLine={{ stroke: 'var(--brand-border)' }} 
                    />
                    <Tooltip 
                        formatter={(value: unknown) => [formatCurrency(value as number), '']}
                        contentStyle={{ backgroundColor: 'var(--brand-card)', borderColor: 'var(--brand-border)', borderRadius: '0.375rem', color: 'var(--brand-card-foreground)' }}
                    />
                    <Legend />
                    <Bar dataKey="total_revenue" name="إجمالي الإيرادات" fill="var(--brand-success)" radius={[4, 4, 0, 0]} />
                    <Bar dataKey="estimated_total_cost" name="التكلفة المقدرة" fill="var(--brand-danger)" radius={[4, 4, 0, 0]} />
                    <Line type="monotone" dataKey="net_profit" name="صافي الربح" stroke="var(--brand-accent)" strokeWidth={3} dot={{ r: 6, fill: 'var(--brand-accent)' }} />
                </ComposedChart>
            </ResponsiveContainer>
        </div>
    )
}

type WorkerPerformanceData = { worker_name: string; month: string; total_days: number; total_wages: number; total_advances: number; [key: string]: unknown }
export function WorkerPerformanceChart({ data }: { data: WorkerPerformanceData[] }) {
    const formattedData = data.map(item => ({
        ...item,
        displayName: `${item.worker_name} (${new Date(item.month).toLocaleDateString('ar-EG', { month: 'short' })})`
    }))

    
    // reverse so earliest is first
    const chartData = [...formattedData].reverse()

    return (
        <div className="mt-6 h-[400px] w-full" dir="ltr">
            <ResponsiveContainer width="100%" height="100%">
                <ComposedChart data={chartData} margin={{ top: 20, right: 30, left: 40, bottom: 5 }}>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="var(--brand-border)" />
                    <XAxis dataKey="displayName" tick={{ fill: 'var(--brand-muted-foreground)' }} axisLine={{ stroke: 'var(--brand-border)' }} />
                    <YAxis 
                        yAxisId="left" 
                        tickFormatter={(val) => Number(val).toLocaleString('en-US')} 
                        tick={{ fill: 'var(--brand-muted-foreground)' }} 
                        axisLine={{ stroke: 'var(--brand-border)' }} 
                    />
                    <YAxis 
                        yAxisId="right" 
                        orientation="right" 
                        tickFormatter={(val) => `${Number(val)}`} 
                        tick={{ fill: 'var(--brand-muted-foreground)' }} 
                        axisLine={{ stroke: 'var(--brand-border)' }} 
                    />
                    <Tooltip 
                        contentStyle={{ backgroundColor: 'var(--brand-card)', borderColor: 'var(--brand-border)', borderRadius: '0.375rem', color: 'var(--brand-card-foreground)' }}
                    />
                    <Legend />
                    <Bar yAxisId="left" dataKey="total_wages" name="الأجور المحسوبة" fill="var(--brand-primary)" radius={[4, 4, 0, 0]} />
                    <Bar yAxisId="left" dataKey="total_advances" name="السلف المسحوبة" fill="var(--brand-danger)" radius={[4, 4, 0, 0]} />
                    <Line yAxisId="right" type="monotone" dataKey="total_days" name="أيام العمل" stroke="var(--brand-accent)" strokeWidth={3} dot={{ r: 4, fill: 'var(--brand-accent)' }} />
                </ComposedChart>
            </ResponsiveContainer>
        </div>
    )
}
