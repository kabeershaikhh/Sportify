// Targeted repair for a user already removed from Firebase Authentication.
// Default mode only reports affected documents. --apply performs the cleanup.
const admin = require('firebase-admin');
const { cleanupUserData } = require('./user_cleanup');

async function main() {
  const args = process.argv.slice(2);
  const uidIndex = args.indexOf('--uid');
  const uid = uidIndex >= 0 ? args[uidIndex + 1] : null;
  if (!uid || uid.startsWith('--') || uid.includes('/')) {
    throw new Error('Usage: node functions/cleanup_deleted_user.js --uid EXACT_UID [--apply]');
  }
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'sportify-52862',
    storageBucket: 'sportify-52862.firebasestorage.app',
  });
  try {
    await admin.auth().getUser(uid);
    throw new Error('Refusing repair: this UID still has an Authentication account. Use in-app deletion.');
  } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
  }
  const db = admin.firestore();
  const counts = {};
  for (const [collection, field, operator] of [
    ['users', 'uid', '=='], ['activities', 'hostId', '=='],
    ['activities', 'participantIds', 'array-contains'],
    ['connections', 'fromUserId', '=='], ['connections', 'toUserId', '=='],
    ['chats', 'participantIds', 'array-contains'],
    ['game_join_requests', 'requesterId', '=='], ['game_join_requests', 'hostId', '=='],
    ['reports', 'reporterId', '=='], ['reports', 'targetId', '=='], ['venues', 'suggestedBy', '=='],
  ]) {
    const result = await db.collection(collection).where(field, operator, uid).count().get();
    counts[`${collection}.${field}`] = result.data().count;
  }
  console.log(JSON.stringify({ project: 'sportify-52862', uid, affected: counts }, null, 2));
  if (!args.includes('--apply')) {
    console.log('Preview only. Cleanup also removes authored messages, hosted-game chats and UID-scoped files. Rerun with --apply to delete.');
    return;
  }
  await cleanupUserData(admin, uid);
  console.log('Related user data cleanup completed.');
}

main().catch((error) => { console.error(error.message); process.exitCode = 1; });
