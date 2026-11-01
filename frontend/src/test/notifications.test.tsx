import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { Application } from '../App'
import { api } from '../api/client'
vi.mock('../api/client', async () => { const original = await vi.importActual('../api/client'); return { ...original, api: vi.fn() } })
it('refreshes the navigation unread count after marking a notification read', async () => {
  let read = false
  vi.mocked(api).mockImplementation(async (path, options) => {
    if (path === '/me') return { data: { user: { id: 'u1', name: 'Agent', email: 'agent@example.com' }, memberships: [{ id: 'm1', role: 'agent', organization: { id: 'o1', name: 'Support team', slug: 'support' } }] } } as never
    if (options?.method === 'PATCH') { read = true; return { data: {} } as never }
    return { data: [{ id: 'n1', kind: 'assignment', message: 'ACME-001 assigned', read_at: read ? new Date().toISOString() : null, created_at: new Date().toISOString(), ticket_id: 't1' }], meta: { page: 1, per_page: 20, total_pages: 1, total_count: 1 }, unread_count: read ? 0 : 1 } as never
  })
  render(<MemoryRouter initialEntries={['/app/notifications']}><Application /></MemoryRouter>)
  expect(await screen.findByRole('link', { name: 'Notifications, 1 unread' })).toBeInTheDocument()
  await userEvent.click(await screen.findByRole('button', { name: 'Mark read' }))
  expect(await screen.findByText('0 unread updates in this workspace.')).toBeInTheDocument()
  expect(screen.queryByRole('link', { name: 'Notifications, 1 unread' })).not.toBeInTheDocument()
})
