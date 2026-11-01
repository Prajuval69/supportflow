import { useState, type FormEvent } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { ArrowLeft, Send } from 'lucide-react'
import { api } from '../api/client'
import { useWorkspace } from '../context'
import { useApi } from '../hooks/useApi'
import { ErrorNotice, Field, label, Loading, PageHeading } from '../components/ui'
import type { Category, Ticket } from '../types'
export function NewTicket() {
  const { org } = useWorkspace()
  const categories = useApi<Category[]>('/categories', org)
  const [error, setError] = useState<Error>()
  const [busy, setBusy] = useState(false)
  const navigate = useNavigate()
  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault(); setBusy(true); setError(undefined)
    try {
      const result = await api<Ticket>('/tickets', { org, method: 'POST', body: { ticket: Object.fromEntries(new FormData(event.currentTarget)) } })
      navigate(`/app/tickets/${result.data.id}`, { state: { created: true } })
    } catch (reason) { setError(reason as Error) } finally { setBusy(false) }
  }
  return <><Link className="back-link" to="/app/tickets"><ArrowLeft size={16} /> Back to tickets</Link><PageHeading eyebrow="START A CONVERSATION" title="How can we help?" description="Share a few details so the right people can get to work." /><section className="panel form-panel">{categories.loading ? <Loading /> : <form onSubmit={submit}><ErrorNotice error={error || categories.error} /><Field label="Title"><input name="title" placeholder="A short summary of the issue" required maxLength={200} /></Field><Field label="Description"><textarea name="description" placeholder="What happened? What were you expecting?" required maxLength={20000} rows={7} /></Field><div className="form-grid"><Field label="Category"><select name="category_id"><option value="">General</option>{categories.result?.data.filter(c => c.active).map(category => <option key={category.id} value={category.id}>{category.name}</option>)}</select></Field><Field label="Priority"><select name="priority" defaultValue="normal">{['low', 'normal', 'high', 'urgent'].map(priority => <option key={priority} value={priority}>{label(priority)}</option>)}</select></Field></div><div className="form-actions"><span className="muted">Your support team will see this request.</span><button className="button primary" disabled={busy}>{busy ? 'Creating…' : 'Create ticket'}<Send size={16} /></button></div></form>}</section></>
}
