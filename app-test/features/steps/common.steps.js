import { Given,AfterAll, After, Before } from '@cucumber/cucumber';
import { chromium, expect } from '@playwright/test';

export let browser, context, page;
  const token = process.env.TOKEN;
  const baseURL = process.env.BASE_URL;
  const authCookie = process.env.AUTH_COOKIE;

Before(async function () {
  if (!browser) {
    browser = await chromium.launch({ headless: true });
  }
  context = await browser.newContext();

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

 
})

After(async function () {
  if (this.page) {
    await this.page.close();
    console.log('Page closed after scenario.');
  }
  if (this.context) {
    await this.context.close();
    console.log('Context closed after scenario.');
  }
});

AfterAll(async function () {
  if (browser) {
    await browser.close();
    console.log('Playwright browser closed after all tests.');
  }
});
