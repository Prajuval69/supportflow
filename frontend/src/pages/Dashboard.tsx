import { useState } from 'react'
import { Link } from 'react-router-dom'
import { ArrowUpRight, CircleDot, Clock3, CheckCheck, MessagesSquare } from 'lucide-react'
import { useWorkspace } from '../context'
import { useApi } from '../hooks/useApi'
import { ErrorNotice, Field, label, Loading, NewTicketLink, PageHeading } from '../components/ui'
import { TicketTable } from '../components/TicketTable'
import type { Summary } from '../types'
export function Dashboard() {
  const { org, membership, staff } = useWorkspace()
  const [from, setFrom] = useState('')
  const [to, setTo] = useState('')
  const { result, loading, error } = useApi<Summary>(`/dashboard/summary?${new URLSearchParams({ from, to })}`, org)
  const data = result?.data
  const metrics = [
    { name: 'Open tickets', value: data?.open, icon: CircleDot, note: 'Ready for a first look', tone: 'blue' },
    { name: 'In progress', value: data?.in_progress, icon: MessagesSquare, note: 'Moving toward a solution', tone: 'teal' },
    { name: 'Overdue', value: data?.overdue, icon: Clock3, note: 'Need a little attention', tone: 'amber' },
    { name: 'Resolved · 30 days', value: data?.resolved_last_30_days, icon: CheckCheck, note: 'Conversations brought to a close', tone: 'green' },
  ]
  return <><PageHeading eyebrow="WORKSPACE OVERVIEW" title="A clear view of your support." description={`${membership.organization.name} · ${staff ? 'Your team’s work, at a glance.' : 'A personal view of your conversations.'}`} action={<NewTicketLink />} /><div className="dashboard-date"><span className="muted">Ticket creation period</span><Field label="From"><input type="date" value={from} onChange={e => setFrom(e.target.value)} /></Field><Field label="To"><input type="date" value={to} onChange={e => setTo(e.target.value)} /></Field>{(from || to) && <button onClick={() => { setFrom(''); setTo('') }}>Clear dates</button>}</div><ErrorNotice error={error} />{loading ? <Loading /> : data && <><div className="metric-grid">{metrics.map(metric => <article className="metric" key={metric.name}><div><span>{metric.name}</span><metric.icon className={`metric-icon ${metric.tone}`} size={20} /></div><strong>{metric.value}</strong><p>{metric.note}</p></article>)}</div><div className="dashboard-grid"><section className="panel priority-panel"><div className="section-heading"><div><p className="eyebrow">DISTRIBUTION</p><h2>What needs your attention</h2></div><span className="muted">{data.total} total tickets</span></div><div className="priority-bars">{['urgent', 'high', 'normal', 'low'].map(priority => <div className="priority-row" key={priority}><span>{label(priority)}</span><div className="bar-track"><div className={`bar-${priority}`} style={{ width: `${data.total ? (data.by_priority[priority] || 0) / data.total * 100 : 0}%` }} /></div><strong>{data.by_priority[priority] || 0}</strong></div>)}</div></section><section className="workspace-note"><div className="note-icon"><CheckCheck size={22} /></div><p className="eyebrow">A SHARED COMMITMENT</p><h2>Every ticket has<br />a next step.</h2><p>Keep conversations moving. Check the inbox for requests waiting on your team.</p><Link to="/app/tickets">Go to ticket inbox <ArrowUpRight size={18} /></Link></section></div><section className="panel"><div className="section-heading"><div><p className="eyebrow">KEEP THE CONVERSATION MOVING</p><h2>Recently updated</h2></div><Link className="text-link" to="/app/tickets">View all tickets <ArrowUpRight size={16} /></Link></div><TicketTable tickets={data.recent_tickets} /></section></>}</>
}
