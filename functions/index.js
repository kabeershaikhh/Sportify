const admin = require('firebase-admin');
const functions = require('firebase-functions/v1');
const { cleanupUserData } = require('./user_cleanup');

admin.initializeApp({
  storageBucket: process.env.STORAGE_BUCKET || 'sportify-52862.firebasestorage.app',
});

// Keep the login account until data cleanup succeeds, so failures can be retried.
exports.deleteMyAccount = functions.runWith({ timeoutSeconds: 540, memory: '512MB' })
  .https.onCall(async (_data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Sign in before deleting your account.');
    }
    const authenticatedAt = Number(context.auth.token.auth_time || 0);
    if (Date.now() / 1000 - authenticatedAt > 300) {
      throw new functions.https.HttpsError('failed-precondition',
        'requires-recent-login: Sign out and sign in again before deleting your account.');
    }
    const uid = context.auth.uid;
    try {
      await cleanupUserData(admin, uid);
      try {
        await admin.auth().deleteUser(uid);
      } catch (error) {
        if (error.code !== 'auth/user-not-found') throw error;
      }
      return { deleted: true };
    } catch (error) {
      functions.logger.error('Account cleanup failed', { uid, error });
      throw new functions.https.HttpsError('internal',
        'Account cleanup could not finish. Please retry deletion.');
    }
  });

// Auth lifecycle triggers require the first-generation API. Individual Console
// deletions and older app versions also use this retryable, idempotent fallback.
exports.cleanupDeletedUser = functions.runWith({
  timeoutSeconds: 540, memory: '512MB', failurePolicy: true,
}).auth.user().onDelete((user) => cleanupUserData(admin, user.uid));
