import { Given, Then } from "@cucumber/cucumber";
import path from "path";

import {
  page,
  browser,
  baseURL,
  screenshotsDir,
  context,
} from "./common.steps.js";
import { expect } from "@playwright/test";
const listingTitle = `My test listing - ${crypto.randomUUID()}`;

await context.route("**/*", (route) => {
  const headers = {
    ...route.request().headers(),
    "Cache-Control": "no-cache",
    Pragma: "no-cache",
  };
  route.continue({ headers });
});

Given("I navigate to the Add New Listing URL", async () => {
  const url = `${baseURL}publish/dashboard`;

  const response = await page.goto(url);
  if (!response || !response.ok()) {
    throw new Error(`Failed to load ${url}`);
  }
  await page.screenshot({ path: "screenshots/dashboard.png", fullPage: true });
});

Then("I should add new listing", { timeout: 90 * 1000 }, async () => {
  await page.getByRole("link", { name: "Add new listing" }).click();
  await page.getByRole("radio", { name: "Complete a web form" }).check();
  await page.getByRole("button", { name: "Continue" }).click();

  await page.getByRole("button", { name: "Continue" }).click();
  await page.getByRole("radio", { name: "Yes" }).check();
  await page.getByRole("button", { name: "Continue" }).click();

  await page.getByRole("textbox", { name: "Listing title" }).fill(listingTitle);
  await page.getByRole("button", { name: "Continue" }).click();
  await page.getByRole("link", { name: "Description" }).click();

  await page
    .getByRole("textbox", { name: "Description" })
    .fill("Test listing description");
  await page.getByRole("button", { name: "Continue" }).click();
  await page
    .getByRole("textbox", { name: "Your reference (optional)" })
    .fill("ref");
  await page.getByRole("button", { name: "Continue" }).click();
  await page.getByRole("checkbox", { name: "Business, economics and" }).check();
  await page.getByRole("checkbox", { name: "Health and care" }).check();
  await page
    .getByRole("checkbox", { name: "Government and public sector" })
    .check();
  await page.getByRole("button", { name: "Continue" }).click();
  await page.getByRole("textbox", { name: "Keyword" }).fill("keyword1");
  await page.getByRole("button", { name: "Continue" }).click();
  await page.getByRole("textbox", { name: "Name" }).click();
  await page.getByRole("textbox", { name: "Name" }).fill("denislav davidov");
  await page
    .getByRole("textbox", { name: "Email address" })
    .fill("denislav.davidov@digital.cabinet-office.gov.uk");
  await page.getByRole("button", { name: "Continue" }).click();
  await page.getByRole("textbox", { name: "Name" }).fill("Densilav Davidov");
  await page
    .getByRole("textbox", { name: "Email address" })
    .fill("denislav.davidov@digital.cabinet-office.gov.uk");
  await page.getByRole("button", { name: "Continue" }).click();
  await page.getByRole("textbox", { name: "Day" }).fill("1");
  await page.getByRole("textbox", { name: "Month" }).fill("1");
  await page.getByRole("textbox", { name: "Year" }).fill("2025");
  await page.getByRole("button", { name: "Continue" }).click();
  await page.getByRole("radio", { name: "Weekly" }).check();
  await page.getByRole("button", { name: "Continue" }).click();
  await page.getByRole("radio", { name: "Yes – anyone can access it" }).check();
  await page.getByRole("button", { name: "Continue" }).click();
  await page.getByRole("radio", { name: "Open Government Licence" }).check();
  await page.getByRole("button", { name: "Continue" }).click();
  await page.getByRole("radio", { name: "API" }).check();
  await page.getByRole("button", { name: "Continue" }).click();
  await page.getByRole("textbox", { name: "Title" }).fill("sample api");
  await page
    .getByRole("textbox", { name: "Documentation URL" })
    .fill("http://sampleapi.com/v1/sample");
  await page.getByRole("button", { name: "Continue" }).click();
  await page.getByRole("button", { name: "Save and return" }).click();
});

Then("I add new theme", { timeout: 90 * 1000 }, async () => {
  await page.screenshot({
    path: path.join(screenshotsDir, "theme_entry.png"),
    fullPage: true,
  });
  await page.getByRole("link", { name: "Themes" }).click();
  await page.getByRole("checkbox", { name: "Geography" }).check();
  await page.getByRole("button", { name: "Save and return" }).click();
});

Then("I add new keyword", { timeout: 90 * 1000 }, async () => {
  await page.screenshot({
    path: path.join(screenshotsDir, "keyword_entry.png"),
    fullPage: true,
  });
  await page.getByRole("link", { name: "Keywords" }).click();
  await page.getByRole("button", { name: "Add another keyword" }).click();
  await page.getByRole("textbox", { name: "Keywords" }).click();
  await page.getByRole("textbox", { name: "Keywords" }).fill("keyword2");
  await page.getByRole("button", { name: "Save and return" }).click();
});

Then("I publish the listing", { timeout: 90 * 1000 }, async () => {
  await page.getByRole("link", { name: "Review and submit" }).click();
  await page.getByRole("button", { name: "Publish data listing" }).click();

  const listingPublishedHeading = page.getByRole("heading", {
    name: "Listing published",
  });
  await expect(listingPublishedHeading).toBeVisible();
  await expect(listingPublishedHeading).toHaveText("Listing published");
  await page.screenshot({
    path: path.join(screenshotsDir, "publish_success.png"),
    fullPage: true,
  });
  await page.getByRole("link", { name: "View all your listings" }).click();
});

Then("I take a screenshot of the page", { timeout: 90 * 1000 }, async () => {
  await page.screenshot({
    path: path.join(screenshotsDir, "search_page.png"),
    fullPage: true,
  });
  const listingLink = page.getByText(listingTitle);
  await expect(listingLink).toBeVisible();
  await listingLink.click();
  await page.screenshot({
    path: path.join(screenshotsDir, "detail_page.png"),
    fullPage: true,
  });
});
