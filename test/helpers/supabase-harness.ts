// Shared test harness for financial server actions (actions/*.ts).
//
// Replaces the ~60-line hand-rolled `vi.hoisted` + `vi.mock('@/lib/supabase/server')`
// blocks that were duplicated in every action test file. A single instance is
// created per test file via:
//
//   const h = vi.hoisted(() => createSupabaseHarness())
//   vi.mock('@/lib/supabase/server', () => ({ createClient: h.createClient }))
//
// It keeps the same mental model as the old mocks:
//   - h.state.user / h.state.role drives auth.getUser() and from('profiles')
//   - h.when(table, method, data) / h.fail(table, method, error) shape the
//     terminal result of a query chain (methods: 'insert' | 'update' | 'select')
//   - h.rpcOk(fn, data) / h.rpcFail(fn, error) shape RPC results
//   - h.idempotency.existing drives the cached/pending path of the REAL
//     @/lib/supabase/idempotency module (not mocked)
//   - h.callsOf() / h.rpcOf() assert what was sent to the database
//   - h.reset() in beforeEach restores defaults

import type { PostgrestError } from '@supabase/supabase-js'

export type HarnessUser = { id: string }

export type HarnessCall = {
  table: string
  method: string
  args: unknown[]
}

export type HarnessRpcCall = {
  fn: string
  args: Record<string, unknown>
}

export type HarnessResult = { data: unknown; error: PostgrestError | null; count?: number | null }

export function postgrestError(code: string, message: string): PostgrestError {
  return {
    name: 'PostgrestError',
    code,
    message,
    details: '',
    hint: '',
    toJSON: () => ({
      name: 'PostgrestError',
      code,
      message,
      details: '',
      hint: '',
    }),
  }
}

export interface HarnessQueryBuilder {
  select(...args: unknown[]): HarnessQueryBuilder
  insert(value: unknown): HarnessQueryBuilder
  update(value: unknown): HarnessQueryBuilder
  eq(column: string, value: unknown): HarnessQueryBuilder
  ilike(column: string, value: unknown): HarnessQueryBuilder
  gte(column: string, value: unknown): HarnessQueryBuilder
  lt(column: string, value: unknown): HarnessQueryBuilder
  order(...args: unknown[]): HarnessQueryBuilder
  limit(count: number): HarnessQueryBuilder
  range(from: number, to: number): HarnessQueryBuilder
  single(): HarnessResult
  maybeSingle(): HarnessResult
  then<TResult1 = HarnessResult, TResult2 = never>(
    onfulfilled?: ((value: HarnessResult) => TResult1 | PromiseLike<TResult1>) | null,
    onrejected?: ((reason: unknown) => TResult2 | PromiseLike<TResult2>) | null
  ): Promise<TResult1 | TResult2>
}

export interface SupabaseHarness {
  state: { user: HarnessUser | null; role: string | null }
  createClient: () => {
    auth: { getUser: () => Promise<{ data: { user: HarnessUser | null } }> }
    from: (table: string) => HarnessQueryBuilder
    rpc: (fn: string, args: Record<string, unknown>) => Promise<HarnessResult>
  }
  results: Record<string, Record<string, unknown>>
  errors: Record<string, Record<string, PostgrestError | null>>
  rpcResults: Record<string, HarnessResult>
  idempotency: {
    existing: { status: string; response_payload?: unknown } | null
    insertError: PostgrestError | null
  }
  calls(): HarnessCall[]
  callsOf(table: string, method?: string): HarnessCall[]
  rpcCalls(): HarnessRpcCall[]
  rpcOf(fn: string): HarnessRpcCall[]
  when(table: string, method: 'insert' | 'update' | 'select', data: unknown): void
  whenCount(table: string, count: number): void
  fail(table: string, method: 'insert' | 'update' | 'select', error: PostgrestError): void
  rpcOk(fn: string, data: unknown): void
  rpcFail(fn: string, error: PostgrestError): void
  reset(): void
}

function success(data: unknown, count: number | null = null): HarnessResult {
  return { data, error: null, count }
}

function idempotencyOutcome(harness: Core, chain: Chain): HarnessResult {
  if (chain.calls.some((c) => c.method === 'insert')) {
    if (harness.idempotency.insertError) {
      return { data: null, error: harness.idempotency.insertError }
    }
    return success({})
  }
  if (chain.calls.some((c) => c.method === 'update')) {
    return success({})
  }
  return success(harness.idempotency.existing)
}

function outcome(harness: Core, table: string, chain: Chain): HarnessResult {
  if (table === 'profiles') {
    return success({ role: harness.state.role })
  }
  if (table === 'idempotency_keys') {
    return idempotencyOutcome(harness, chain)
  }

  const bucket = chain.calls.some((c) => c.method === 'update')
    ? 'update'
    : chain.calls.some((c) => c.method === 'insert')
      ? 'insert'
      : 'select'
  const err = harness.errors[table]?.[bucket]
  if (err) {
    return { data: null, error: err, count: null }
  }
  return success(
    harness.results[table]?.[bucket] ?? null,
    harness.counts[table] ?? null
  )
}

