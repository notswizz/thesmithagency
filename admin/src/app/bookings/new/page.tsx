'use client';

import { useState, useMemo, useEffect } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { useStore } from '@/lib/store';
import { bookingService, availabilityService } from '@/lib/firebase/service';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input, Select, Textarea } from '@/components/ui/Input';
import { Badge } from '@/components/ui/Badge';
import { useToast } from '@/components/ui/Toast';
import { dateRange, formatDateShort, toDateString } from '@/lib/utils/dates';
import { getAvailableStaff, autoAssign } from '@/lib/utils/booking';
import type { DateNeed, Availability, Booking } from '@/types';

export default function NewBookingPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { toast } = useToast();
  const { clients, shows, staff, bookings } = useStore();

  const [step, setStep] = useState(1);
  const [loading, setLoading] = useState(false);
  const [availabilities, setAvailabilities] = useState<Availability[]>([]);

  // Step 1 form
  const [clientId, setClientId] = useState('');
  const [showId, setShowId] = useState(searchParams.get('showId') || '');
  const [status, setStatus] = useState<Booking['status']>('pending');
  const [paymentStatus, setPaymentStatus] = useState<Booking['paymentStatus']>('unpaid');
  const [notes, setNotes] = useState('');

  // Step 2: dates and staff
  const [datesNeeded, setDatesNeeded] = useState<DateNeed[]>([]);

  const selectedShow = useMemo(() => shows.find((s) => s.id === showId), [shows, showId]);

  const showDates = useMemo(() => {
    if (!selectedShow) return [];
    return dateRange(selectedShow.startDate, selectedShow.endDate);
  }, [selectedShow]);

  useEffect(() => {
    if (showId) {
      availabilityService.getByShow(showId).then(setAvailabilities);
    }
  }, [showId]);

  function addDate(date: string) {
    if (datesNeeded.find((d) => d.date === date)) return;
    setDatesNeeded((prev) => [...prev, { date, staffCount: 1, staffIds: [''] }].sort((a, b) => a.date.localeCompare(b.date)));
  }

  function removeDate(date: string) {
    setDatesNeeded((prev) => prev.filter((d) => d.date !== date));
  }

  function updateStaffCount(date: string, count: number) {
    setDatesNeeded((prev) => prev.map((d) => {
      if (d.date !== date) return d;
      const staffIds = Array.from({ length: count }, (_, i) => d.staffIds[i] || '');
      return { ...d, staffCount: count, staffIds };
    }));
  }

  function assignStaff(date: string, slotIndex: number, staffId: string) {
    setDatesNeeded((prev) => prev.map((d) => {
      if (d.date !== date) return d;
      const staffIds = [...d.staffIds];
      staffIds[slotIndex] = staffId;
      return { ...d, staffIds };
    }));
  }

  function handleAutoAssign() {
    const result = autoAssign(datesNeeded, showId, availabilities, bookings);
    setDatesNeeded(result);
    toast('info', 'Auto-assigned staff');
  }

  function addAllDates() {
    const newDates = showDates
      .filter((d) => !datesNeeded.find((dn) => dn.date === d))
      .map((d) => ({ date: d, staffCount: 1, staffIds: [''] }));
    setDatesNeeded((prev) => [...prev, ...newDates].sort((a, b) => a.date.localeCompare(b.date)));
  }

  async function handleSubmit() {
    setLoading(true);
    try {
      const clientName = clients.find((c) => c.id === clientId)?.name || '';
      const showName = shows.find((s) => s.id === showId)?.name || '';
      await bookingService.create({
        clientId,
        showId,
        title: clientName,
        showName,
        status,
        paymentStatus,
        notes,
        datesNeeded,
      });
      toast('success', 'Booking created');
      router.push('/bookings');
    } catch {
      toast('error', 'Failed to create booking');
    } finally {
      setLoading(false);
    }
  }

  function getStaffName(id: string) {
    return staff.find((s) => s.id === id)?.name || 'Unknown';
  }

  return (
    <div className="max-w-3xl mx-auto space-y-6">
      <h1 className="text-2xl font-semibold text-navy-heading">New Booking</h1>

      {/* Step indicator */}
      <div className="flex items-center gap-4">
        <div className={`flex items-center gap-2 text-sm ${step === 1 ? 'text-pink-dark font-medium' : 'text-navy-secondary/40'}`}>
          <span className={`w-6 h-6 rounded-full flex items-center justify-center text-xs ${step === 1 ? 'bg-pink-dark text-white' : 'bg-border-light'}`}>1</span>
          Details
        </div>
        <div className="flex-1 h-px bg-border-light" />
        <div className={`flex items-center gap-2 text-sm ${step === 2 ? 'text-pink-dark font-medium' : 'text-navy-secondary/40'}`}>
          <span className={`w-6 h-6 rounded-full flex items-center justify-center text-xs ${step === 2 ? 'bg-pink-dark text-white' : 'bg-border-light'}`}>2</span>
          Dates & Staff
        </div>
      </div>

      {step === 1 && (
        <Card>
          <div className="space-y-4">
            <Select
              label="Client"
              value={clientId}
              onChange={(e) => setClientId(e.target.value)}
              options={[
                { value: '', label: 'Select a client…' },
                ...clients.map((c) => ({ value: c.id, label: c.name })),
              ]}
            />
            <Select
              label="Show"
              value={showId}
              onChange={(e) => setShowId(e.target.value)}
              options={[
                { value: '', label: 'Select a show…' },
                ...shows.filter((s) => s.status !== 'inactive' && s.status !== 'cancelled').map((s) => ({ value: s.id, label: `${s.name} (${s.location})` })),
              ]}
            />
            <Select
              label="Status"
              value={status}
              onChange={(e) => setStatus(e.target.value as Booking['status'])}
              options={[
                { value: 'pending', label: 'Pending' },
                { value: 'booked', label: 'Booked' },
              ]}
            />
            <Select
              label="Payment Status"
              value={paymentStatus || 'unpaid'}
              onChange={(e) => setPaymentStatus(e.target.value as Booking['paymentStatus'])}
              options={[
                { value: 'unpaid', label: 'Unpaid' },
                { value: 'deposit_paid', label: 'Deposit Paid' },
                { value: 'paid', label: 'Paid' },
              ]}
            />
            <Textarea label="Notes" value={notes} onChange={(e) => setNotes(e.target.value)} />
            <div className="flex justify-end pt-4">
              <Button onClick={() => setStep(2)} disabled={!clientId || !showId}>Next →</Button>
            </div>
          </div>
        </Card>
      )}

      {step === 2 && (
        <div className="space-y-4">
          <Card>
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-navy-heading">Select Dates</h2>
              <div className="flex gap-2">
                <Button variant="secondary" size="sm" onClick={addAllDates}>Add All Dates</Button>
                {datesNeeded.length > 0 && (
                  <Button variant="secondary" size="sm" onClick={handleAutoAssign}>⚡ Auto-Assign</Button>
                )}
              </div>
            </div>
            <div className="flex flex-wrap gap-2 mb-4">
              {showDates.map((d) => {
                const isSelected = datesNeeded.some((dn) => dn.date === d);
                return (
                  <button
                    key={d}
                    onClick={() => isSelected ? removeDate(d) : addDate(d)}
                    className={`px-3 py-1.5 text-xs rounded-lg transition-colors ${
                      isSelected ? 'bg-pink-dark text-white' : 'bg-cream-dark text-navy-secondary hover:bg-border-light'
                    }`}
                  >
                    {formatDateShort(d)}
                  </button>
                );
              })}
            </div>
          </Card>

          {/* Date-by-date staff assignment */}
          {datesNeeded.map((dn) => {
            const available = getAvailableStaff(dn.date, showId, availabilities, bookings, undefined, dn);
            const availableStaffList = available.map((id) => ({ id, name: getStaffName(id) }));

            return (
              <Card key={dn.date}>
                <div className="flex items-center justify-between mb-3">
                  <div>
                    <span className="font-medium text-navy">{formatDateShort(dn.date)}</span>
                    <span className="text-xs text-navy-secondary/40 ml-2">{availableStaffList.length} available</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <label className="text-xs text-navy-secondary/60">Staff needed:</label>
                    <input
                      type="number"
                      min={1}
                      max={20}
                      value={dn.staffCount}
                      onChange={(e) => updateStaffCount(dn.date, Number(e.target.value))}
                      className="w-16 px-2 py-1 text-sm rounded-lg ring-1 ring-border-light"
                    />
                    <button onClick={() => removeDate(dn.date)} className="text-navy-secondary/40 hover:text-red-500 text-xs">✕</button>
                  </div>
                </div>

                <div className="space-y-2">
                  {Array.from({ length: dn.staffCount }).map((_, i) => (
                    <div key={i} className="flex items-center gap-2">
                      <span className="text-xs text-navy-secondary/40 w-6">{i + 1}.</span>
                      <select
                        value={dn.staffIds[i] || ''}
                        onChange={(e) => assignStaff(dn.date, i, e.target.value)}
                        className="flex-1 px-3 py-1.5 text-sm rounded-lg ring-1 ring-border-light bg-white"
                      >
                        <option value="">Unassigned</option>
                        {dn.staffIds[i] && !availableStaffList.find((s) => s.id === dn.staffIds[i]) && (
                          <option value={dn.staffIds[i]}>{getStaffName(dn.staffIds[i])} (currently assigned)</option>
                        )}
                        {availableStaffList.map((s) => (
                          <option key={s.id} value={s.id}>{s.name}</option>
                        ))}
                      </select>
                      {dn.staffIds[i] && (
                        <Badge variant="emerald">✓</Badge>
                      )}
                    </div>
                  ))}
                </div>
              </Card>
            );
          })}

          <div className="flex justify-between pt-4">
            <Button variant="secondary" onClick={() => setStep(1)}>← Back</Button>
            <Button onClick={handleSubmit} loading={loading}>Create Booking</Button>
          </div>
        </div>
      )}
    </div>
  );
}
