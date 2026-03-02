import type { Booking, DateNeed, Availability } from '@/types';

/** Calculate total staff needed across all dates */
export function totalNeeded(booking: Booking): number {
  return booking.datesNeeded.reduce((sum, d) => sum + d.staffCount, 0);
}

/** Calculate total staff assigned across all dates */
export function totalAssigned(booking: Booking): number {
  return booking.datesNeeded.reduce(
    (sum, d) => sum + d.staffIds.filter(Boolean).length,
    0
  );
}

/** Check if booking is fully staffed */
export function isFilled(booking: Booking): boolean {
  return totalAssigned(booking) >= totalNeeded(booking);
}

/** Fill ratio as 0-1 */
export function fillRatio(booking: Booking): number {
  const needed = totalNeeded(booking);
  if (needed === 0) return 1;
  return Math.min(totalAssigned(booking) / needed, 1);
}

/**
 * Get available staff for a specific date in a show.
 * Excludes staff already booked for that date in other bookings for same show,
 * and staff already assigned in the current booking for that date.
 */
export function getAvailableStaff(
  date: string,
  showId: string,
  availabilities: Availability[],
  allBookings: Booking[],
  currentBookingId?: string,
  currentDateNeed?: DateNeed
): string[] {
  // Staff who submitted availability for this show+date
  const availableStaffIds = new Set<string>();
  for (const a of availabilities) {
    if (a.showId === showId && a.availableDates.includes(date)) {
      availableStaffIds.add(a.staffId);
    }
  }

  // Staff already booked for this date in OTHER bookings for same show
  const bookedStaffIds = new Set<string>();
  for (const b of allBookings) {
    if (b.showId !== showId) continue;
    if (b.id === currentBookingId) continue;
    if (b.status === 'cancelled') continue;
    for (const dn of b.datesNeeded) {
      if (dn.date === date) {
        dn.staffIds.filter(Boolean).forEach((id) => bookedStaffIds.add(id));
      }
    }
  }

  // Staff already assigned in current booking for this date
  const currentlyAssigned = new Set<string>();
  if (currentDateNeed) {
    currentDateNeed.staffIds.filter(Boolean).forEach((id) => currentlyAssigned.add(id));
  }

  return Array.from(availableStaffIds).filter(
    (id) => !bookedStaffIds.has(id) && !currentlyAssigned.has(id)
  );
}

/**
 * Auto-assign algorithm: sort dates by fewest available staff first (hardest first),
 * then greedily fill each date's slots.
 */
export function autoAssign(
  datesNeeded: DateNeed[],
  showId: string,
  availabilities: Availability[],
  allBookings: Booking[],
  currentBookingId?: string
): DateNeed[] {
  // Calculate difficulty (fewest available = hardest)
  const datesByDifficulty = [...datesNeeded].sort((a, b) => {
    const aAvail = getAvailableStaff(a.date, showId, availabilities, allBookings, currentBookingId).length;
    const bAvail = getAvailableStaff(b.date, showId, availabilities, allBookings, currentBookingId).length;
    return aAvail - bAvail;
  });

  // Track assignments across dates
  const assignments = new Map<string, string[]>();
  const globalAssigned = new Map<string, Set<string>>(); // date -> set of assigned staff

  for (const dn of datesByDifficulty) {
    const available = getAvailableStaff(
      dn.date, showId, availabilities, allBookings, currentBookingId
    );
    const assigned: string[] = [...dn.staffIds.filter(Boolean)];
    const usedOnDate = globalAssigned.get(dn.date) || new Set<string>();

    for (const staffId of available) {
      if (assigned.length >= dn.staffCount) break;
      if (assigned.includes(staffId)) continue;
      if (usedOnDate.has(staffId)) continue;
      assigned.push(staffId);
      usedOnDate.add(staffId);
    }

    // Pad with empty strings if not enough staff
    while (assigned.length < dn.staffCount) {
      assigned.push('');
    }

    assignments.set(dn.date, assigned);
    globalAssigned.set(dn.date, usedOnDate);
  }

  return datesNeeded.map((dn) => ({
    ...dn,
    staffIds: assignments.get(dn.date) || dn.staffIds,
  }));
}