type Chain = { table: string; calls: { method: string; args: unknown[] }[] }
type Core = {
  state: SupabaseHarness['state']
  log: HarnessCall[]
  rpcLog: HarnessRpcCall[]
  results: SupabaseHarness['results']
  errors: SupabaseHarness['errors']
  counts: Record<string, number>
  rpcResults: SupabaseHarness['rpcResults']
  idempotency: SupabaseHarness['idempotency']
}

export function createSupabaseHarness(): SupabaseHarness {
  const core = {
    state: { 
      user: { id: '11111111-1111-4111-8111-111111111111' } as HarnessUser | null, 
      role: 'owner' as string | null 
    },
    log: [] as HarnessCall[],
    rpcLog: [] as HarnessRpcCall[],
    results: {
      v_treasury_balance: { select: { current_balance: 1000000 } },
    } as SupabaseHarness['results'],
    errors: {} as SupabaseHarness['errors'],
    counts: {} as Record<string, number>,
    rpcResults: {} as SupabaseHarness['rpcResults'],
    idempotency: {
      existing: null as { status: string; response_payload?: unknown } | null,
      insertError: null as PostgrestError | null,
    },
  } satisfies Core

  function createBuilder(table: string): HarnessQueryBuilder {
    const chain: Chain = { table, calls: [] }
    const record = (method: string, args: unknown[]) => {
      chain.calls.push({ method, args })
      core.log.push({ table, method, args })
    }
    const resolve = (): HarnessResult => outcome(core, table, chain)

    return {
      select(...args: unknown[]) {
        record('select', args)
        return this
      },
      insert(value: unknown) {
        record('insert', [value])
        return this
      },
      update(value: unknown) {
        record('update', [value])
        return this
      },
      eq(column: string, value: unknown) {
        record('eq', [column, value])
        return this
      },
      ilike(column: string, value: unknown) {
        record('ilike', [column, value])
        return this
      },
      gte(column: string, value: unknown) {
        record('gte', [column, value])
        return this
      },
      lt(column: string, value: unknown) {
        record('lt', [column, value])
        return this
      },
      order(...args: unknown[]) {
        record('order', args)
        return this
      },
      limit(count: number) {
        record('limit', [count])
        return this
      },
      range(from: number, to: number) {
        record('range', [from, to])
        return this
      },
      single() {
        record('single', [])
        return resolve()
      },
      maybeSingle() {
        record('maybeSingle', [])
        return resolve()
      },
      then<TResult1 = HarnessResult, TResult2 = never>(
        onfulfilled?: ((value: HarnessResult) => TResult1 | PromiseLike<TResult1>) | null,
        onrejected?: ((reason: unknown) => TResult2 | PromiseLike<TResult2>) | null
      ) {
        const settled = (async () => resolve())()
        return settled.then(onfulfilled, onrejected)
      },
    }
  }

  return {
    state: core.state,
    results: core.results,
    errors: core.errors,
    rpcResults: core.rpcResults,
    idempotency: core.idempotency,

    createClient: () => ({
      auth: {
        getUser: async () => ({ data: { user: core.state.user } }),
      },
      from: (table: string) => createBuilder(table),
      rpc: async (fn: string, args: Record<string, unknown>) => {
        core.rpcLog.push({ fn, args })
        return core.rpcResults[fn] ?? { data: null, error: null }
      },
    }),

    calls: () => core.log,
    callsOf: (table: string, method?: string) =>
      core.log.filter(
        (c) => c.table === table && (method === undefined || c.method === method)
      ),
    rpcCalls: () => core.rpcLog,
    rpcOf: (fn: string) => core.rpcLog.filter((c) => c.fn === fn),

    when(table: string, method: 'insert' | 'update' | 'select', data: unknown) {
      core.results[table] ??= {}
      core.results[table][method] = data
    },
    whenCount(table: string, count: number) {
      core.counts[table] = count
    },
    fail(table: string, method: 'insert' | 'update' | 'select', error: PostgrestError) {
      core.errors[table] ??= {}
      core.errors[table][method] = error
    },
    rpcOk(fn: string, data: unknown) {
      core.rpcResults[fn] = { data, error: null }
    },
    rpcFail(fn: string, error: PostgrestError) {
      core.rpcResults[fn] = { data: null, error }
    },

    reset() {
      core.state.user = { id: '11111111-1111-4111-8111-111111111111' }
      core.state.role = 'owner'
      core.log.length = 0
      core.rpcLog.length = 0
      for (const key of Object.keys(core.results)) {
        if (key !== 'v_treasury_balance') delete core.results[key]
      }
      for (const key of Object.keys(core.errors)) delete core.errors[key]
      for (const key of Object.keys(core.counts)) delete core.counts[key]
      for (const key of Object.keys(core.rpcResults)) delete core.rpcResults[key]
      core.idempotency.existing = null
      core.idempotency.insertError = null
    },
  }
}