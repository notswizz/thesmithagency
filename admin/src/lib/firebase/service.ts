import {
  collection,
  doc,
  addDoc,
  updateDoc,
  deleteDoc,
  getDoc,
  getDocs,
  onSnapshot,
  query,
  orderBy,
  where,
  Timestamp,
  QueryConstraint,
  DocumentData,
  Unsubscribe,
} from 'firebase/firestore';
import { db } from './config';
import type {
  Staff, Client, Show, Booking, Availability,
  Contact, Showroom, BoardPost, BoardReply,
} from '@/types';

// ─── Generic helpers ────────────────────────────────────────────────

function withId<T>(snap: DocumentData & { id: string }): T {
  return { id: snap.id, ...snap.data() } as T;
}

export function subscribe<T>(
  path: string,
  callback: (items: T[]) => void,
  constraints: QueryConstraint[] = []
): Unsubscribe {
  const q = query(collection(db, path), ...constraints);
  return onSnapshot(q, (snap) => {
    callback(snap.docs.map((d) => withId<T>(d)));
  });
}

export async function getAll<T>(
  path: string,
  constraints: QueryConstraint[] = []
): Promise<T[]> {
  const q = query(collection(db, path), ...constraints);
  const snap = await getDocs(q);
  return snap.docs.map((d) => withId<T>(d));
}

export async function getById<T>(path: string, id: string): Promise<T | null> {
  const snap = await getDoc(doc(db, path, id));
  if (!snap.exists()) return null;
  return { id: snap.id, ...snap.data() } as T;
}

export async function create<T extends Record<string, unknown>>(
  path: string,
  data: Omit<T, 'id' | 'createdAt' | 'updatedAt'>
): Promise<string> {
  const ref = await addDoc(collection(db, path), {
    ...data,
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  });
  return ref.id;
}

export async function update(
  path: string,
  id: string,
  data: Record<string, unknown>
): Promise<void> {
  await updateDoc(doc(db, path, id), {
    ...data,
    updatedAt: Timestamp.now(),
  });
}

export async function remove(path: string, id: string): Promise<void> {
  await deleteDoc(doc(db, path, id));
}

// ─── Typed collection helpers ───────────────────────────────────────

export const staffService = {
  subscribe: (cb: (s: Staff[]) => void) =>
    subscribe<Staff>('staff', cb, [orderBy('name')]),
  getAll: () => getAll<Staff>('staff', [orderBy('name')]),
  getById: (id: string) => getById<Staff>('staff', id),
  update: (id: string, data: Partial<Staff>) => update('staff', id, data as Record<string, unknown>),
  delete: (id: string) => remove('staff', id),
};

export const clientService = {
  subscribe: (cb: (c: Client[]) => void) =>
    subscribe<Client>('clients', cb, [orderBy('name')]),
  getAll: () => getAll<Client>('clients', [orderBy('name')]),
  getById: (id: string) => getById<Client>('clients', id),
  create: (data: Omit<Client, 'id' | 'createdAt' | 'updatedAt'>) =>
    create<Client & Record<string, unknown>>('clients', data as Record<string, unknown>),
  update: (id: string, data: Partial<Client>) => update('clients', id, data as Record<string, unknown>),
  delete: (id: string) => remove('clients', id),
};

export const showService = {
  subscribe: (cb: (s: Show[]) => void) =>
    subscribe<Show>('shows', cb, [orderBy('startDate', 'desc')]),
  getAll: () => getAll<Show>('shows', [orderBy('startDate', 'desc')]),
  getById: (id: string) => getById<Show>('shows', id),
  create: (data: Omit<Show, 'id' | 'createdAt' | 'updatedAt'>) =>
    create<Show & Record<string, unknown>>('shows', data as Record<string, unknown>),
  update: (id: string, data: Partial<Show>) => update('shows', id, data as Record<string, unknown>),
  delete: (id: string) => remove('shows', id),
};

export const bookingService = {
  subscribe: (cb: (b: Booking[]) => void) =>
    subscribe<Booking>('bookings', cb, [orderBy('createdAt', 'desc')]),
  getAll: () => getAll<Booking>('bookings', [orderBy('createdAt', 'desc')]),
  getById: (id: string) => getById<Booking>('bookings', id),
  create: (data: Omit<Booking, 'id' | 'createdAt' | 'updatedAt'>) =>
    create<Booking & Record<string, unknown>>('bookings', data as Record<string, unknown>),
  update: (id: string, data: Partial<Booking>) => update('bookings', id, data as Record<string, unknown>),
  delete: (id: string) => remove('bookings', id),
  getByShow: (showId: string) =>
    getAll<Booking>('bookings', [where('showId', '==', showId)]),
  getByClient: (clientId: string) =>
    getAll<Booking>('bookings', [where('clientId', '==', clientId)]),
};

export const availabilityService = {
  subscribe: (cb: (a: Availability[]) => void) =>
    subscribe<Availability>('availability', cb),
  getByShow: (showId: string) =>
    getAll<Availability>('availability', [where('showId', '==', showId)]),
  getByStaff: (staffId: string) =>
    getAll<Availability>('availability', [where('staffId', '==', staffId)]),
};

export const contactService = {
  getByClient: (clientId: string) =>
    getAll<Contact>('contacts', [where('clientId', '==', clientId)]),
  create: (data: Omit<Contact, 'id'>) =>
    create<Contact & Record<string, unknown>>('contacts', data as Record<string, unknown>),
  update: (id: string, data: Partial<Contact>) => update('contacts', id, data as Record<string, unknown>),
  delete: (id: string) => remove('contacts', id),
};

export const showroomService = {
  getByClient: (clientId: string) =>
    getAll<Showroom>('showrooms', [where('clientId', '==', clientId)]),
  create: (data: Omit<Showroom, 'id'>) =>
    create<Showroom & Record<string, unknown>>('showrooms', data as Record<string, unknown>),
  update: (id: string, data: Partial<Showroom>) => update('showrooms', id, data as Record<string, unknown>),
  delete: (id: string) => remove('showrooms', id),
};

export const boardService = {
  subscribePosts: (cb: (p: BoardPost[]) => void) =>
    subscribe<BoardPost>('boardPosts', cb, [orderBy('createdAt', 'desc')]),
  subscribeReplies: (postId: string, cb: (r: BoardReply[]) => void) =>
    subscribe<BoardReply>('boardReplies', cb, [
      where('postId', '==', postId),
      orderBy('createdAt', 'asc'),
    ]),
  createPost: (data: Omit<BoardPost, 'id' | 'createdAt'>) =>
    create<BoardPost & Record<string, unknown>>('boardPosts', data as Record<string, unknown>),
  createReply: (data: Omit<BoardReply, 'id' | 'createdAt'>) =>
    create<BoardReply & Record<string, unknown>>('boardReplies', data as Record<string, unknown>),
  updatePost: (id: string, data: Partial<BoardPost>) =>
    update('boardPosts', id, data as Record<string, unknown>),
};
