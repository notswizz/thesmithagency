'use client';

import { useState, useEffect, useMemo, useCallback } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import { useStore } from '@/lib/store';
import { bookingService, availabilityService } from '@/lib/firebase/service';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { useToast } from '@/components/ui/Toast';
import { formatDateShort } from '@/lib/utils/dates';
import { Modal } from '@/components/ui/Modal';
import { totalNeeded, totalAssigned, fillRatio, getAvailableStaff, autoAssign } from '@/lib/utils/booking';
import type { Availability, DateNeed, Booking } from '@/types';

export default function BookingDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const { toast } = useToast();
  const { bookings, clients, shows, staff } = useStore();

  const booking = bookings.find((b) => b.id === id);
  const client = clients.find((c) => c.id === booking?.clientId);
  const show = shows.find((s) => s.id === booking?.showId);

  const [datesNeeded, setDatesNeeded] = useState<DateNeed[]>([]);
  const [availabilities, setAvailabilities] = useState<Availability[]>([]);
  const [pickerSlot, setPickerSlot] = useState<{ date: string; slotIndex: number } | null>(null);
  const [finalAmount, setFinalAmount] = useState('');
  const [isCharging, setIsCharging] = useState(false);
  const [adjustments, setAdjustments] = useState<Array<{ label: string; amount: number }>>([]);
  const [newAdjLabel, setNewAdjLabel] = useState('');
  const [newAdjAmount, setNewAdjAmount] = useState('');
  const [showChargeConfirm, setShowChargeConfirm] = useState(false);
  const [payMethod, setPayMethod] = useState<'card' | 'check'>('card');
  const [checkNumber, setCheckNumber] = useState('');
  const [checkAmount, setCheckAmount] = useState('');
  const [checkDate, setCheckDate] = useState('');
  const [isRecordingCheck, setIsRecordingCheck] = useState(false);
  const [showCheckConfirm, setShowCheckConfirm] = useState(false);

  useEffect(() => {
    if (booking) {
      setDatesNeeded(booking.datesNeeded.map((d) => ({ ...d, staffIds: [...d.staffIds] })));
    }
  }, [booking]);

  useEffect(() => {
    if (booking?.showId) {
      availabilityService.getByShow(booking.showId).then(setAvailabilities);
    }
  }, [booking?.showId]);

  const saveDates = useCallback(async (updated: DateNeed[]) => {
    setDatesNeeded(updated);
    try {
      const clientName = client?.name || '';
      const showName = show?.name || '';
      await bookingService.update(id, { datesNeeded: updated, title: clientName, showName });
    } catch {
      toast('error', 'Failed to save');
    }
  }, [client, show, id, toast]);

  const assignStaff = useCallback(async (date: string, slotIndex: number, staffId: string) => {
    const updated = datesNeeded.map((d) => {
      if (d.date !== date) return d;
      const staffIds = [...d.staffIds];
      staffIds[slotIndex] = staffId;
      return { ...d, staffIds };
    });
    await saveDates(updated);
  }, [datesNeeded, saveDates]);

  const toggleStaffDate = useCallback(async (staffId: string, date: string) => {
    const dn = datesNeeded.find((d) => d.date === date);
    if (!dn) return;
    const existingIndex = dn.staffIds.indexOf(staffId);
    if (existingIndex >= 0) {
      // Unassign (blue -> green)
      const updated = datesNeeded.map((d) => {
        if (d.date !== date) return d;
        const staffIds = [...d.staffIds];
        staffIds[existingIndex] = '';
        return { ...d, staffIds };
      });
      await saveDates(updated);
    } else {
      // Assign to first open slot (green -> blue)
      const openSlot = dn.staffIds.findIndex((s) => !s);
      if (openSlot < 0) return; // no open slots
      const updated = datesNeeded.map((d) => {
        if (d.date !== date) return d;
        const staffIds = [...d.staffIds];
        staffIds[openSlot] = staffId;
        return { ...d, staffIds };
      });
      await saveDates(updated);
    }
  }, [datesNeeded, saveDates]);

  async function updateStatus(newStatus: Booking['status']) {
    try {
      await bookingService.update(id, { status: newStatus });
      toast('success', `Status updated to ${newStatus}`);
    } catch {
      toast('error', 'Failed to update status');
    }
  }

  async function updatePaymentStatus(newStatus: Booking['paymentStatus']) {
    try {
      await bookingService.update(id, { paymentStatus: newStatus });
      toast('success', `Payment updated to ${newStatus.replace('_', ' ')}`);
    } catch {
      toast('error', 'Failed to update payment status');
    }
  }

  function getStaffName(staffId: string) {
    return staff.find((s) => s.id === staffId)?.name || 'Unknown';
  }

  if (!booking) {
    return <div className="text-center py-12 text-navy-secondary/40">Booking not found</div>;
  }

  const needed = totalNeeded(booking);
  const assigned = totalAssigned(booking);
  const fill = fillRatio(booking);

  const statuses: Booking['status'][] = ['pending', 'booked', 'completed'];
  const paymentStatuses: Booking['paymentStatus'][] = ['unpaid', 'deposit_paid', 'paid'];

  return (
    <div className="space-y-6 max-w-4xl">
      <button onClick={() => router.back()} className="text-sm text-navy-secondary/40 hover:text-navy-secondary">
        ← Back
      </button>

      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-navy-heading">
            {client?.name || 'Unknown Client'}
          </h1>
          <Link href={`/shows/${booking.showId}`} className="text-sm text-pink-dark hover:underline">
            {show?.name || 'Unknown Show'}
          </Link>
        </div>
        <Badge status={booking.paymentStatus as 'unpaid' | 'deposit_paid' | 'paid'}>{(booking.paymentStatus || 'unpaid').replace('_', ' ')}</Badge>
      </div>

      {/* Status + Payment */}
      <div className="flex flex-wrap items-center gap-6">
        <div className="flex items-center gap-2">
          <span className="text-xs font-medium text-navy-secondary/50 uppercase tracking-wide">Status</span>
          <div className="flex rounded-lg ring-1 ring-border-light overflow-hidden">
            {statuses.map((s) => (
              <button
                key={s}
                onClick={() => updateStatus(s)}
                className={`px-3 py-1.5 text-xs font-medium capitalize transition-colors ${
                  booking.status === s
                    ? 'bg-pink-dark text-white'
                    : 'bg-white text-navy-secondary hover:bg-cream-dark'
                }`}
              >
                {s}
              </button>
            ))}
          </div>
        </div>
        <div className="flex items-center gap-2">
          <span className="text-xs font-medium text-navy-secondary/50 uppercase tracking-wide">Payment</span>
          <div className="flex rounded-lg ring-1 ring-border-light overflow-hidden">
            {paymentStatuses.map((s) => (
              <button
                key={s}
                onClick={() => updatePaymentStatus(s)}
                className={`px-3 py-1.5 text-xs font-medium capitalize transition-colors ${
                  (booking.paymentStatus || 'unpaid') === s
                    ? 'bg-pink-dark text-white'
                    : 'bg-white text-navy-secondary hover:bg-cream-dark'
                }`}
              >
                {s.replace('_', ' ')}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Stats */}
      <div className="flex flex-wrap items-center gap-4 text-sm">
        <span className="text-navy-secondary/50">Days Needed <span className="font-semibold text-navy">{needed}</span></span>
        <span className="text-navy-secondary/50">Assigned <span className="font-semibold text-navy">{assigned}</span></span>
        <span className="text-navy-secondary/50">Fill Rate <span className={`font-semibold ${fill < 0.5 ? 'text-red-500' : fill < 1 ? 'text-amber-500' : 'text-emerald-500'}`}>{Math.round(fill * 100)}%</span></span>
      </div>

      {/* Staff Assignments */}
      <div>
        <h2 className="text-sm font-semibold text-navy-heading mb-3">Staff Assignments</h2>
        <div className="rounded-xl ring-1 ring-border-light overflow-hidden">
          {datesNeeded.map((dn, di) => {
            const filledCount = dn.staffIds.filter(Boolean).length;
            const isFull = filledCount >= dn.staffCount;

            return (
              <div key={dn.date} className={di > 0 ? 'border-t border-border-light' : ''}>
                <div className="flex items-center gap-3 px-4 py-2 bg-cream-dark/40">
                  <span className="text-xs font-semibold text-navy uppercase tracking-wide">{formatDateShort(dn.date)}</span>
                  <span className={`ml-auto text-[10px] font-semibold px-1.5 py-0.5 rounded-full ${
                    isFull ? 'bg-emerald-100 text-emerald-700' : 'bg-amber-100 text-amber-700'
                  }`}>
                    {filledCount}/{dn.staffCount}
                  </span>
                </div>
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3">
                  {Array.from({ length: dn.staffCount }).map((_, i) => {
                    const currentStaffId = dn.staffIds[i] || '';
                    return (
                      <button
                        key={i}
                        onClick={() => setPickerSlot({ date: dn.date, slotIndex: i })}
                        className={`flex items-center gap-2.5 px-4 py-2.5 text-left text-sm transition-colors hover:bg-cream-dark/60 border-b border-r border-border-light/50 ${
                          currentStaffId ? 'text-navy' : 'text-navy-secondary/30'
                        }`}
                      >
                        <span className={`w-1.5 h-1.5 rounded-full shrink-0 ${currentStaffId ? 'bg-emerald-400' : 'bg-border-light'}`} />
                        {currentStaffId ? getStaffName(currentStaffId) : 'Unassigned'}
                      </button>
                    );
                  })}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Contact & Showroom */}
      {(booking.contactName || booking.showroomCity) && (
        <div className="flex flex-wrap gap-4">
          {booking.contactName && (
            <Card>
              <h2 className="text-xs font-medium text-navy-secondary/50 uppercase tracking-wide mb-2">Primary Show Contact</h2>
              <p className="text-sm font-medium text-navy">{booking.contactName}</p>
              {booking.contactPhone && <p className="text-sm text-navy-secondary">{booking.contactPhone}</p>}
              {booking.contactEmail && <p className="text-sm text-navy-secondary">{booking.contactEmail}</p>}
            </Card>
          )}
          {booking.showroomCity && (
            <Card>
              <h2 className="text-xs font-medium text-navy-secondary/50 uppercase tracking-wide mb-2">Showroom Location</h2>
              <p className="text-sm font-medium text-navy">{booking.showroomCity}</p>
              {booking.showroomLocation && <p className="text-sm text-navy-secondary">{booking.showroomLocation}</p>}
            </Card>
          )}
        </div>
      )}

      {/* Notes */}
      {booking.notes && (
        <Card>
          <h2 className="text-lg font-semibold text-navy-heading mb-2">Notes</h2>
          <p className="text-sm text-navy-secondary">{booking.notes}</p>
        </Card>
      )}

      {/* Final Charge — Card / Check toggle */}
      {(booking.paymentStatus === 'deposit_paid' && (booking.status === 'booked' || booking.status === 'completed')) && (() => {
        const rate = booking.dailyRate || 0;
        const days = booking.totalStaffDays || 0;
        const subtotal = booking.estimatedTotal || (rate * days);
        const deposit = booking.depositAmount || 10000;
        const adjTotal = adjustments.reduce((sum, a) => sum + a.amount, 0);
        const chargeAmount = subtotal - deposit + adjTotal;
        const chargeDollars = chargeAmount / 100;
        const marketName = booking.market ? booking.market.charAt(0).toUpperCase() + booking.market.slice(1) : 'Other';

        return (
          <Card>
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-navy-heading">Final Charge</h2>
              <div className="flex rounded-lg ring-1 ring-border-light overflow-hidden">
                <button
                  onClick={() => setPayMethod('card')}
                  className={`px-3 py-1.5 text-xs font-medium transition-colors ${
                    payMethod === 'card'
                      ? 'bg-pink-dark text-white'
                      : 'bg-white text-navy-secondary hover:bg-cream-dark'
                  }`}
                >
                  Card
                </button>
                <button
                  onClick={() => setPayMethod('check')}
                  className={`px-3 py-1.5 text-xs font-medium transition-colors ${
                    payMethod === 'check'
                      ? 'bg-pink-dark text-white'
                      : 'bg-white text-navy-secondary hover:bg-cream-dark'
                  }`}
                >
                  Check
                </button>
              </div>
            </div>

            {/* Pricing breakdown (shared) */}
            <div className="space-y-2 text-sm mb-4">
              <div className="flex justify-between">
                <span className="text-navy-secondary">Market Rate</span>
                <span className="text-navy">${(rate / 100).toFixed(2)}/day ({marketName})</span>
              </div>
              <div className="flex justify-between">
                <span className="text-navy-secondary">Staff Days</span>
                <span className="text-navy">{days}</span>
              </div>
              <div className="border-t border-border-light pt-2 flex justify-between font-medium">
                <span className="text-navy">Subtotal</span>
                <span className="text-navy">${(subtotal / 100).toFixed(2)}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-navy-secondary">Deposit Paid</span>
                <span className="text-emerald-600">-${(deposit / 100).toFixed(2)}</span>
              </div>

              {/* Adjustments */}
              {adjustments.map((adj, i) => (
                <div key={i} className="flex justify-between items-center">
                  <span className="text-navy-secondary">{adj.label}</span>
                  <div className="flex items-center gap-2">
                    <span className={adj.amount >= 0 ? 'text-navy' : 'text-emerald-600'}>
                      {adj.amount >= 0 ? '+' : '-'}${(Math.abs(adj.amount) / 100).toFixed(2)}
                    </span>
                    <button
                      onClick={() => setAdjustments(adjustments.filter((_, j) => j !== i))}
                      className="text-red-400 hover:text-red-600 text-xs"
                    >
                      &times;
                    </button>
                  </div>
                </div>
              ))}

              {/* Add adjustment */}
              <div className="flex items-end gap-2 pt-2">
                <div className="flex-1">
                  <input
                    type="text"
                    placeholder="Label (e.g. Early departure)"
                    value={newAdjLabel}
                    onChange={(e) => setNewAdjLabel(e.target.value)}
                    className="w-full px-3 py-1.5 rounded-lg ring-1 ring-border-light text-sm focus:outline-none focus:ring-2 focus:ring-pink-dark"
                  />
                </div>
                <div className="w-28">
                  <div className="relative">
                    <span className="absolute left-2 top-1/2 -translate-y-1/2 text-navy-secondary/40 text-sm">$</span>
                    <input
                      type="number"
                      step="0.01"
                      placeholder="0.00"
                      value={newAdjAmount}
                      onChange={(e) => setNewAdjAmount(e.target.value)}
                      className="w-full pl-6 pr-2 py-1.5 rounded-lg ring-1 ring-border-light text-sm focus:outline-none focus:ring-2 focus:ring-pink-dark"
                    />
                  </div>
                </div>
                <button
                  onClick={() => {
                    const amt = parseFloat(newAdjAmount);
                    if (!newAdjLabel.trim() || isNaN(amt)) return;
                    setAdjustments([...adjustments, { label: newAdjLabel.trim(), amount: Math.round(amt * 100) }]);
                    setNewAdjLabel('');
                    setNewAdjAmount('');
                  }}
                  className="px-3 py-1.5 text-sm font-medium text-pink-dark hover:bg-pink-dark/5 rounded-lg transition-colors"
                >
                  + Add
                </button>
              </div>

              {/* Total */}
              <div className="border-t border-border-light pt-3 flex justify-between text-base font-semibold">
                <span className="text-navy-heading">Amount to Charge</span>
                <span className="text-navy-heading">${chargeDollars.toFixed(2)}</span>
              </div>
            </div>

            {/* Card payment */}
            {payMethod === 'card' && (
              <>
                <Button
                  onClick={() => setShowChargeConfirm(true)}
                  disabled={isCharging || chargeAmount <= 0}
                >
                  {isCharging ? 'Charging...' : `Charge ${client?.name || 'Client'} $${chargeDollars.toFixed(2)}`}
                </Button>

                {booking.stripeFinalPaymentId && (
                  <p className="mt-3 text-xs text-emerald-600">
                    Final payment collected — {booking.stripeFinalPaymentId}
                  </p>
                )}

                <Modal open={showChargeConfirm} onClose={() => setShowChargeConfirm(false)} title="Confirm Charge">
                  <p className="text-sm text-navy-secondary mb-4">
                    Charge <span className="font-semibold text-navy">{client?.name}</span> <span className="font-semibold text-navy">${chargeDollars.toFixed(2)}</span> to their card on file?
                  </p>
                  <div className="flex gap-3 justify-end">
                    <Button onClick={() => setShowChargeConfirm(false)}>Cancel</Button>
                    <Button
                      onClick={async () => {
                        setShowChargeConfirm(false);
                        setIsCharging(true);
                        try {
                          const res = await fetch('/api/stripe/charge-final', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({
                              clientId: booking.clientId,
                              amount: chargeDollars,
                              bookingId: booking.id,
                              adjustments,
                            }),
                          });
                          const data = await res.json();
                          if (!res.ok) throw new Error(data.error || 'Charge failed');
                          toast('success', `Charged $${chargeDollars.toFixed(2)} successfully`);
                          setAdjustments([]);
                        } catch (err) {
                          toast('error', err instanceof Error ? err.message : 'Charge failed');
                        } finally {
                          setIsCharging(false);
                        }
                      }}
                    >
                      Confirm Charge
                    </Button>
                  </div>
                </Modal>
              </>
            )}

            {/* Check payment */}
            {payMethod === 'check' && (
              <>
                <div className="space-y-4">
                  <div>
                    <label className="text-xs font-medium text-navy-secondary/50 uppercase tracking-wide">Check Number</label>
                    <input
                      type="text"
                      value={checkNumber}
                      onChange={(e) => setCheckNumber(e.target.value)}
                      placeholder="e.g. 1234"
                      className="mt-1 w-full px-3 py-2 rounded-lg ring-1 ring-border-light text-sm focus:outline-none focus:ring-2 focus:ring-pink-dark"
                    />
                  </div>
                  <div>
                    <label className="text-xs font-medium text-navy-secondary/50 uppercase tracking-wide">Amount ($)</label>
                    <input
                      type="number"
                      step="0.01"
                      value={checkAmount}
                      onChange={(e) => setCheckAmount(e.target.value)}
                      placeholder="0.00"
                      className="mt-1 w-full px-3 py-2 rounded-lg ring-1 ring-border-light text-sm focus:outline-none focus:ring-2 focus:ring-pink-dark"
                    />
                  </div>
                  <div>
                    <label className="text-xs font-medium text-navy-secondary/50 uppercase tracking-wide">Date</label>
                    <input
                      type="date"
                      value={checkDate}
                      onChange={(e) => setCheckDate(e.target.value)}
                      className="mt-1 w-full px-3 py-2 rounded-lg ring-1 ring-border-light text-sm focus:outline-none focus:ring-2 focus:ring-pink-dark"
                    />
                  </div>
                  <Button
                    onClick={() => setShowCheckConfirm(true)}
                    disabled={isRecordingCheck || !checkNumber.trim() || !checkAmount || !checkDate}
                  >
                    {isRecordingCheck ? 'Recording...' : 'Record Check Payment'}
                  </Button>
                </div>

                <Modal open={showCheckConfirm} onClose={() => setShowCheckConfirm(false)} title="Confirm Check Payment">
                  <p className="text-sm text-navy-secondary mb-4">
                    Record check <span className="font-semibold text-navy">#{checkNumber}</span> for <span className="font-semibold text-navy">${parseFloat(checkAmount || '0').toFixed(2)}</span> from <span className="font-semibold text-navy">{client?.name}</span>?
                  </p>
                  <div className="flex gap-3 justify-end">
                    <Button onClick={() => setShowCheckConfirm(false)}>Cancel</Button>
                    <Button
                      onClick={async () => {
                        setShowCheckConfirm(false);
                        setIsRecordingCheck(true);
                        try {
                          await bookingService.update(id, {
                            paymentStatus: 'paid',
                            paymentMethod: 'check',
                            checkNumber: checkNumber.trim(),
                            checkAmount: Math.round(parseFloat(checkAmount) * 100),
                            checkDate,
                            finalAmount: Math.round(parseFloat(checkAmount) * 100),
                          });
                          toast('success', 'Check payment recorded');
                          setCheckNumber('');
                          setCheckAmount('');
                          setCheckDate('');
                        } catch (err) {
                          toast('error', err instanceof Error ? err.message : 'Failed to record check');
                        } finally {
                          setIsRecordingCheck(false);
                        }
                      }}
                    >
                      Confirm
                    </Button>
                  </div>
                </Modal>
              </>
            )}
          </Card>
        );
      })()}

      {/* Already paid summary */}
      {booking.paymentStatus === 'paid' && booking.finalAmount && (
        <Card>
          <h2 className="text-lg font-semibold text-navy-heading mb-2 flex items-center gap-2">
            <span className="text-emerald-500">&#10003;</span> Payment Complete
          </h2>
          <div className="space-y-2 text-sm">
            {booking.estimatedTotal && (
              <div className="flex justify-between">
                <span className="text-navy-secondary">Estimated Total</span>
                <span className="text-navy">${(booking.estimatedTotal / 100).toFixed(2)}</span>
              </div>
            )}
            <div className="flex justify-between">
              <span className="text-navy-secondary">Deposit</span>
              <span className="text-navy">-${((booking.depositAmount || 10000) / 100).toFixed(2)}</span>
            </div>
            {booking.adjustments?.map((adj, i) => (
              <div key={i} className="flex justify-between">
                <span className="text-navy-secondary">{adj.label}</span>
                <span className={adj.amount >= 0 ? 'text-navy' : 'text-emerald-600'}>
                  {adj.amount >= 0 ? '+' : '-'}${(Math.abs(adj.amount) / 100).toFixed(2)}
                </span>
              </div>
            ))}
            <div className="border-t border-border-light pt-2 flex justify-between font-semibold">
              <span className="text-navy-heading">Final Charged</span>
              <span className="text-emerald-600">${(booking.finalAmount / 100).toFixed(2)}</span>
            </div>
          </div>
          {booking.paymentMethod === 'check' && booking.checkNumber && (
            <p className="mt-3 text-xs text-navy-secondary/50">
              Paid by check #{booking.checkNumber}{booking.checkDate ? ` on ${booking.checkDate}` : ''}
            </p>
          )}
          {booking.stripeFinalPaymentId && (
            <p className="mt-3 text-xs text-navy-secondary/50">{booking.stripeFinalPaymentId}</p>
          )}
        </Card>
      )}

      {/* Staff Picker Modal */}
      {pickerSlot && (() => {
        const pickerDn = datesNeeded.find((d) => d.date === pickerSlot.date);
        const availableIds = pickerDn
          ? getAvailableStaff(pickerSlot.date, booking.showId, availabilities, bookings, booking.id, pickerDn)
          : [];
        const currentStaffId = pickerDn?.staffIds[pickerSlot.slotIndex] || '';
        // Include currently assigned staff (even if not in available list) + all available
        const allPickerIds = currentStaffId && !availableIds.includes(currentStaffId)
          ? [currentStaffId, ...availableIds]
          : availableIds;
        // Build availability lookup per staff
        const staffAvailMap = new Map<string, Set<string>>();
        for (const a of availabilities) {
          if (!staffAvailMap.has(a.staffId)) staffAvailMap.set(a.staffId, new Set());
          a.availableDates.forEach((d) => staffAvailMap.get(a.staffId)!.add(d));
        }
        // Build booked lookups: other bookings (red) and current booking (blue)
        const staffBookedOtherMap = new Map<string, Set<string>>();
        const staffBookedCurrentMap = new Map<string, Set<string>>();
        for (const b of bookings) {
          if (b.showId !== booking.showId || b.status === 'cancelled') continue;
          const targetMap = b.id === booking.id ? staffBookedCurrentMap : staffBookedOtherMap;
          for (const dn of b.datesNeeded) {
            for (const sid of dn.staffIds.filter(Boolean)) {
              if (!targetMap.has(sid)) targetMap.set(sid, new Set());
              targetMap.get(sid)!.add(dn.date);
            }
          }
        }
        const allDates = datesNeeded.map((d) => d.date);

        return (
          <Modal
            open
            onClose={() => setPickerSlot(null)}
            title={`Assign Staff — ${formatDateShort(pickerSlot.date)}`}
            size="lg"
          >
            <div className="flex items-center gap-3 text-[10px] text-navy-secondary/30 -mt-3 mb-3">
              <span className="flex items-center gap-1"><span className="w-1.5 h-1.5 rounded-full bg-emerald-400 inline-block" /> Available</span>
              <span className="flex items-center gap-1"><span className="w-1.5 h-1.5 rounded-full bg-blue-400 inline-block" /> Booked</span>
              <span className="flex items-center gap-1"><span className="w-1.5 h-1.5 rounded-full bg-red-400 inline-block" /> Elsewhere</span>
              <span className="flex items-center gap-1"><span className="w-1.5 h-1.5 rounded-full bg-gray-200 inline-block" /> Unavailable</span>
            </div>

            {/* Unassign option */}
            {currentStaffId && (
              <button
                onClick={() => { assignStaff(pickerSlot.date, pickerSlot.slotIndex, ''); setPickerSlot(null); }}
                className="w-full text-left px-4 py-3 text-sm text-red-500 hover:bg-red-50 rounded-lg mb-2 transition-colors"
              >
                Remove Assignment
              </button>
            )}

            {/* Date column headers */}
            <div className="flex items-center gap-2 px-4 py-2 border-b border-border-light mb-1">
              <span className="flex-1 text-xs font-medium text-navy-secondary/50 uppercase tracking-wide">Staff</span>
              <div className="flex gap-1.5">
                {allDates.map((d) => (
                  <span
                    key={d}
                    className={`w-10 text-center text-[10px] font-medium ${
                      d === pickerSlot.date ? 'text-pink-dark' : 'text-navy-secondary/40'
                    }`}
                  >
                    {formatDateShort(d).replace(/\s/g, '\n').split('\n')[1] || formatDateShort(d)}
                  </span>
                ))}
              </div>
            </div>

            {/* Staff list */}
            <div className="max-h-80 overflow-y-auto -mx-6 px-6">
              {allPickerIds.length === 0 && (
                <div className="text-center py-8 text-sm text-navy-secondary/40">No available staff for this date</div>
              )}
              {allPickerIds.map((sid) => {
                const staffMember = staff.find((s) => s.id === sid);
                const availDates = staffAvailMap.get(sid) || new Set();
                const isSelected = sid === currentStaffId;
                return (
                  <div
                    key={sid}
                    className={`w-full flex items-center gap-2 px-4 py-3 rounded-lg transition-colors ${
                      isSelected
                        ? 'bg-pink-dark/5 ring-1 ring-pink-dark/20'
                        : 'hover:bg-cream-dark'
                    }`}
                  >
                    <button
                      className="flex-1 min-w-0 text-left"
                      onClick={() => { assignStaff(pickerSlot.date, pickerSlot.slotIndex, sid); setPickerSlot(null); }}
                    >
                      <div className="text-sm font-medium text-navy truncate">
                        {staffMember?.name || 'Unknown'}
                      </div>
                      {isSelected && (
                        <span className="text-[10px] text-pink-dark font-medium uppercase">Currently assigned</span>
                      )}
                    </button>
                    <div className="flex gap-1.5">
                      {allDates.map((d) => {
                        const isAvail = availDates.has(d);
                        const isBookedCurrent = staffBookedCurrentMap.get(sid)?.has(d) || false;
                        const isBookedOther = staffBookedOtherMap.get(sid)?.has(d) || false;
                        const dotColor = isBookedCurrent
                          ? 'bg-blue-400'
                          : isBookedOther
                            ? 'bg-red-400'
                            : isAvail
                              ? 'bg-emerald-400'
                              : 'bg-gray-200';
                        // Clickable if green (assign) or blue (unassign)
                        const clickable = (isAvail && !isBookedOther && !isBookedCurrent) || isBookedCurrent;
                        return (
                          <button
                            key={d}
                            disabled={!clickable}
                            onClick={(e) => { e.stopPropagation(); toggleStaffDate(sid, d); }}
                            className={`w-10 flex justify-center ${clickable ? 'cursor-pointer' : 'cursor-default'}`}
                          >
                            <span
                              className={`w-2.5 h-2.5 rounded-full ${dotColor} ${
                                d === pickerSlot.date ? 'ring-2 ring-offset-1 ring-pink-dark/30' : ''
                              } ${clickable ? 'hover:scale-150 transition-transform' : ''}`}
                            />
                          </button>
                        );
                      })}
                    </div>
                  </div>
                );
              })}
            </div>
          </Modal>
        );
      })()}
    </div>
  );
}
