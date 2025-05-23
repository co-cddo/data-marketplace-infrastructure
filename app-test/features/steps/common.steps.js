import { Given } from '@cucumber/cucumber';
import { chromium, expect } from '@playwright/test';

export let browser, context, page;

Given('I am logged in via SSO', async () => {
  browser = await chromium.launch({ headless: true });
  context = await browser.newContext();

  const token = process.env.AUTH_TOKEN;
  const baseURL = process.env.BASE_URL;
  const authCookie = process.env.AUTH_COOKIE;

  if (!token || !baseURL || !authCookie) {
    throw new Error('AUTH_TOKEN or BASE_URL not set');
  }

  // Set auth cookie manually
  await context.addCookies([
    {
      name: 'CO-Datamarketplace',
      value: token,
      domain: new URL(baseURL).hostname,
      path: '/',
      httpOnly: true,
      secure: true,
      sameSite: 'Lax'
    }
  ]);
    await context.addCookies([
    {
      name: '.AspNetCore.Cookies',
      value: authCookie,
      domain: new URL(baseURL).hostname,
      path: '/',
      httpOnly: true,
      secure: true,
      sameSite: 'Lax'
    }
  ]);

  page = await context.newPage();

  await page.goto(new URL('/', baseURL).toString());

  // Wait for app confirmation
  await page.waitForSelector('span.govuk-header__product-name');
  const header = page.locator('span.govuk-header__product-name');
  await expect(header).toContainText('Data Marketplace');
});
