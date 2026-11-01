import { test, expect, type Page } from '@playwright/test'
async function login(page: Page, email: string) {
  await page.goto('/login')
  await page.getByLabel('Email address').fill(email)
  await page
    .getByLabel('Password', { exact: true })
    .fill(process.env.DEMO_PASSWORD || 'DemoPass!12345')
  await page.getByRole('button', { name: 'Sign in', exact: true }).click()
  await expect(page.getByRole('heading', { name: 'A clear view of your support.' })).toBeVisible()
}
test('known foreign ticket returns a safe 404 and customer cannot enter admin screens', async ({
  page,
}) => {
  await login(page, 'admin@acme.example')
  const acme = (await (await page.request.get('/api/v1/me')).json()).data.memberships[0]
    .organization.id
  const ticket = (
    await (
      await page.request.get('/api/v1/tickets', { headers: { 'X-Organization-ID': acme } })
    ).json()
  ).data[0]
  await page.getByRole('button', { name: 'Sign out' }).click()
  await expect(page.getByRole('heading', { name: 'Welcome back' })).toBeVisible()
  await login(page, 'agent1@orbit.example')
  await page.goto(`/app/tickets/${ticket.id}`)
  await expect(page.getByRole('heading', { name: 'Ticket unavailable' })).toBeVisible()
  await expect(page.getByText(ticket.title, { exact: true })).toHaveCount(0)
  const orbit = (await (await page.request.get('/api/v1/me')).json()).data.memberships[0]
    .organization.id
  const denied = await page.request.get(`/api/v1/tickets/${ticket.id}`, {
    headers: { 'X-Organization-ID': orbit },
  })
  expect(denied.status()).toBe(404)
  await page.getByRole('button', { name: 'Sign out' }).click()
  await expect(page.getByRole('heading', { name: 'Welcome back' })).toBeVisible()
  await login(page, 'customer1@acme.example')
  await page.goto('/app/admin/sla')
  await expect(page.getByRole('heading', { name: 'Admin access required' })).toBeVisible()
})

test('dual-member switch remounts the workspace with different permissions', async ({ page }) => {
  await login(page, 'dual@demo.example')
  await expect(page.getByRole('link', { name: 'People', exact: true })).toBeVisible()
  await page.getByLabel('Active organization').selectOption({ label: 'Orbit Labs' })
  await expect(page.getByText('Customer workspace')).toBeVisible()
  await expect(page.getByRole('link', { name: 'People', exact: true })).toHaveCount(0)
  await page.getByRole('link', { name: 'Tickets', exact: true }).click()
  await expect(page.getByRole('heading', { name: 'Your tickets', exact: true })).toBeVisible()
  await expect(page.getByText('No tickets found')).toBeVisible()
})

test('admin changes an SLA target and a new ticket snapshots it; restores original policy', async ({
  page,
}) => {
  await login(page, 'admin@acme.example')
  const org = (await (await page.request.get('/api/v1/me')).json()).data.memberships[0].organization
    .id
  const original = (
    await (
      await page.request.get('/api/v1/sla_policies', { headers: { 'X-Organization-ID': org } })
    ).json()
  ).data.find((policy: { priority: string }) => policy.priority === 'high')
  try {
    await page.getByRole('link', { name: 'SLA policies', exact: true }).click()
    await page.getByLabel('First response for high (minutes)', { exact: true }).fill('7')
    const row = page
      .locator('form')
      .filter({ has: page.getByLabel('First response for high (minutes)', { exact: true }) })
    await row.getByRole('button', { name: 'Save policy' }).click()
    await expect(
      page.getByText('High policy saved. New tickets will use these targets.', { exact: true }),
    ).toBeVisible()
    await page.goto('/app/tickets/new')
    await page.getByLabel('Title', { exact: true }).fill(`SLA snapshot proof ${Date.now()}`)
    await page.getByLabel('Description').fill('New policy verification.')
    await page.getByLabel('Priority', { exact: true }).selectOption('high')
    await page.getByRole('button', { name: 'Create ticket' }).click()
    await expect(page.getByRole('heading', { name: /SLA snapshot proof/ })).toBeVisible()
    const id = page.url().split('/').at(-1)
    const ticket = (
      await (
        await page.request.get(`/api/v1/tickets/${id}`, { headers: { 'X-Organization-ID': org } })
      ).json()
    ).data
    expect(
      Math.round(
        (Date.parse(ticket.first_response_due_at) - Date.parse(ticket.created_at)) / 60000,
      ),
    ).toBe(7)
  } finally {
    const token = (await (await page.request.get('/api/v1/auth/csrf')).json()).data.csrf_token
    const restored = await page.request.patch('/api/v1/sla_policies/high', {
      headers: { 'X-Organization-ID': org, 'X-CSRF-Token': token },
      data: {
        sla_policy: {
          first_response_minutes: original.first_response_minutes,
          resolution_minutes: original.resolution_minutes,
        },
      },
    })
    expect(restored.ok()).toBeTruthy()
  }
})

test('admin creates and deactivates a category and adds a local member with confirmed access changes', async ({
  page,
}) => {
  await login(page, 'admin@orbit.example')
  await page.getByRole('link', { name: 'Categories', exact: true }).click()
  const name = `Browser category ${Date.now()}`
  await page.getByLabel('New category name').fill(name)
  await page.getByRole('button', { name: 'Add category' }).click()
  const categoryRow = page
    .locator('form.category-row')
    .filter({ has: page.locator(`input[value="${name}"]`) })
  await expect(categoryRow).toBeVisible()
  await categoryRow.getByLabel(`Availability for ${name}`).selectOption('false')
  page.once('dialog', (dialog) => dialog.accept())
  await categoryRow.getByRole('button', { name: 'Save', exact: true }).click()
  await expect(page.getByLabel(`Availability for ${name}`)).toHaveValue('false')
  await page.getByRole('link', { name: 'People', exact: true }).click()
  const email = `browser-${Date.now()}@demo.example`
  await page.getByLabel('Email address', { exact: true }).fill(email)
  await page.getByLabel('Name (new account)', { exact: true }).fill('Browser Test Member')
  await page
    .getByLabel('Initial password (new account)', { exact: true })
    .fill('BrowserLocal!12345')
  await page.getByRole('button', { name: 'Add member' }).click()
  await expect(page.getByText(email, { exact: true })).toBeVisible()
})
