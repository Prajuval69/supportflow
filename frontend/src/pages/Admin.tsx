import { useState, type FormEvent } from 'react'
import { Plus, ShieldCheck } from 'lucide-react'
import { api } from '../api/client'
import { useWorkspace } from '../context'
import { useApi } from '../hooks/useApi'
import { Badge, Empty, ErrorNotice, Field, label, Loading, PageHeading } from '../components/ui'
import type { Category, Member, SlaPolicy } from '../types'
export function AdminGate({ children }: { children: React.ReactNode }) {
  const { admin } = useWorkspace()
  return admin ? children : <Empty title="Admin access required">Your current workspace role cannot manage these settings.</Empty>
}
export function Team() {
  const { org, identity } = useWorkspace()
  const { result, error, loading, reload } = useApi<Member[]>('/memberships', org)
  const [mutationError, setError] = useState<Error>()
  const [busy, setBusy] = useState(false)
  const [success, setSuccess] = useState('')
  async function add(event: FormEvent<HTMLFormElement>) {
    event.preventDefault(); setError(undefined); setSuccess(''); setBusy(true); const form = event.currentTarget
    try { await api('/memberships', { org, method: 'POST', body: { membership: Object.fromEntries(new FormData(form)) } }); form.reset(); reload(); setSuccess('Member added to the workspace.') }
    catch (reason) { setError(reason as Error) } finally { setBusy(false) }
  }
  async function update(event: FormEvent<HTMLFormElement>, member: Member) {
    event.preventDefault()
    if (!window.confirm(`Update role and access for ${member.user.name}?`)) return
    setError(undefined); setSuccess(''); setBusy(true)
    const data = new FormData(event.currentTarget)
    try { await api(`/memberships/${member.id}`, { org, method: 'PATCH', body: { membership: { role: data.get('role'), active: data.get('active') === 'true' } } }); reload(); setSuccess('Member access updated.'); if (member.user.id === identity.user.id) window.location.reload() }
    catch (reason) { setError(reason as Error) } finally { setBusy(false) }
  }
  return <><PageHeading eyebrow="WORKSPACE SETTINGS" title="People & permissions" description="Give each teammate the right access to do their best work." /><ErrorNotice error={error || mutationError} />{success && <div role="status" className="success-notice">{success}</div>}<section className="panel admin-form"><h2>Add a member</h2><p className="muted">Use an existing account email, or include a name and initial password to create a local account.</p><form onSubmit={add}><div className="admin-add-grid"><Field label="Email address"><input name="email" type="email" required placeholder="teammate@example.com" /></Field><Field label="Name (new account)"><input name="name" maxLength={100} /></Field><Field label="Initial password (new account)"><input name="password" type="password" minLength={12} maxLength={72} autoComplete="new-password" /></Field><Field label="Role"><select name="role" defaultValue="customer">{['customer', 'agent', 'admin'].map(role => <option key={role} value={role}>{label(role)}</option>)}</select></Field></div><button className="button primary" disabled={busy}>Add member <Plus size={15} /></button></form></section><section className="panel admin-table">{loading ? <Loading /> : result?.data.map(member => <form key={`${member.id}:${member.role}:${member.active}`} className="member-row" onSubmit={e => update(e, member)}><div className="member-info"><span className="avatar">{member.user.name.charAt(0)}</span><div><strong>{member.user.name}{member.user.id === identity.user.id ? ' (you)' : ''}</strong><p>{member.user.email}</p></div></div><Field label={`Role for ${member.user.name}`}><select name="role" defaultValue={member.role}>{['customer', 'agent', 'admin'].map(role => <option key={role} value={role}>{label(role)}</option>)}</select></Field><Field label={`Access for ${member.user.name}`}><select name="active" defaultValue={String(member.active)}><option value="true">Active</option><option value="false">Deactivated</option></select></Field><button disabled={busy}>Save</button></form>)}</section><p className="settings-footnote"><ShieldCheck size={15} /> The last active admin is protected from removal.</p></>
}
export function Categories() {
  const { org } = useWorkspace()
  const { result, loading, error, reload } = useApi<Category[]>('/categories', org)
  const [mutationError, setError] = useState<Error>()
  const [busy, setBusy] = useState(false)
  async function save(event: FormEvent<HTMLFormElement>, category?: Category) {
    event.preventDefault(); setError(undefined); setBusy(true); const form = event.currentTarget
    const data = new FormData(form)
    if (category && data.get('active') === 'false' && category.active && !window.confirm('Deactivate this category for new tickets?')) { setBusy(false); return }
    try { await api(`/categories${category ? `/${category.id}` : ''}`, { org, method: category ? 'PATCH' : 'POST', body: { category: { name: data.get('name'), ...(category ? { active: data.get('active') === 'true' } : {}) } } }); if (!category) form.reset(); reload() }
    catch (reason) { setError(reason as Error) } finally { setBusy(false) }
  }
  return <><PageHeading eyebrow="WORKSPACE SETTINGS" title="Ticket categories" description="A little structure helps every request find its way." /><ErrorNotice error={error || mutationError} /><section className="panel admin-form"><form onSubmit={e => save(e)} className="inline-form"><Field label="New category name"><input name="name" required maxLength={80} placeholder="e.g. Product feedback" /></Field><button className="button primary" disabled={busy}>Add category <Plus size={15} /></button></form></section><section className="panel admin-table">{loading ? <Loading /> : result?.data.length ? result.data.map(category => <form className="category-row" key={`${category.id}:${category.name}:${category.active}`} onSubmit={e => save(e, category)}><Field label="Category name"><input name="name" defaultValue={category.name} required maxLength={80} /></Field><Field label={`Availability for ${category.name}`}><select name="active" defaultValue={String(category.active)}><option value="true">Active</option><option value="false">Deactivated</option></select></Field><button disabled={busy}>Save</button></form>) : <Empty title="No categories yet" />}</section></>
}
function SlaRow({ policy, save, busy }: { policy: SlaPolicy; save: (event: FormEvent<HTMLFormElement>, priority: string) => void; busy: boolean }) {
  return <form className="sla-row" onSubmit={event => save(event, policy.priority)}><div><Badge value={policy.priority} /><p>{policy.priority === 'urgent' ? 'Service at a standstill' : policy.priority === 'high' ? 'Significant impact' : policy.priority === 'normal' ? 'Everyday support' : 'Can wait a little'}</p></div><Field label={`First response for ${policy.priority} (minutes)`}><input name="first_response_minutes" type="number" min={1} max={525600} required defaultValue={policy.first_response_minutes} /></Field><Field label={`Resolution for ${policy.priority} (minutes)`}><input name="resolution_minutes" type="number" min={1} max={525600} required defaultValue={policy.resolution_minutes} /></Field><button disabled={busy}>Save policy</button></form>
}
export function Sla() {
  const { org } = useWorkspace()
  const { result, loading, error, reload } = useApi<SlaPolicy[]>('/sla_policies', org)
  const [mutationError, setError] = useState<Error>()
  const [busy, setBusy] = useState(false)
  const [success, setSuccess] = useState('')
  async function save(event: FormEvent<HTMLFormElement>, priority: string) {
    event.preventDefault(); setBusy(true); setError(undefined); setSuccess('')
    const data = new FormData(event.currentTarget)
    try { await api(`/sla_policies/${priority}`, { org, method: 'PATCH', body: { sla_policy: Object.fromEntries(data) } }); reload(); setSuccess(`${label(priority)} policy saved. New tickets will use these targets.`) }
    catch (reason) { setError(reason as Error) } finally { setBusy(false) }
  }
  return <><PageHeading eyebrow="WORKSPACE SETTINGS" title="Service commitments" description="Set clear expectations. Give your team a target to work toward." /><div className="info-banner"><ClockPolicy /> <p>Targets use elapsed calendar minutes, around the clock. Changes apply to new tickets. Existing deadlines stay as originally promised.</p></div><ErrorNotice error={error || mutationError} />{success && <div className="success-notice" role="status">{success}</div>}<section className="panel admin-table">{loading ? <Loading /> : ['urgent', 'high', 'normal', 'low'].map(priority => { const policy = result?.data.find(p => p.priority === priority); return policy && <SlaRow key={`${priority}:${policy.first_response_minutes}:${policy.resolution_minutes}`} policy={policy} save={save} busy={busy} /> })}</section><p className="settings-footnote"><ShieldCheck size={15} /> Overdue tickets are checked by the background worker every five minutes.</p></>
}
function ClockPolicy() { return <ShieldCheck size={23} /> }
