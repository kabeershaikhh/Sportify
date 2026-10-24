import { before, after, beforeEach, test } from 'node:test';
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, setDoc, getDoc, updateDoc, collection, query, where, getDocs, Timestamp, runTransaction, setLogLevel } from 'firebase/firestore';
setLogLevel('silent');
let env;
const projectId = 'demo-sportify';
const future = Timestamp.fromMillis(Date.now() + 86400000);
const game = {id:'game', hostId:'host', hostName:'Host', sport:'Cricket', skillLevel:'Beginner', area:'Latifabad',
  dateTime:future, venue:'Public court', playersNeeded:2, participantIds:['host'], status:'open', createdAt:Timestamp.now()};
const profile = uid => ({uid, name:'Player Name', email:'player@example.com', sports:[{sport:'Cricket',skillLevel:'Beginner'}],
  availability:{mon:['evening']}, isProfileComplete:true, createdAt:Timestamp.now()});
const db = uid => env.authenticatedContext(uid).firestore();
async function requestPlace(uid) {
  await env.withSecurityRulesDisabled(async context => {
    const pair = ['host', uid].sort().join('_');
    await setDoc(doc(context.firestore(), `connections/${pair}`), {
      fromUserId: 'host', toUserId: uid, status: 'accepted',
    });
  });
  await assertSucceeds(getDoc(doc(db(uid), `game_join_requests/game_${uid}`)));
  await assertSucceeds(setDoc(doc(db(uid), `game_join_requests/game_${uid}`), {
    activityId: 'game', requesterId: uid, requesterName: uid,
    hostId: 'host', status: 'pending', createdAt: Timestamp.now(),
  }));
}
async function approvePlace(uid, syncChat = false) {
  const store = db('host');
  return runTransaction(store, async tx => {
    const ref = doc(store, 'activities/game');
    const requestRef = doc(store, `game_join_requests/game_${uid}`);
    const chatRef = doc(store, 'chats/activity_game');
    const current = (await tx.get(ref)).data();
    await tx.get(requestRef);
    if (syncChat) await tx.get(chatRef);
    if (current.participantIds.length >= current.playersNeeded) throw new Error('Game is full');
    const participantIds = [...current.participantIds, uid];
    tx.update(requestRef, {status: 'accepted'});
    tx.update(ref, {participantIds,
      status: participantIds.length >= current.playersNeeded ? 'full' : 'open',
      lastApprovedJoinRequestId: `game_${uid}`,
    });
    if (syncChat) tx.update(chatRef, {participantIds});
  });
}
before(async () => { env = await initializeTestEnvironment({projectId, firestore:{host:'127.0.0.1',port:8080,
  rules:readFileSync(new URL('../../firestore.rules', import.meta.url),'utf8')}}); });
after(async () => { if (env) await env.cleanup(); });
beforeEach(async () => { await env.clearFirestore(); await env.withSecurityRulesDisabled(async context => {
  const store = context.firestore(); await setDoc(doc(store,'activities/game'),game);
  await setDoc(doc(store,'users/host'),profile('host'));
  await setDoc(doc(store,'connections/request'),{id:'request',fromUserId:'host',toUserId:'player',status:'pending'});
}); });
test('signed-out users cannot read activities or profiles', async () => {
  const anon = env.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(anon,'activities/game'))); await assertFails(getDoc(doc(anon,'users/host')));
});
test('only owners can edit a profile and completed onboarding cannot be reset', async () => {
  await assertSucceeds(updateDoc(doc(db('host'),'users/host'),{name:'Updated Name'}));
  await assertFails(updateDoc(doc(db('player'),'users/host'),{name:'Impostor'}));
  await assertFails(updateDoc(doc(db('host'),'users/host'),{isProfileComplete:false}));
  await assertSucceeds(getDocs(query(collection(db('player'),'users'),where('isProfileComplete','==',true))));
});

test('host game editing preserves ownership and membership', async () => {
  await requestPlace('player');
  await assertSucceeds(updateDoc(doc(db('host'), 'activities/game'), {
    venue: 'Updated public court', playersNeeded: 4, status: 'open',
    description: 'Bring your racket', venueAddress: 'Main Road',
  }));
  const saved = (await getDoc(doc(db('host'), 'activities/game'))).data();
  assert.deepEqual(saved.participantIds, ['host']);
  assert.equal(saved.hostId, 'host');
  assert.equal((await getDoc(doc(db('player'), 'game_join_requests/game_player'))).data().status, 'pending');
  await assertSucceeds(approvePlace('player'));
  await assertFails(updateDoc(doc(db('player'), 'activities/game'), {venue: 'Unauthorized venue'}));
  await assertFails(updateDoc(doc(db('host'), 'activities/game'), {hostId: 'player'}));
  await assertFails(updateDoc(doc(db('host'), 'activities/game'), {participantIds: ['host', 'third']}));
});

test('host game editing cannot reduce capacity below players or use past dates', async () => {
  await env.withSecurityRulesDisabled(async context => {
    await updateDoc(doc(context.firestore(), 'activities/game'), {
      participantIds: ['host', 'one', 'two'], playersNeeded: 3, status: 'full',
    });
  });
  await assertFails(updateDoc(doc(db('host'), 'activities/game'), {playersNeeded: 2, status: 'full'}));
  await assertFails(updateDoc(doc(db('host'), 'activities/game'), {dateTime: Timestamp.fromMillis(Date.now() - 60000)}));
  await assertSucceeds(updateDoc(doc(db('host'), 'activities/game'), {playersNeeded: 4, status: 'open'}));
  await assertFails(updateDoc(doc(db('host'), 'activities/game'), {playersNeeded: 3, status: 'open'}));
  await assertSucceeds(updateDoc(doc(db('host'), 'activities/game'), {playersNeeded: 3, status: 'full'}));
});

