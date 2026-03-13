import { Timestamp } from 'firebase/firestore';

// ─── Firebase Models ───────────────────────────────────────────────

export interface Staff {
  id: string;
  name: string;
  email: string;
  phone: string;
  location: string;
  address: string;
  college: string;
  dressSize: string;
  shoeSize: string;
  height?: string;
  instagram: string;
  retailWholesaleExperience: string;
  resumeURL: string;
  photoURL: string;
  payRate: number;
  applicationFormCompleted: boolean;
  applicationFormApproved: boolean;
  skills: string[];
  role: string;
  bankAccountHolderName?: string;
  bankRoutingNumber?: string;
  bankAccountNumber?: string;
  bankAccountType?: string;
  directDepositCompleted?: boolean;
  adminNotes?: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface Client {
  id: string;
  name: string;
  email: string;
  website: string;
  stripeCustomerId?: string;
  adminNotes?: string;
  tcAcceptedAt?: Timestamp;
  tcVersion?: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface Show {
  id: string;
  name: string;
  startDate: string; // YYYY-MM-DD
  endDate: string;   // YYYY-MM-DD
  location: string;
  venue: string;
  description: string;
  season: string;
  type: string;
  market?: string;   // "atlanta" | "dallas" | "other"
  status: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface DateNeed {
  date: string; // YYYY-MM-DD
  staffCount: number;
  staffIds: string[];
}

export interface Booking {
  id: string;
  clientId: string;
  showId: string;
  showName?: string;
  title?: string;
  status: 'pending' | 'booked' | 'completed' | 'cancelled';
  paymentStatus: 'unpaid' | 'deposit_paid' | 'paid';
  contactName?: string;
  contactEmail?: string;
  contactPhone?: string;
  showroomCity?: string;
  showroomLocation?: string;
  notes: string;
  datesNeeded: DateNeed[];
  market?: string;
  dailyRate?: number;          // cents
  totalStaffDays?: number;
  estimatedTotal?: number;     // cents
  depositAmount?: number;      // cents
  balanceDue?: number;         // cents
  finalAmount?: number;        // cents
  cancellationFee?: number;    // cents
  adjustments?: Array<{
    label: string;
    amount: number;            // cents, positive or negative
  }>;
  stripeCustomerId?: string;
  paymentMethod?: 'card' | 'check';
  checkNumber?: string;
  checkAmount?: number;
  checkDate?: string;
  stripePaymentIntentId?: string;
  stripeFinalPaymentId?: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface Availability {
  id: string;
  staffId: string;
  staffName: string;
  showId: string;
  showName: string;
  availableDates: string[];
  createdAt: Timestamp;
}

export interface Contact {
  id: string;
  clientId: string;
  name: string;
  email: string;
  phone: string;
  role: string;
}

export interface Showroom {
  id: string;
  clientId: string;
  city: string;
  buildingNumber: string;
  floorNumber: string;
  boothNumber: string;
}

export interface BoardPost {
  id: string;
  text: string;
  mentions: Mention[];
  createdBy: string;
  completed: boolean;
  createdAt: Timestamp;
}

export interface BoardReply {
  id: string;
  postId: string;
  parentId: string | null;
  text: string;
  mentions: Mention[];
  createdBy: string;
  createdAt: Timestamp;
}

export interface Mention {
  id: string;
  type: string;
  label: string;
}

export interface Admin {
  id: string;
  email: string;
  name: string;
  role: 'owner' | 'manager';
  createdAt: Timestamp;
}

// ─── UI Types ──────────────────────────────────────────────────────

export type BookingStatus = 'pending' | 'booked' | 'completed' | 'cancelled';
export type PaymentStatus = 'unpaid' | 'deposit_paid' | 'paid';
export type ShowStatus = 'active' | 'inactive';

export interface SortConfig {
  key: string;
  direction: 'asc' | 'desc';
}

export interface FilterState {
  search: string;
  [key: string]: string | string[] | boolean | undefined;
}

export interface ChatMessage {
  id: string;
  role: 'user' | 'assistant' | 'system';
  content: string;
  timestamp: Date;
}
