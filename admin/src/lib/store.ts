import { create } from 'zustand';
import type { Staff, Client, Show, Booking, Availability } from '@/types';

interface AppState {
  // Data
  staff: Staff[];
  clients: Client[];
  shows: Show[];
  bookings: Booking[];
  availability: Availability[];

  // Setters
  setStaff: (staff: Staff[]) => void;
  setClients: (clients: Client[]) => void;
  setShows: (shows: Show[]) => void;
  setBookings: (bookings: Booking[]) => void;
  setAvailability: (availability: Availability[]) => void;

  // UI state
  sidebarOpen: boolean;
  setSidebarOpen: (open: boolean) => void;
  chatOpen: boolean;
  setChatOpen: (open: boolean) => void;
  commandPaletteOpen: boolean;
  setCommandPaletteOpen: (open: boolean) => void;
}

export const useStore = create<AppState>((set) => ({
  staff: [],
  clients: [],
  shows: [],
  bookings: [],
  availability: [],

  setStaff: (staff) => set({ staff }),
  setClients: (clients) => set({ clients }),
  setShows: (shows) => set({ shows }),
  setBookings: (bookings) => set({ bookings }),
  setAvailability: (availability) => set({ availability }),

  sidebarOpen: true,
  setSidebarOpen: (sidebarOpen) => set({ sidebarOpen }),
  chatOpen: false,
  setChatOpen: (chatOpen) => set({ chatOpen }),
  commandPaletteOpen: false,
  setCommandPaletteOpen: (commandPaletteOpen) => set({ commandPaletteOpen }),
}));
