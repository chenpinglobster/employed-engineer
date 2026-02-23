import { beforeEach, afterEach } from 'vitest';
import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';

/**
 * Auto-cleanup: creates unique temp file per test
 * Import in your tests: import { getTempFile } from './vitest.setup';
 */

let currentTestFile: string | null = null;

beforeEach(() => {
  // Generate unique temp file for this test
  const timestamp = Date.now();
  const random = Math.random().toString(36).slice(2, 8);
  currentTestFile = path.join(os.tmpdir(), `test-${timestamp}-${random}.json`);
});

afterEach(() => {
  // Cleanup temp file after each test
  if (currentTestFile && fs.existsSync(currentTestFile)) {
    try {
      fs.unlinkSync(currentTestFile);
    } catch (err) {
      console.warn(`Failed to cleanup ${currentTestFile}:`, err);
    }
  }
  currentTestFile = null;
});

/**
 * Get the current test's temp file path
 * Usage in tests:
 * 
 * import { getTempFile } from './vitest.setup';
 * const testFile = getTempFile();
 * const manager = new TodoManager(testFile);
 */
export function getTempFile(): string {
  if (!currentTestFile) {
    throw new Error('getTempFile() called outside of test context');
  }
  return currentTestFile;
}
