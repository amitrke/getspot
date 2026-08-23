/** @type {import('jest').Config} */
module.exports = {
  preset: "ts-jest",
  testEnvironment: "node",
  rootDir: ".",
  testMatch: ["<rootDir>/test/**/*.test.ts"],
  // Firestore emulator round trips are slower than pure unit tests.
  testTimeout: 20000,
  // Run files (not just tests within a file) serially — the shared
  // emulator database is cleared between each test file's suite, and
  // parallel workers would race on that.
  maxWorkers: 1,
};
