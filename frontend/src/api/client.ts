import type { Identity, Response } from '../types'
let csrfToken: string | undefined
export class ApiError extends Error {
  constructor(
    public status: number,
    message: string,
    public fields?: Record<string, string[]>,
  ) {
    super(message)
  }
}
export function resetCsrf() {
  csrfToken = undefined
}
export async function api<T>(
  path: string,
  options: { method?: string; body?: unknown; org?: string; signal?: AbortSignal } = {},
): Promise<Response<T>> {
  const method = options.method || 'GET'
  if (method !== 'GET' && !csrfToken) {
    const result = await api<{ csrf_token: string }>('/auth/csrf')
    csrfToken = result.data.csrf_token
  }
  const headers: Record<string, string> = { Accept: 'application/json' }
  if (options.org) headers['X-Organization-ID'] = options.org
  if (options.body) headers['Content-Type'] = 'application/json'
  if (method !== 'GET' && csrfToken) headers['X-CSRF-Token'] = csrfToken
  const response = await fetch(`/api/v1${path}`, {
    method,
    credentials: 'include',
    headers,
    signal: options.signal,
    body: options.body ? JSON.stringify(options.body) : undefined,
  })
  if (response.status === 204) return { data: undefined as T }
  const payload = await response.json()
  if (!response.ok) {
    if (response.status === 401 && path !== '/auth/login')
      window.dispatchEvent(new Event('supportflow:expired'))
    throw new ApiError(
      response.status,
      payload.error?.message || 'Request failed',
      payload.error?.fields,
    )
  }
  if (path === '/auth/login') csrfToken = (payload.data as Identity).csrf_token
  return payload
}