test('host game editing cannot reopen cancelled or past games', async () => {
  await assertSucceeds(updateDoc(doc(db('host'), 'activities/game'), {status: 'cancelled'}));
  await assertFails(updateDoc(doc(db('host'), 'activities/game'), {venue: 'Another court', status: 'open'}));
  await env.withSecurityRulesDisabled(async context => {
    await updateDoc(doc(context.firestore(), 'activities/game'), {
      status: 'open', dateTime: Timestamp.fromMillis(Date.now() - 60000),
    });
  });
  await assertFails(updateDoc(doc(db('host'), 'activities/game'), {dateTime: future}));
});
test('joining enforces capacity and host ownership', async () => {
  await assertFails(updateDoc(doc(db('player'),'activities/game'),{participantIds:['host','player'],status:'full'}));
  await requestPlace('player');
  await assertSucceeds(approvePlace('player'));
  await assertFails(updateDoc(doc(db('third'),'activities/game'),{participantIds:['host','player','third'],status:'full'}));
  await assertFails(updateDoc(doc(db('player'),'activities/game'),{hostId:'player'}));
  await assertSucceeds(updateDoc(doc(db('player'),'activities/game'),{participantIds:['host'],status:'open'}));
});
test('two concurrent joins cannot claim the same last spot', async () => {
  await requestPlace('one');
  await requestPlace('two');
  const attempts = await Promise.allSettled([approvePlace('one'),approvePlace('two')]);
  assert.equal(attempts.filter(result => result.status === 'fulfilled').length,1);
  const saved = await getDoc(doc(db('host'),'activities/game'));
  assert.equal(saved.data().participantIds.length,2);
});
test('only the host can cancel and cancelled games reject joins', async () => {
  await assertFails(updateDoc(doc(db('player'),'activities/game'),{status:'cancelled'}));
  await assertSucceeds(updateDoc(doc(db('host'),'activities/game'),{status:'cancelled'}));
  await assertFails(updateDoc(doc(db('player'),'activities/game'),{participantIds:['host','player'],status:'full'}));
});
test('only the receiver can accept a request', async () => {
  await assertFails(updateDoc(doc(db('host'),'connections/request'),{status:'accepted'}));
  await assertSucceeds(updateDoc(doc(db('player'),'connections/request'),{status:'accepted'}));
});
test('direct chat requires an accepted connection and outsiders cannot read messages', async () => {
  const chat = {id:'direct',type:'direct',connectionId:'request',participantIds:['host','player'],participantNames:{host:'Host',player:'Player'},createdAt:Timestamp.now()};
  await assertFails(setDoc(doc(db('host'),'chats/direct'),chat));
  await updateDoc(doc(db('player'),'connections/request'),{status:'accepted'});
  await assertSucceeds(setDoc(doc(db('host'),'chats/direct'),chat));
  await assertSucceeds(setDoc(doc(db('host'),'chats/direct/messages/one'),{senderId:'host',text:'Hello',sentAt:Timestamp.now()}));
  await assertFails(getDoc(doc(db('third'),'chats/direct/messages/one')));
  await assertFails(setDoc(doc(db('player'),'chats/direct/messages/two'),{senderId:'host',text:'Spoofed',sentAt:Timestamp.now()}));
});
test('activity chat membership follows the live game and leaving revokes message access', async () => {
  await requestPlace('player');
  await approvePlace('player');
  await assertSucceeds(setDoc(doc(db('host'),'chats/activity_game'),{id:'activity_game',type:'activity',activityId:'game',participantIds:['host','player'],participantNames:{},createdAt:Timestamp.now()}));
  await assertSucceeds(setDoc(doc(db('player'),'chats/activity_game/messages/one'),{senderId:'player',text:'Ready',sentAt:Timestamp.now()}));
  await updateDoc(doc(db('player'),'activities/game'),{participantIds:['host'],status:'open'});
  await assertFails(getDoc(doc(db('player'),'chats/activity_game/messages/one')));
});
test('a transactional join also synchronizes activity chat membership', async () => {
  await setDoc(doc(db('host'),'chats/activity_game'),{id:'activity_game',type:'activity',activityId:'game',participantIds:['host'],participantNames:{},createdAt:Timestamp.now()});
  await requestPlace('player');
  await assertSucceeds(approvePlace('player', true));
});
test('venue suggestions stay pending and reports cannot impersonate another user', async () => {
  const venue = {name:'Public court',sports:['Cricket'],status:'pending',suggestedBy:'player'};
  await assertSucceeds(setDoc(doc(db('player'),'venues/suggestion'),venue));
  await assertFails(setDoc(doc(db('player'),'venues/approved'),{...venue,status:'approved'}));
  await assertSucceeds(setDoc(doc(db('player'),'reports/report'),{reporterId:'player',reason:'Issue',status:'pending'}));
  await assertFails(setDoc(doc(db('player'),'reports/spoofed'),{reporterId:'host',reason:'Issue',status:'pending'}));
});
