import { test, expect, type Page } from '@playwright/test'
import { mkdir } from 'node:fs/promises'
import path from 'node:path'
const directory = path.resolve('../docs/screenshots')
async function login(page: Page, email: string) {
  await page.goto('/login')
  await page.getByLabel('Email address').fill(email)
  await page
    .getByLabel('Password', { exact: true })
    .fill(process.env.DEMO_PASSWORD || 'DemoPass!12345')
  await page.getByRole('button', { name: 'Sign in', exact: true }).click()
  await expect(page.getByRole('heading', { name: 'A clear view of your support.' })).toBeVisible()
}
async function capture(page: Page, name: string) {
  await expect(page.getByRole('status', { name: 'Loading' })).toHaveCount(0)
  await expect(page.getByRole('alert')).toHaveCount(0)
  await expect
    .poll(() => page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth))
    .toBeTruthy()
  await page.screenshot({ path: path.join(directory, `${name}.png`), fullPage: true })
}
for (const size of [
  { name: 'desktop', width: 1280, height: 800 },
  { name: 'mobile', width: 390, height: 844 },
]) {
  test(`${size.name}: real dashboard, inbox, SLA and staff/customer detail evidence`, async ({
    page,
  }) => {
    test.setTimeout(60000)
    await mkdir(directory, { recursive: true })
    await page.setViewportSize(size)
    const errors: string[] = []
    page.on('pageerror', (error) => errors.push(error.message))
    await page.goto('/login')
    await expect(page.getByRole('heading', { name: 'Welcome back' })).toBeVisible()
    await capture(page, `login-${size.name}`)
    await login(page, 'admin@acme.example')
    await expect(page.getByText('What needs your attention')).toBeVisible()
    await capture(page, `dashboard-${size.name}`)
    if (size.name === 'mobile') {
      const open = page.getByRole('button', { name: 'Open navigation' })
      await open.click()
      await expect(page.getByRole('navigation', { name: 'Main navigation' })).toBeVisible()
      await page.keyboard.press('Escape')
      await expect(open).toBeFocused()
      await expect(open).toHaveAttribute('aria-expanded', 'false')
    }
    await page.goto('/app/tickets')
    await expect(page.getByRole('heading', { name: 'Ticket inbox' })).toBeVisible()
    await capture(page, `inbox-${size.name}`)
    const org = (await (await page.request.get('/api/v1/me')).json()).data.memberships[0]
      .organization.id
    const candidates = (
      await (
        await page.request.get('/api/v1/tickets?per_page=100', {
          headers: { 'X-Organization-ID': org },
        })
      ).json()
    ).data
    const ticket = candidates.find(
      (item: { ticket_number: string }) => item.ticket_number === 'ACME-0002',
    )
    expect(ticket).toBeTruthy()
    await page.goto(`/app/tickets/${ticket.id}`)
    await expect(
      page.getByText('Investigating the account configuration.', { exact: true }),
    ).toBeVisible()
    await capture(page, `detail-staff-${size.name}`)
    await page.goto('/app/admin/sla')
    await expect(page.getByRole('heading', { name: 'Service commitments' })).toBeVisible()
    await expect(
      page.getByLabel('First response for normal (minutes)', { exact: true }),
    ).toBeVisible()
    await capture(page, `sla-${size.name}`)
    // On mobile the sidebar is intentionally inert until opened.
    if (size.name === 'mobile') await page.getByRole('button', { name: 'Open navigation' }).click()
    await page.getByRole('button', { name: 'Sign out' }).click()
    await expect(page.getByRole('heading', { name: 'Welcome back' })).toBeVisible()
    await login(page, 'customer2@acme.example')
    await page.goto(`/app/tickets/${ticket.id}`)
    await expect(page.getByRole('heading', { name: ticket.title })).toBeVisible()
    await expect(
      page.getByText(
        'Thanks for reporting this. We are investigating and will update you shortly.',
        { exact: true },
      ),
    ).toBeVisible()
    await expect(
      page.getByText('Investigating the account configuration.', { exact: true }),
    ).toHaveCount(0)
    await capture(page, `detail-customer-${size.name}`)
    if (size.name === 'mobile') {
      await page.setViewportSize({ width: 375, height: 812 })
      await expect
        .poll(() => page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth))
        .toBeTruthy()
      await page.goto('/app/tickets')
      await expect(page.getByRole('heading', { name: 'Your tickets', exact: true })).toBeVisible()
      await capture(page, 'inbox-mobile-375')
    }
    expect(errors).toEqual([])
  })
}
