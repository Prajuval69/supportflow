import { useSearchParams } from 'react-router-dom'
import { Search, SlidersHorizontal } from 'lucide-react'
import { useWorkspace } from '../context'
import { useApi } from '../hooks/useApi'
import {
  ErrorNotice,
  Field,
  label,
  Loading,
  NewTicketLink,
  PageHeading,
  Pagination,
} from '../components/ui'
import { TicketTable } from '../components/TicketTable'
import type { Category, Member, Ticket } from '../types'
export function Tickets() {
  const { org, staff } = useWorkspace()
  const [params, setParams] = useSearchParams()
  const query = new URLSearchParams(params)
  query.set('per_page', '10')
  const { result, loading, error } = useApi<Ticket[]>(`/tickets?${query}`, org)
  const categories = useApi<Category[]>('/categories', org)
  const members = useApi<Member[]>('/memberships', org, staff)
  function update(key: string, value: string) {
    const next = new URLSearchParams(params)
    value ? next.set(key, value) : next.delete(key)
    if (key !== 'page') next.delete('page')
    setParams(next)
  }
  return (
    <>
      <PageHeading
        eyebrow="THE WORK QUEUE"
        title={staff ? 'Ticket inbox' : 'Your tickets'}
        description="Every conversation, with a clear next step."
        action={<NewTicketLink />}
      />
      <section className="panel">
        <div className="inbox-header">
          <h2>
            All tickets <span className="count">{result?.meta?.total_count ?? '…'}</span>
          </h2>
          <span className="muted small-text">
            <SlidersHorizontal size={14} /> Make the queue your own
          </span>
        </div>
        <div className="filters">
          <Field label="Search tickets">
            <span className="search-input">
              <Search size={17} />
              <input
                type="search"
                placeholder="Search title or ticket number"
                value={params.get('q') || ''}
                onChange={(e) => update('q', e.target.value)}
              />
            </span>
          </Field>
          <Field label="Status">
            <select
              value={params.get('status') || ''}
              onChange={(e) => update('status', e.target.value)}
            >
              <option value="">All statuses</option>
              {['open', 'in_progress', 'waiting_on_customer', 'resolved', 'closed'].map((value) => (
                <option key={value} value={value}>
                  {label(value)}
                </option>
              ))}
            </select>
          </Field>
          <Field label="Priority">
            <select
              value={params.get('priority') || ''}
              onChange={(e) => update('priority', e.target.value)}
            >
              <option value="">All priorities</option>
              {['low', 'normal', 'high', 'urgent'].map((value) => (
                <option key={value} value={value}>
                  {label(value)}
                </option>
              ))}
            </select>
          </Field>
          <Field label="Category">
            <select
              value={params.get('category_id') || ''}
              onChange={(e) => update('category_id', e.target.value)}
            >
              <option value="">All categories</option>
              {categories.result?.data.map((category) => (
                <option key={category.id} value={category.id}>
                  {category.name}
                </option>
              ))}
            </select>
          </Field>
          {staff && (
            <Field label="Assignee">
              <select
                value={params.get('assignee_id') || ''}
                onChange={(e) => update('assignee_id', e.target.value)}
              >
                <option value="">Any assignee</option>
                {members.result?.data
                  .filter((member) => member.active && member.role !== 'customer')
                  .map((member) => (
                    <option key={member.id} value={member.user.id}>
                      {member.user.name}
                    </option>
                  ))}
              </select>
            </Field>
          )}
          <Field label="Sort by">
            <select
              value={`${params.get('sort') || 'created_at'}:${params.get('direction') || 'desc'}`}
              onChange={(e) => {
                const [sort, direction] = e.target.value.split(':')
                const next = new URLSearchParams(params)
                next.set('sort', sort)
                next.set('direction', direction)
                next.delete('page')
                setParams(next)
              }}
            >
              <option value="created_at:desc">Newest first</option>
              <option value="created_at:asc">Oldest first</option>
              <option value="updated_at:desc">Recently updated</option>
              <option value="priority:desc">Highest priority</option>
            </select>
          </Field>
        </div>
        <ErrorNotice error={error} />
        {loading ? (
          <Loading />
        ) : (
          result && (
            <>
              <TicketTable tickets={result.data} />
              <Pagination
                page={result.meta!.page}
                total={result.meta!.total_pages}
                setPage={(page) => update('page', String(page))}
              />
            </>
          )
        )}
      </section>
    </>
  )
}
