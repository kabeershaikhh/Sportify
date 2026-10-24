const admin = require('firebase-admin');
const functions = require('firebase-functions');

admin.initializeApp();

const db = admin.firestore();

async function deleteQuery(query) {
  const snapshot = await query.get();
  await Promise.all(snapshot.docs.map((doc) => db.recursiveDelete(doc.ref)));
}

exports.cleanupDeletedUser = functions.auth.user().onDelete(async (user) => {
  const uid = user.uid;

  const [hostedGames, joinedGames, sentConnections, receivedConnections,
    userChats] = await Promise.all([
    db.collection('activities').where('hostId', '==', uid).get(),
    db.collection('activities').where('participantIds', 'array-contains', uid).get(),
    db.collection('connections').where('fromUserId', '==', uid).get(),
    db.collection('connections').where('toUserId', '==', uid).get(),
    db.collection('chats').where('participantIds', 'array-contains', uid).get(),
  ]);

  const hostedIds = new Set(hostedGames.docs.map((doc) => doc.id));
  const hostedChatSnapshots = await Promise.all([...hostedIds].map((activityId) =>
    db.collection('chats').where('activityId', '==', activityId).get()));
  const chatsToDelete = new Map();
  for (const snapshot of hostedChatSnapshots) {
    for (const doc of snapshot.docs) chatsToDelete.set(doc.ref.path, doc.ref);
  }

  const chatUpdates = [];
  for (const doc of userChats.docs) {
    const chat = doc.data();
    if (chat.type === 'direct' || hostedIds.has(chat.activityId)) {
      chatsToDelete.set(doc.ref.path, doc.ref);
      continue;
    }
    if (chat.type === 'activity' && chat.activityId) {
      const game = await db.collection('activities').doc(chat.activityId).get();
      if (!game.exists) {
        chatsToDelete.set(doc.ref.path, doc.ref);
      } else {
        const participantIds = (chat.participantIds || []).filter((id) => id !== uid);
        const participantNames = { ...(chat.participantNames || {}) };
        delete participantNames[uid];
        chatUpdates.push(doc.ref.update({ participantIds, participantNames }));
      }
    }
  }

  const gameUpdates = joinedGames.docs
    .filter((doc) => !hostedIds.has(doc.id))
    .map((doc) => {
      const game = doc.data();
      const participantIds = (game.participantIds || []).filter((id) => id !== uid);
      const status = game.status === 'cancelled' ? 'cancelled'
        : participantIds.length >= game.playersNeeded ? 'full' : 'open';
      return doc.ref.update({ participantIds, status });
    });

  const connectionDeletes = [...sentConnections.docs, ...receivedConnections.docs]
    .map((doc) => doc.ref);
  const reportSnapshots = await Promise.all([
    db.collection('reports').where('reporterId', '==', uid).get(),
    db.collection('reports').where('targetId', '==', uid).get(),
  ]);
  const reportRefs = new Map();
  for (const snapshot of reportSnapshots) {
    for (const doc of snapshot.docs) reportRefs.set(doc.ref.path, doc.ref);
  }
  await Promise.all([
    ...[...hostedGames.docs].map((doc) => db.recursiveDelete(doc.ref)),
    ...[...chatsToDelete.values()].map((ref) => db.recursiveDelete(ref)),
    ...connectionDeletes.map((ref) => db.recursiveDelete(ref)),
    ...[...reportRefs.values()].map((ref) => db.recursiveDelete(ref)),
    ...gameUpdates,
    ...chatUpdates,
    deleteQuery(db.collectionGroup('messages').where('senderId', '==', uid)),
    deleteQuery(db.collection('game_join_requests').where('requesterId', '==', uid)),
    deleteQuery(db.collection('game_join_requests').where('hostId', '==', uid)),
    db.recursiveDelete(db.collection('users').doc(uid)),
    // The app currently stores external profile photo URLs, not uploaded files.
    // Clean up UID-scoped objects if uploads are added under these prefixes.
    admin.storage().bucket().deleteFiles({ prefix: `users/${uid}/` }),
    admin.storage().bucket().deleteFiles({ prefix: `profile_photos/${uid}/` }),
  ]);
});
