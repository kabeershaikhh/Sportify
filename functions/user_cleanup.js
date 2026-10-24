async function deleteQuery(db, query) {
  while (true) {
    const snapshot = await query.limit(100).get();
    if (snapshot.empty) return;
    for (const doc of snapshot.docs) await db.recursiveDelete(doc.ref);
  }
}

async function cleanupUserData(admin, uid) {
  if (typeof uid !== 'string' || !uid || uid.includes('/')) {
    throw new Error('A valid, exact Firebase user UID is required.');
  }
  const db = admin.firestore();
  const field = admin.firestore.FieldValue;
  const [hostedGames, joinedGames, userChats] = await Promise.all([
    db.collection('activities').where('hostId', '==', uid).get(),
    db.collection('activities').where('participantIds', 'array-contains', uid).get(),
    db.collection('chats').where('participantIds', 'array-contains', uid).get(),
  ]);
  const hostedIds = new Set(hostedGames.docs.map((doc) => doc.id));

  // Delete descendants first, so retries can discover unfinished hosted games.
  for (const game of hostedGames.docs) {
    await deleteQuery(db, db.collection('chats').where('activityId', '==', game.id));
    await db.recursiveDelete(db.collection('chats').doc(`activity_${game.id}`));
    await deleteQuery(db, db.collection('game_join_requests').where('activityId', '==', game.id));
    await db.recursiveDelete(game.ref);
  }

  // Includes messages in rooms the user already left. Clear identifying previews
  // before deleting each message so a retry cannot miss a leftover preview.
  const messages = db.collectionGroup('messages').where('senderId', '==', uid);
  while (true) {
    const snapshot = await messages.limit(100).get();
    if (snapshot.empty) break;
    for (const message of snapshot.docs) {
      const room = message.ref.parent.parent;
      if (room) {
        await db.runTransaction(async (transaction) => {
          const chat = await transaction.get(room);
          if (chat.exists) transaction.update(room, { lastMessage: null, lastMessageAt: null });
        });
      }
      await db.recursiveDelete(message.ref);
    }
  }

  for (const room of userChats.docs) {
    if (room.data().type === 'direct' || hostedIds.has(room.data().activityId)) {
      await db.recursiveDelete(room.ref);
      continue;
    }
    await db.runTransaction(async (transaction) => {
      const chat = await transaction.get(room.ref);
      if (!chat.exists) return;
      transaction.update(room.ref,
        'participantIds', field.arrayRemove(uid),
        new admin.firestore.FieldPath('participantNames', uid), field.delete(),
        'lastMessage', null, 'lastMessageAt', null);
    });
  }

  for (const game of joinedGames.docs) {
    if (hostedIds.has(game.id)) continue;
    await db.runTransaction(async (transaction) => {
      const latest = await transaction.get(game.ref);
      if (!latest.exists) return;
      const data = latest.data();
      const participantIds = (data.participantIds || []).filter((id) => id !== uid);
      const update = {
        participantIds,
        status: data.status === 'cancelled' ? 'cancelled'
          : participantIds.length >= data.playersNeeded ? 'full' : 'open',
      };
      if (data.lastApprovedJoinRequestId === `${game.id}_${uid}`) {
        update.lastApprovedJoinRequestId = field.delete();
      }
      transaction.update(game.ref, update);
    });
  }

  for (const [collection, property] of [
    ['connections', 'fromUserId'], ['connections', 'toUserId'],
    ['game_join_requests', 'requesterId'], ['game_join_requests', 'hostId'],
    ['reports', 'reporterId'], ['reports', 'targetId'], ['venues', 'suggestedBy'],
  ]) {
    await deleteQuery(db, db.collection(collection).where(property, '==', uid));
  }

  const bucket = admin.storage().bucket();
  const [exists] = await bucket.exists();
  if (exists) {
    for (const prefix of [`users/${uid}/`, `profile_photos/${uid}/`]) {
      await bucket.deleteFiles({ prefix });
    }
  }
  await db.recursiveDelete(db.collection('users').doc(uid));
}

module.exports = { cleanupUserData };
