import { useState } from 'react'
import { Link } from 'react-router-dom'
import { Bell, Check, ArrowUpRight } from 'lucide-react'
import { api } from '../api/client'
import { useWorkspace } from '../context'
import { useApi } from '../hooks/useApi'
import { date, Empty, ErrorNotice, label, Loading, PageHeading, Pagination } from '../components/ui'
import type { Notice } from '../types'
export function Notifications() {
  const { org, refreshNotifications } = useWorkspace()
  const [page, setPage] = useState(1)
  const { result, loading, error, reload } = useApi<Notice[]>(`/notifications?page=${page}`, org)
  const [mutationError, setError] = useState<Error>()
  const [pending, setPending] = useState<string>()
  async function markRead(id: string) {
    setPending(id)
    setError(undefined)
    try {
      await api(`/notifications/${id}/read`, { org, method: 'PATCH' })
      reload()
      refreshNotifications()
    } catch (reason) {
      setError(reason as Error)
    } finally {
      setPending(undefined)
    }
  }
  return (
    <>
      <PageHeading
        eyebrow="STAY IN THE LOOP"
        title="Notifications"
        description={`${result?.unread_count || 0} unread updates in this workspace.`}
      />
      <ErrorNotice error={error || mutationError} />
      <section className="panel">
        {loading ? (
          <Loading />
        ) : result?.data.length ? (
          <>
            <div className="notification-list">
              {result.data.map((notice) => (
                <article
                  key={notice.id}
                  className={`notification-row ${notice.read_at ? '' : 'unread'}`}
                >
                  <span className="notice-icon">
                    <Bell size={18} />
                  </span>
                  <div>
                    <span className="eyebrow">{label(notice.kind)}</span>
                    <h2>{notice.message}</h2>
                    <p>{date(notice.created_at)}</p>
                    {notice.ticket_id && (
                      <Link className="text-link" to={`/app/tickets/${notice.ticket_id}`}>
                        Open ticket <ArrowUpRight size={13} />
                      </Link>
                    )}
                  </div>
                  {notice.read_at ? (
                    <span className="read-label">
                      <Check size={13} /> Read
                    </span>
                  ) : (
                    <button disabled={pending === notice.id} onClick={() => markRead(notice.id)}>
                      Mark read
                    </button>
                  )}
                </article>
              ))}
            </div>
            <Pagination
              page={result.meta!.page}
              total={result.meta!.total_pages}
              setPage={setPage}
            />
          </>
        ) : (
          <Empty title="You're all caught up">
            Assignments and service updates will appear here.
          </Empty>
        )}
      </section>
    </>
  )
}
