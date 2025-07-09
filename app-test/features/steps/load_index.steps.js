import { context, Given, Then } from "@cucumber/cucumber";
import { chromium, expect } from "@playwright/test";

const baseURL = process.env.BASE_URL;

const browser = await chromium.launch({ headless: true });
const myContext = await browser.newContext();
const page = await myContext.newPage();
Given("I navigate to the base URL", async () => {
  const response = await page.goto(baseURL);
  if (!response || !response.ok()) {
    throw new Error(`Failed to load ${baseURL}`);
  }
  await page.waitForSelector("span.govuk-header__product-name");
  const header = page.locator("span.govuk-header__product-name");
  await expect(header).toContainText("Data Marketplace");
});

Then(
  "I should see {string} in the product name header",
  async (expectedText) => {
    const header = page.locator("span.govuk-header__product-name");
    await expect(header).toContainText(expectedText);
    await page.screenshot({
      path: "./screenshots/base-url.png",
      fullPage: true,
    });
    await page.close();
    await myContext.close();
    await browser.close();
  }
);
