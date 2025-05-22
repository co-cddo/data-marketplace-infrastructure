import { Given, Then } from '@cucumber/cucumber';
import { chromium, expect } from '@playwright/test';

let browser, page;
Given('I am logged in via SSO', async () => {

  await page.goto(new URL('/', baseURL).toString());

  // Wait for app confirmation
  await page.waitForSelector('span.govuk-header__product-name');
  const header = page.locator('span.govuk-header__product-name');
  await expect(header).toContainText('Data Marketplace');
});

Given('I navigate to the base URL', async () => {
  browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  page = await context.newPage();

  const response = await page.goto(process.env.BASE_URL);
  if (!response || !response.ok()) {
    throw new Error(`Failed to load ${process.env.BASE_URL}`);
  }
});

Then('I should see {string} in the product name header', async (expectedText) => {
  const header = page.locator('span.govuk-header__product-name');
  await expect(header).toContainText(expectedText);
  // await page.screenshot({ path: 'screenshots/base-url.png', fullPage: true });
  await browser.close();
});
