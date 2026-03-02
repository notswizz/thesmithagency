import {
  signInWithEmailAndPassword,
  signOut as firebaseSignOut,
  onAuthStateChanged,
  User,
} from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
import { auth, db } from './config';
import type { Admin } from '@/types';

export async function signIn(email: string, password: string): Promise<Admin> {
  const cred = await signInWithEmailAndPassword(auth, email, password);
  const adminDoc = await getDoc(doc(db, 'admins', cred.user.uid));
  if (!adminDoc.exists()) {
    await firebaseSignOut(auth);
    throw new Error('Not authorized as admin');
  }
  return { id: adminDoc.id, ...adminDoc.data() } as Admin;
}

export async function signOut() {
  await firebaseSignOut(auth);
}

export function onAuthChange(callback: (user: User | null) => void) {
  return onAuthStateChanged(auth, callback);
}

export async function getAdminProfile(uid: string): Promise<Admin | null> {
  const snap = await getDoc(doc(db, 'admins', uid));
  if (!snap.exists()) return null;
  return { id: snap.id, ...snap.data() } as Admin;
}
