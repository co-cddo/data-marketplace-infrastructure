import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./features",
  testMatch: "*.js",
  retries: 0,
  use: {
    headless: true,
    baseURL: process.env.BASE_URL || "http://localhost",
  },
});
