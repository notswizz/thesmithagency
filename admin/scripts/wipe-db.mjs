import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs, deleteDoc, doc, writeBatch } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: 'AIzaSyC1I_hYoiuc-IEMNwaSss41CD7jnaEpy7Q',
  authDomain: 'the-smith-agency.firebaseapp.com',
  projectId: 'the-smith-agency',
  storageBucket: 'the-smith-agency.firebasestorage.app',
  messagingSenderId: '1048512215721',
  appId: '1:1048512215721:web:c092a7c008d61c4c7d47b8',
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

const COLLECTIONS = [
  'staff',
  'clients',
  'shows',
  'bookings',
  'availability',
  'contacts',
  'showrooms',
  'boardPosts',
  'boardReplies',
];

async function deleteCollection(name) {
  const snap = await getDocs(collection(db, name));
  if (snap.empty) {
    console.log(`  ${name}: empty`);
    return 0;
  }

  // Firestore batches support up to 500 ops
  let deleted = 0;
  let batch = writeBatch(db);
  let count = 0;

  for (const d of snap.docs) {
    batch.delete(doc(db, name, d.id));
    count++;
    deleted++;

    if (count >= 400) {
      await batch.commit();
      batch = writeBatch(db);
      count = 0;
    }
  }

  if (count > 0) await batch.commit();
  console.log(`  ${name}: deleted ${deleted} docs`);
  return deleted;
}

async function main() {
  console.log('\n⚠️  Wiping all Firestore collections for: the-smith-agency\n');

  let total = 0;
  for (const name of COLLECTIONS) {
    total += await deleteCollection(name);
  }

  console.log(`\nDone. Deleted ${total} documents total.\n`);
  process.exit(0);
}

main();
