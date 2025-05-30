import { Given, Then } from "@cucumber/cucumber";
import { expect } from "@playwright/test";

import { page, browser, baseURL, screenshotsDir } from "./common.steps.js";

Given("I navigate to the base URL after login", async () => {
  await page.goto(baseURL);
});

Then('I should see "Sign out" button in the toolbar', async () => {
  const signOutLink = page.getByRole("link", { name: "Sign out" });
  await expect(signOutLink).toBeVisible();
  await page.screenshot({
    path: `${screenshotsDir}/logged_index.png`,
    fullPage: true,
  });
});
