import { useCallback, useEffect, useState } from 'react'
import { BrowserRouter, Link, Navigate, Route, Routes, useLocation, useNavigate } from 'react-router-dom'
import { api, resetCsrf } from './api/client'
import { WorkspaceContext } from './context'
import { AppShell } from './components/AppShell'
import { Empty, ErrorNotice, Loading } from './components/ui'
import { Login } from './pages/Login'
import { Dashboard } from './pages/Dashboard'
import { Tickets } from './pages/Tickets'
import { NewTicket } from './pages/NewTicket'
import { TicketDetail } from './pages/TicketDetail'
import { Notifications } from './pages/Notifications'
import { AdminGate, Team, Categories, Sla } from './pages/Admin'
import { useApi } from './hooks/useApi'
import type { Notice } from './types'
import type { Identity, Membership } from './types'
function Workspace({ identity, membership, onSwitch, logout }: { identity: Identity; membership: Membership; onSwitch: (id: string) => void; logout: () => void }) {
  const notifications = useApi<Notice[]>('/notifications?per_page=1', membership.organization.id)
  const refreshNotifications = useCallback(() => notifications.reload(), [notifications.reload])
  useEffect(() => {
    const timer = window.setInterval(refreshNotifications, 30000)
    return () => window.clearInterval(timer)
  }, [refreshNotifications])
  return <WorkspaceContext.Provider value={{ identity, membership, refreshNotifications }}><AppShell identity={identity} membership={membership} onSwitch={onSwitch} logout={logout} unread={notifications.result?.unread_count || 0}><Routes><Route index element={<Dashboard />} /><Route path="tickets" element={<Tickets />} /><Route path="tickets/new" element={<NewTicket />} /><Route path="tickets/:id" element={<TicketDetail />} /><Route path="notifications" element={<Notifications />} /><Route path="admin/team" element={<AdminGate><Team /></AdminGate>} /><Route path="admin/categories" element={<AdminGate><Categories /></AdminGate>} /><Route path="admin/sla" element={<AdminGate><Sla /></AdminGate>} /><Route path="*" element={<Empty title="Page not found"><Link to="/app">Return to overview</Link></Empty>} /></Routes></AppShell></WorkspaceContext.Provider>
}
export function Application() {
  const [identity, setIdentity] = useState<Identity | null>(null)
  const [org, setOrg] = useState('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<Error>()
  const navigate = useNavigate()
  const location = useLocation()
  useEffect(() => {
    const controller = new AbortController()
    api<Identity>('/me', { signal: controller.signal }).then(result => { if (!controller.signal.aborted) { setIdentity(result.data); setOrg(result.data.memberships[0]?.organization.id || '') } }).catch(reason => { if (!controller.signal.aborted && reason.status !== 401) setError(reason) }).finally(() => { if (!controller.signal.aborted) setLoading(false) })
    const expired = () => { setIdentity(null); setOrg(''); resetCsrf() }
    window.addEventListener('supportflow:expired', expired)
    return () => { controller.abort(); window.removeEventListener('supportflow:expired', expired) }
  }, [])
  function login(data: Identity) { setIdentity(data); setOrg(data.memberships[0]?.organization.id || ''); navigate('/app', { replace: true }) }
  function switchOrg(id: string) { setOrg(id); navigate('/app') }
  async function logout() {
    try { await api('/auth/logout', { method: 'DELETE' }); setIdentity(null); setOrg(''); resetCsrf(); navigate('/login') }
    catch (reason) { setError(reason as Error) }
  }
  if (loading) return <Loading />
  if (!identity) return <><ErrorNotice error={error} /><Login onLogin={login} /></>
  const membership = identity.memberships.find(member => member.organization.id === org)
  if (!membership) return <><Empty title="No active workspace">Ask an organization admin to activate your membership.</Empty><button onClick={logout}>Sign out</button></>
  if (!location.pathname.startsWith('/app')) return <Navigate to="/app" replace />
  return <><ErrorNotice error={error} /><Routes><Route path="/app/*" element={<Workspace key={`${identity.user.id}:${org}:${membership.role}`} identity={identity} membership={membership} onSwitch={switchOrg} logout={logout} />} /></Routes></>
}
export default function App() { return <BrowserRouter><Application /></BrowserRouter> }
