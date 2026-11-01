import { useState, type FormEvent } from 'react'
import { ArrowRight, Layers3, ShieldCheck } from 'lucide-react'
import { api } from '../api/client'
import { ErrorNotice, Field } from '../components/ui'
import type { Identity } from '../types'
export function Login({ onLogin }: { onLogin: (identity: Identity) => void }) {
  const [error, setError] = useState<Error>()
  const [busy, setBusy] = useState(false)
  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault(); setError(undefined); setBusy(true)
    const data = new FormData(event.currentTarget)
    try { onLogin((await api<Identity>('/auth/login', { method: 'POST', body: Object.fromEntries(data) })).data) }
    catch (reason) { setError(reason as Error) }
    finally { setBusy(false) }
  }
  return <main className="login-page"><section className="login-story"><a className="brand" href="/login"><span className="brand-icon"><Layers3 /></span>SupportFlow</a><div><p className="eyebrow">A little clarity. A better response.</p><h1>Good support<br />starts here.</h1><p>One workspace for every conversation, every teammate, and every commitment.</p><div className="story-line"><ShieldCheck size={20} /> Your team's work. Your workspace.</div></div><p className="login-footer">Built around the people behind every ticket.</p></section><section className="login-form-panel"><form onSubmit={submit} className="login-form"><p className="eyebrow">YOUR SUPPORT WORKSPACE</p><h2>Welcome back</h2><p className="muted">Sign in to pick up where you left off.</p><ErrorNotice error={error} /><Field label="Email address"><input type="email" name="email" autoComplete="username" placeholder="you@company.com" required /></Field><Field label="Password"><input type="password" name="password" autoComplete="current-password" placeholder="Enter your password" required /></Field><button className="button primary" disabled={busy}>{busy ? 'Signing in…' : 'Sign in'}<ArrowRight size={17} /></button><p className="form-help">Local portfolio demo. Use the demo accounts in the project README.</p></form></section></main>
}
