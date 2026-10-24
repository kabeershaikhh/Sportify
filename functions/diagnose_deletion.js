// Read-only deployment/index checks; does not read or delete user documents.
const admin = require('firebase-admin');

async function main() {
  const app = admin.initializeApp({
    credential: admin.credential.applicationDefault(), projectId: 'sportify-52862',
  });
  const { access_token: token } = await app.options.credential.getAccessToken();
  for (const [label, url] of [
    ['deleteMyAccount', 'https://cloudfunctions.googleapis.com/v1/projects/sportify-52862/locations/us-central1/functions/deleteMyAccount'],
    ['cleanupDeletedUser', 'https://cloudfunctions.googleapis.com/v1/projects/sportify-52862/locations/us-central1/functions/cleanupDeletedUser'],
    ['messages.senderId', 'https://firestore.googleapis.com/v1/projects/sportify-52862/databases/(default)/collectionGroups/messages/fields/senderId'],
  ]) {
    const response = await fetch(url, {
      headers: { Authorization: `Bearer ${token}` }, signal: AbortSignal.timeout(20000),
    });
    const result = await response.json();
    console.log(JSON.stringify({ check: label, httpStatus: response.status,
      status: result.status, indexes: result.indexConfig?.indexes,
      error: result.error?.message }, null, 2));
  }
  await app.delete();
}

main().catch((error) => { console.error(error.message); process.exitCode = 1; });
