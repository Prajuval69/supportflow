import { cloneElement, isValidElement, useId, type ReactElement, type ReactNode } from 'react'
import { AlertCircle, Inbox, ArrowUpRight } from 'lucide-react'
import { Link } from 'react-router-dom'
export const label = (value: string) =>
  value.replaceAll('_', ' ').replace(/\b\w/g, (character) => character.toUpperCase())
export const date = (value: string) =>
  new Date(value).toLocaleString(undefined, {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
export function Badge({ value }: { value: string }) {
  return <span className={`badge badge-${value}`}>{label(value)}</span>
}
export function ErrorNotice({ error }: { error?: Error }) {
  return error ? (
    <div className="error-notice" role="alert">
      <AlertCircle size={18} />
      <span>
        {error.message}
        {'fields' in error && error.fields ? (
          <ul>
            {Object.entries(error.fields as Record<string, string[]>).map(([key, values]) => (
              <li key={key}>
                {label(key)}: {values.join(', ')}
              </li>
            ))}
          </ul>
        ) : null}
      </span>
    </div>
  ) : null
}
export function Loading() {
  return (
    <div className="loading" role="status" aria-label="Loading">
      <div className="skeleton" />
      <div className="skeleton" />
      <div className="skeleton" />
      <span className="sr-only">Loading workspace data</span>
    </div>
  )
}
export function Empty({
  title = 'Nothing here yet',
  children,
}: {
  title?: string
  children?: ReactNode
}) {
  return (
    <div className="empty">
      <Inbox size={32} />
      <h2>{title}</h2>
      <p>{children || 'Your workspace is up to date.'}</p>
    </div>
  )
}
export function PageHeading({
  eyebrow,
  title,
  description,
  action,
}: {
  eyebrow: string
  title: string
  description?: string
  action?: ReactNode
}) {
  return (
    <div className="page-heading">
      <div>
        <p className="eyebrow">{eyebrow}</p>
        <h1>{title}</h1>
        {description && <p className="muted">{description}</p>}
      </div>
      {action}
    </div>
  )
}
export function NewTicketLink() {
  return (
    <Link className="button primary" to="/app/tickets/new">
      New ticket <ArrowUpRight size={17} />
    </Link>
  )
}
export function Field({ label: text, children }: { label: string; children: ReactNode }) {
  const id = useId()
  const control =
    isValidElement(children) && ['input', 'select', 'textarea'].includes(String(children.type))
      ? cloneElement(children as ReactElement<{ 'aria-labelledby'?: string }>, {
          'aria-labelledby': id,
        })
      : children
  return (
    <label className="field">
      <span id={id}>{text}</span>
      {control}
    </label>
  )
}
export function Pagination({
  page,
  total,
  setPage,
}: {
  page: number
  total: number
  setPage: (page: number) => void
}) {
  return (
    <nav className="pagination" aria-label="Pagination">
      <span>
        Page {page} of {Math.max(total, 1)}
      </span>
      <div>
        <button disabled={page <= 1} onClick={() => setPage(page - 1)}>
          Previous
        </button>
        <button disabled={page >= total} onClick={() => setPage(page + 1)}>
          Next
        </button>
      </div>
    </nav>
  )
}
