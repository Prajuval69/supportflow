import { useCallback, useEffect, useState } from 'react'
import { api } from '../api/client'
import type { Response } from '../types'
export function useApi<T>(path: string, org: string, enabled = true) {
  const key = `${org}:${path}`
  const [stored, setStored] = useState<{ key: string; result: Response<T> }>()
  const result = stored?.key === key ? stored.result : undefined
  const [error, setError] = useState<Error>()
  const [loading, setLoading] = useState(true)
  const [revision, setRevision] = useState(0)
  const reload = useCallback(() => setRevision(value => value + 1), [])
  useEffect(() => {
    if (!enabled) { setLoading(false); return }
    const controller = new AbortController()
    setLoading(true); setError(undefined)
    api<T>(path, { org, signal: controller.signal }).then(data => {
      if (!controller.signal.aborted) setStored({ key: `${org}:${path}`, result: data })
    }).catch((reason: Error) => {
      if (!controller.signal.aborted) setError(reason)
    }).finally(() => { if (!controller.signal.aborted) setLoading(false) })
    return () => controller.abort()
  }, [path, org, revision, enabled])
  return { result, error, loading, reload }
}
