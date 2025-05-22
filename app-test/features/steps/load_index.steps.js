import { Given, Then } from '@cucumber/cucumber';
import { chromium, expect } from '@playwright/test';

let browser, page;
const baseURL= process.env.BASE_URL


Given('I navigate to the base URL', async () => {
  browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  page = await context.newPage();

  const response = await page.goto(baseURL);
  if (!response || !response.ok()) {
    throw new Error(`Failed to load ${baseURL}`);
  }
  await page.waitForSelector('span.govuk-header__product-name');
  const header = page.locator('span.govuk-header__product-name');
  await expect(header).toContainText('Data Marketplace');
});

Then('I should see {string} in the product name header', async (expectedText) => {
  const header = page.locator('span.govuk-header__product-name');
  await expect(header).toContainText(expectedText);
  // await page.screenshot({ path: 'screenshots/base-url.png', fullPage: true });
  await browser.close();
});
