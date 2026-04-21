import fs from 'node:fs/promises';
import path from 'node:path';
import { beforeAll, afterAll, beforeEach, describe, expect, it } from 'vitest';
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc } from 'firebase/firestore';

let testEnv;

describe('Firestore security rules', () => {
  beforeAll(async () => {
    const rulesPath = path.resolve(process.cwd(), '..', 'firestore.rules');
    const rules = await fs.readFile(rulesPath, 'utf8');
    testEnv = await initializeTestEnvironment({
      projectId: 'studentmove-dev',
      firestore: { rules, host: '127.0.0.1', port: 8080 },
    });
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  afterAll(async () => {
    await testEnv.cleanup();
  });

  it('allows user to read and write own preferences', async () => {
    const db = testEnv.authenticatedContext('u1').firestore();
    await assertSucceeds(
      setDoc(doc(db, 'userPreferences/u1'), { savedRoutes: ['Uttara - DSC'] }),
    );
    await assertSucceeds(getDoc(doc(db, 'userPreferences/u1')));
  });

  it('blocks user from writing announcements', async () => {
    const db = testEnv.authenticatedContext('u1').firestore();
    await assertFails(
      setDoc(doc(db, 'announcements/a1'), { title: 'x', body: 'y' }),
    );
  });
});
