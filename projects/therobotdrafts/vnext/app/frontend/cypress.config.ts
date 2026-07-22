import { defineConfig } from "cypress";
import createBundler from "@bahmutov/cypress-esbuild-preprocessor";
import { addCucumberPreprocessorPlugin } from "@badeball/cypress-cucumber-preprocessor";
import { createEsbuildPlugin } from "@badeball/cypress-cucumber-preprocessor/esbuild";

export default defineConfig({
  e2e: {
    baseUrl: process.env.CYPRESS_BASE_URL || "http://localhost:3000",
    specPattern: "cypress/e2e/**/*.feature",
    supportFile: "cypress/support/e2e.ts",
    async setupNodeEvents(on, config) {
      await addCucumberPreprocessorPlugin(on, config);
      on(
        "file:preprocessor",
        createBundler({
          plugins: [createEsbuildPlugin(config)],
        })
      );
      return config;
    },
    env: {
      appName: process.env.CYPRESS_APP_NAME || "HoloGraph",
      tagline: process.env.CYPRESS_TAGLINE || "Web-native 3D code graph drafting workspace",
      siteDomain: process.env.CYPRESS_SITE_DOMAIN || "therobotdrafts.com",
      appDomain: process.env.CYPRESS_APP_DOMAIN || "app.therobotdrafts.com",
      apiUrl: process.env.CYPRESS_API_URL || "http://localhost:4000",
      ssoDomain: process.env.CYPRESS_SSO_DOMAIN || "therobotdrafts.com",
      passwordDomain: process.env.CYPRESS_PASSWORD_DOMAIN || "therobotdrafts.com",
    },
  },
});
