import { Given, AfterAll, After, Before } from "@cucumber/cucumber";
import { chromium, expect } from "@playwright/test";
import fs from "fs";
import path from "path";
import dotenv from "dotenv";
dotenv.config();

const token = process.env.TOKEN;
const baseURL = process.env.BASE_URL;
const authCookie = process.env.AUTH_COOKIE;

if (!token || !baseURL || !authCookie) {
  throw new Error("AUTH_TOKEN or BASE_URL not set");
}
const screenshotsDir = path.resolve("screenshots");
if (!fs.existsSync(screenshotsDir)) {
  fs.mkdirSync(screenshotsDir);
}
const browser = await chromium.launch({ headless: true });
const context = await browser.newContext({
  storageState: {
    cookies: [
      {
        name: "CO-Datamarketplace",
        value: token,
        domain: new URL(baseURL).hostname,
        path: "/",
        httpOnly: true,
        secure: true,
        sameSite: "Lax",
      },
      {
        name: ".AspNetCore.Cookies",
        value: authCookie,
        domain: new URL(baseURL).hostname,
        path: "/",
        httpOnly: true,
        secure: true,
        sameSite: "Lax",
      },
    ],
    origins: [],
  },
});
const page = await context.newPage();

AfterAll(async function () {
  if (page) await page.close();
  if (context) await context.close();
  if (browser) await browser.close();
});

export { browser, context, page, screenshotsDir, baseURL };
