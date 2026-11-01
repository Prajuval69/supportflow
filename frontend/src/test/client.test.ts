import { api, resetCsrf } from '../api/client'
beforeEach(() => resetCsrf())
it('uses cookie credentials, validates CSRF bootstrap and sends the tenant header', async () => {
  const fetchMock = vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce(new Response(JSON.stringify({ data: { csrf_token: 'test-csrf' } }), { status: 200 })).mockResolvedValueOnce(new Response(JSON.stringify({ data: { id: 'ticket' } }), { status: 201 }))
  await api('/tickets', { method: 'POST', org: 'org1', body: { ticket: { title: 'A' } } })
  expect(fetchMock).toHaveBeenNthCalledWith(2, '/api/v1/tickets', expect.objectContaining({ credentials: 'include', headers: expect.objectContaining({ 'X-CSRF-Token': 'test-csrf', 'X-Organization-ID': 'org1' }) }))
})
