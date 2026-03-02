'use client';

import { useEffect } from 'react';
import { useStore } from '@/lib/store';
import {
  staffService,
  clientService,
  showService,
  bookingService,
  availabilityService,
} from '@/lib/firebase/service';

/** Subscribe to all main collections. Call once in root layout. */
export function useFirestoreSubscriptions() {
  const {
    setStaff, setClients, setShows, setBookings, setAvailability,
  } = useStore();

  useEffect(() => {
    const unsubs = [
      staffService.subscribe(setStaff),
      clientService.subscribe(setClients),
      showService.subscribe(setShows),
      bookingService.subscribe(setBookings),
      availabilityService.subscribe(setAvailability),
    ];
    return () => unsubs.forEach((u) => u());
  }, [setStaff, setClients, setShows, setBookings, setAvailability]);
}
