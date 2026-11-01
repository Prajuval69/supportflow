import { test, expect } from '@playwright/test'
test('real SLA notifications can be read and unread count updates', async ({ page }) => {
  await page.goto('/login')
  await page.getByLabel('Email address').fill('admin@acme.example')
  await page
    .getByLabel('Password', { exact: true })
    .fill(process.env.DEMO_PASSWORD || 'DemoPass!12345')
  await page.getByRole('button', { name: 'Sign in', exact: true }).click()
  await expect(page.getByRole('heading', { name: 'A clear view of your support.' })).toBeVisible()
  const org = (await (await page.request.get('/api/v1/me')).json()).data.memberships[0].organization
    .id
  const baseline = await (
    await page.request.get('/api/v1/notifications', { headers: { 'X-Organization-ID': org } })
  ).json()
  await page.goto('/app/tickets/new')
  await page.getByLabel('Title', { exact: true }).fill(`Notification proof ${Date.now()}`)
  await page.getByLabel('Description').fill('Real assignment notification verification.')
  await page.getByRole('button', { name: 'Create ticket' }).click()
  await expect(page.getByRole('heading', { name: /Notification proof/ })).toBeVisible()
  await page.getByLabel('Assignee', { exact: true }).selectOption({ label: 'Acme Admin' })
  const saved = page.waitForResponse(
    (response) =>
      response.url().includes('/api/v1/tickets/') &&
      response.request().method() === 'PATCH' &&
      response.ok(),
  )
  await page.getByRole('button', { name: 'Save changes' }).click()
  await saved
  await expect
    .poll(
      async () =>
        (
          await (
            await page.request.get('/api/v1/notifications', {
              headers: { 'X-Organization-ID': org },
            })
          ).json()
        ).unread_count,
      { timeout: 20000 },
    )
    .toBeGreaterThan(baseline.unread_count)
  const before = await (
    await page.request.get('/api/v1/notifications', { headers: { 'X-Organization-ID': org } })
  ).json()
  await page.goto('/app/notifications')
  const first = page.getByRole('button', { name: 'Mark read', exact: true }).first()
  await expect(first).toBeVisible()
  await first.click()
  await expect(
    page.getByText(`${before.unread_count - 1} unread updates in this workspace.`, { exact: true }),
  ).toBeVisible()
  await expect(
    page.getByRole('link', { name: `Notifications, ${before.unread_count - 1} unread` }),
  ).toBeVisible()
})
