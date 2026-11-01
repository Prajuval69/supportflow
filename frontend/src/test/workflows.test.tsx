import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { api, ApiError } from '../api/client'
import { WorkspaceContext } from '../context'
import { Login } from '../pages/Login'
import { Tickets } from '../pages/Tickets'
import { NewTicket } from '../pages/NewTicket'
import { TicketDetail } from '../pages/TicketDetail'
import { AppShell } from '../components/AppShell'
import { Application } from '../App'
import type { Identity, Membership, Ticket } from '../types'
vi.mock('../api/client', async () => { const original = await vi.importActual('../api/client'); return { ...original, api: vi.fn() } })
const mocked = vi.mocked(api)
const membership: Membership = { id: 'm1', role: 'customer', organization: { id: 'org1', name: 'Acme Support', slug: 'acme' } }
const second: Membership = { id: 'm2', role: 'customer', organization: { id: 'org2', name: 'Orbit Labs', slug: 'orbit' } }
const identity: Identity = { user: { id: 'u1', name: 'Customer', email: 'customer@example.com' }, memberships: [membership, second] }
const ticket: Ticket = { id: 't1', ticket_number: 'ACME-0001', title: 'Account access', description: 'Help me', status: 'open', priority: 'high', created_by: identity.user, assignee: null, category: null, created_at: new Date().toISOString(), updated_at: new Date().toISOString(), first_response_due_at: new Date().toISOString(), resolution_due_at: new Date().toISOString(), first_response_at: null, overdue: false }
function workspace(children: React.ReactNode, role = membership.role, path = '/app/tickets') { return render(<MemoryRouter initialEntries={[path]}><WorkspaceContext.Provider value={{ identity, membership: { ...membership, role }, refreshNotifications: vi.fn() }}>{children}</WorkspaceContext.Provider></MemoryRouter>) }
beforeEach(() => { mocked.mockReset() })

it('validates required login fields and shows generic 401 error', async () => {
  mocked.mockRejectedValue(new ApiError(401, 'Email or password is incorrect'))
  render(<Login onLogin={vi.fn()} />)
  expect(screen.getByLabelText('Email address')).toBeRequired()
  expect(screen.getByLabelText('Password')).toBeRequired()
  await userEvent.type(screen.getByLabelText('Email address'), 'customer@example.com')
  await userEvent.type(screen.getByLabelText('Password'), 'wrongpassword')
  await userEvent.click(screen.getByRole('button', { name: 'Sign in' }))
  expect(await screen.findByRole('alert')).toHaveTextContent('Email or password is incorrect')
})

it('sends filters and pagination as query parameters and displays empty state', async () => {
  mocked.mockImplementation(async (path) => path.startsWith('/tickets') ? { data: [], meta: { page: path.includes('page=2') ? 2 : 1, total_pages: 2, total_count: 12, per_page: 10 } } as never : { data: [] } as never)
  workspace(<Tickets />)
  expect(await screen.findByText('No tickets found')).toBeInTheDocument()
  await userEvent.selectOptions(screen.getByLabelText('Priority'), 'urgent')
  await waitFor(() => expect(mocked).toHaveBeenCalledWith(expect.stringContaining('priority=urgent'), expect.objectContaining({ org: 'org1' })))
  await userEvent.click(screen.getByRole('button', { name: 'Next' }))
  await waitFor(() => expect(mocked).toHaveBeenCalledWith(expect.stringContaining('page=2'), expect.anything()))
})

it('renders list loading and failure states', async () => {
  let reject: (error: Error) => void = () => { throw new Error('Promise not initialized') }
  mocked.mockImplementation((path) => path.startsWith('/tickets') ? new Promise((_resolve, rejectPromise) => { reject = rejectPromise }) : Promise.resolve({ data: [] } as never))
  workspace(<Tickets />)
  expect(screen.getByRole('status', { name: 'Loading' })).toBeInTheDocument()
  reject(new Error('Database unavailable'))
  expect(await screen.findByRole('alert')).toHaveTextContent('Database unavailable')
})

it('does not expose internal composer or staff controls to a customer', async () => {
  mocked.mockImplementation(async path => ({ data: path === '/tickets/t1' ? ticket : [] }) as never)
  workspace(<Routes><Route path="/app/tickets/:id" element={<TicketDetail />} /></Routes>, 'customer', '/app/tickets/t1')
  expect(await screen.findByRole('heading', { name: 'Account access' })).toBeInTheDocument()
  expect(screen.queryByRole('button', { name: 'Internal note' })).not.toBeInTheDocument()
  expect(screen.queryByRole('button', { name: 'Save changes' })).not.toBeInTheDocument()
  expect(mocked).not.toHaveBeenCalledWith('/memberships', expect.anything())
})

it('shows ticket creation validation errors and then navigates on success', async () => {
  let submissions = 0
  mocked.mockImplementation(async (path, options) => {
    if (options?.method === 'POST') { if (submissions++ === 0) throw new ApiError(422, 'Please check the fields', { title: ['is invalid'] }); return { data: ticket } as never }
    return { data: [] } as never
  })
  workspace(<Routes><Route path="/app/tickets/new" element={<NewTicket />} /><Route path="/app/tickets/t1" element={<p>Created detail page</p>} /></Routes>, 'customer', '/app/tickets/new')
  await userEvent.type(await screen.findByLabelText('Title'), 'Account access')
  await userEvent.type(screen.getByLabelText('Description'), 'Help me')
  await userEvent.click(screen.getByRole('button', { name: 'Create ticket' }))
  expect(await screen.findByRole('alert')).toHaveTextContent('Title: is invalid')
  await userEvent.click(screen.getByRole('button', { name: 'Create ticket' }))
  expect(await screen.findByText('Created detail page')).toBeInTheDocument()
})

it('supports keyboard mobile navigation and hides admin links for customers', async () => {
  render(<MemoryRouter><AppShell identity={identity} membership={membership} onSwitch={vi.fn()} logout={vi.fn()} unread={0}><p>Content</p></AppShell></MemoryRouter>)
  const menu = screen.getByRole('button', { name: 'Open navigation' })
  await userEvent.click(menu)
  expect(menu).toHaveAttribute('aria-expanded', 'true')
  await userEvent.keyboard('{Escape}')
  expect(menu).toHaveAttribute('aria-expanded', 'false')
  expect(menu).toHaveFocus()
  expect(screen.queryByRole('link', { name: 'People' })).not.toBeInTheDocument()
})

it('clears organization data immediately and ignores a late response after switching', async () => {
  let resolveOld: ((data: never) => void) | undefined
  const summary = { total: 0, open: 0, in_progress: 0, overdue: 0, resolved_last_30_days: 0, by_priority: {}, by_status: {}, recent_tickets: [] }
  mocked.mockImplementation((path, options) => {
    if (path === '/me') return Promise.resolve({ data: identity } as never)
    if (options?.org === 'org1') return new Promise(resolve => { resolveOld = resolve })
    return Promise.resolve({ data: summary } as never)
  })
  render(<MemoryRouter initialEntries={['/app']}><Application /></MemoryRouter>)
  await userEvent.selectOptions(await screen.findByLabelText('Active organization'), 'org2')
  expect(await screen.findByText('Orbit Labs · A personal view of your conversations.')).toBeInTheDocument()
  resolveOld?.({ data: { ...summary, recent_tickets: [{ ...ticket, title: 'Stale confidential title' }] } } as never)
  await waitFor(() => expect(screen.queryByText('Stale confidential title')).not.toBeInTheDocument())
})
