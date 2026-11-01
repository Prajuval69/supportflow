import { useEffect, useRef, useState, type ReactNode } from 'react'
import { Link, NavLink, useLocation } from 'react-router-dom'
import { Bell, Building2, ChevronDown, CircleHelp, Inbox, Layers3, LayoutDashboard, LogOut, Menu, Settings2, Users, X, Tags } from 'lucide-react'
import type { Identity, Membership } from '../types'
import { label } from './ui'
export function AppShell({ identity, membership, onSwitch, logout, unread, children }: { identity: Identity; membership: Membership; onSwitch: (id: string) => void; logout: () => void; unread: number; children: ReactNode }) {
  const [mobile, setMobile] = useState(false)
  const menuButton = useRef<HTMLButtonElement>(null)
  const navRef = useRef<HTMLElement>(null)
  const location = useLocation()
  useEffect(() => { setMobile(false) }, [location.pathname, membership.id])
  useEffect(() => {
    if (!mobile) return
    navRef.current?.querySelector<HTMLAnchorElement>('a')?.focus()
    const listener = (event: KeyboardEvent) => {
      if (event.key === 'Escape') { setMobile(false); menuButton.current?.focus() }
      if (event.key === 'Tab') {
        const nodes = navRef.current?.querySelectorAll<HTMLElement>('a,button')
        if (!nodes?.length) return
        const first = nodes[0], last = nodes[nodes.length - 1]
        if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last.focus() }
        else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first.focus() }
      }
    }
    document.addEventListener('keydown', listener)
    return () => document.removeEventListener('keydown', listener)
  }, [mobile])
  return <div className="app-layout"><a className="skip-link" href="#main-content">Skip to content</a>{mobile && <button className="nav-backdrop" aria-label="Close navigation backdrop" onClick={() => setMobile(false)} />}<aside ref={navRef} id="workspace-navigation" className={`sidebar ${mobile ? 'is-open' : ''}`}><Link className="brand" to="/app"><span className="brand-icon"><Layers3 size={22} /></span>SupportFlow</Link><button className="mobile-close icon-button" aria-label="Close navigation" onClick={() => { setMobile(false); menuButton.current?.focus() }}><X /></button><div className="workspace-label"><span className="workspace-avatar">{membership.organization.name.charAt(0)}</span><div><strong>{membership.organization.name}</strong><span>Support workspace</span></div></div><p className="nav-label">WORKSPACE</p><nav aria-label="Main navigation"><NavLink to="/app" end><LayoutDashboard size={18} /> Overview</NavLink><NavLink to="/app/tickets"><Inbox size={18} /> Tickets</NavLink><NavLink to="/app/notifications"><Bell size={18} /> Notifications{unread > 0 && <span className="nav-count">{unread}</span>}</NavLink>{membership.role === 'admin' && <><p className="nav-label">MANAGE</p><NavLink to="/app/admin/team"><Users size={18} /> People</NavLink><NavLink to="/app/admin/categories"><Tags size={18} /> Categories</NavLink><NavLink to="/app/admin/sla"><Settings2 size={18} /> SLA policies</NavLink></>}</nav><div className="sidebar-bottom"><div className="help-note"><CircleHelp size={19} /><div><strong>A better day for support.</strong><p>Clear ownership. Thoughtful replies.</p></div></div><button className="logout-button" onClick={logout}><LogOut size={17} /> Sign out</button><div className="sidebar-user"><span className="avatar">{identity.user.name.charAt(0)}</span><div><strong>{identity.user.name}</strong><span>{label(membership.role)}</span></div></div></div></aside><div className="main-area"><header className="topbar"><div className="topbar-left"><button className="icon-button mobile-menu" ref={menuButton} aria-label="Open navigation" aria-controls="workspace-navigation" aria-expanded={mobile} onClick={() => setMobile(!mobile)}><Menu size={22} /></button><Building2 size={17} /><label className="org-switcher"><span className="sr-only">Active organization</span><select value={membership.organization.id} onChange={e => onSwitch(e.target.value)}>{identity.memberships.map(member => <option key={member.id} value={member.organization.id}>{member.organization.name}</option>)}</select><ChevronDown size={15} /></label></div><div className="topbar-right"><span className="role-label">{label(membership.role)} workspace</span><Link className="notification-bell" to="/app/notifications" aria-label={`Notifications${unread ? `, ${unread} unread` : ''}`}><Bell size={20} />{unread > 0 && <span>{unread}</span>}</Link><span className="avatar">{identity.user.name.charAt(0)}</span></div></header><main id="main-content" className="page-content">{children}</main><footer className="app-footer"><span>SupportFlow</span><span>More clarity. Better conversations.</span></footer></div></div>
}
