import { When, Then } from '@cucumber/cucumber';
import fs from 'fs';
import path from 'path';

import { page, browser } from './common.steps.js';

When('I navigate to the catalog data page', async () => {
  const catalogUrl = new URL('/catalogdata/getcddodataassets', process.env.BASE_URL).toString();
  await page.goto(catalogUrl);
});

Then('I take a screenshot of the page', async () => {
  const screenshotsDir = path.resolve('screenshots');
  if (!fs.existsSync(screenshotsDir)) {
    fs.mkdirSync(screenshotsDir);
  }
  await page.screenshot({ path: path.join(screenshotsDir, 'catalog_data_page.png'), fullPage: true });
  await browser.close();
});
