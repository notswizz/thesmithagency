'use client';

import { useState, useEffect, useMemo } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import { useStore } from '@/lib/store';
import { showService, availabilityService } from '@/lib/firebase/service';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { Input, Select, Textarea } from '@/components/ui/Input';
import { useToast } from '@/components/ui/Toast';
import { dateRange, formatDateShort } from '@/lib/utils/dates';
import { totalNeeded, totalAssigned } from '@/lib/utils/booking';
import type { Show, Availability, ShowStatus } from '@/types';

export default function ShowDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const { toast } = useToast();
  const { shows, bookings, staff } = useStore();
  const show = shows.find((s) => s.id === id);

  const [editing, setEditing] = useState(false);
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState<Partial<Show>>({});
  const [availabilities, setAvailabilities] = useState<Availability[]>([]);

  useEffect(() => {
    if (show) setForm(show);
  }, [show]);

  useEffect(() => {
    availabilityService.getByShow(id).then(setAvailabilities);
  }, [id]);

  const showBookings = useMemo(
    () => bookings.filter((b) => b.showId === id && b.status !== 'cancelled'),
    [bookings, id]
  );

  const dates = useMemo(
    () => show ? dateRange(show.startDate, show.endDate) : [],
    [show]
  );

  const { clients } = useStore();

  // Map "staffId:date" → client name for booked staff on this show
  const bookedMap = useMemo(() => {
    const map = new Map<string, string>();
    for (const b of showBookings) {
      const clientName = clients.find((c) => c.id === b.clientId)?.name || 'Unknown client';
      for (const dn of b.datesNeeded) {
        for (const sid of dn.staffIds) {
          const key = `${sid}:${dn.date}`;
          const existing = map.get(key);
          map.set(key, existing ? `${existing}, ${clientName}` : clientName);
        }
      }
    }
    return map;
  }, [showBookings, clients]);

  async function save() {
    setSaving(true);
    try {
      const { id: _, createdAt: _c, updatedAt: _u, ...data } = form as Show;
      await showService.update(id, data);
      toast('success', 'Show updated');
      setEditing(false);
    } catch {
      toast('error', 'Failed to update');
    } finally {
      setSaving(false);
    }
  }

  if (!show) {
    return <div className="text-center py-12 text-navy-secondary/40">Show not found</div>;
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <button onClick={() => router.back()} className="text-sm text-navy-secondary/40 hover:text-navy-secondary mb-1">← Back</button>
          <h1 className="text-2xl font-semibold text-navy-heading">{show.name}</h1>
        </div>
        <div className="flex gap-2">
          {editing ? (
            <>
              <Button variant="secondary" onClick={() => setEditing(false)}>Cancel</Button>
              <Button onClick={save} loading={saving}>Save</Button>
            </>
          ) : (
            <Button variant="secondary" onClick={() => setEditing(true)}>Edit</Button>
          )}
        </div>
      </div>

      {/* Show Details */}
      <Card>
        {editing ? (
          <div className="space-y-4">
            <Input label="Name" value={form.name || ''} onChange={(e) => setForm({ ...form, name: e.target.value })} />
            <div className="grid grid-cols-2 gap-4">
              <Input label="Start Date" type="date" value={form.startDate || ''} onChange={(e) => setForm({ ...form, startDate: e.target.value })} />
              <Input label="End Date" type="date" value={form.endDate || ''} onChange={(e) => setForm({ ...form, endDate: e.target.value })} />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <Input label="Location" value={form.location || ''} onChange={(e) => setForm({ ...form, location: e.target.value })} />
              <Input label="Venue" value={form.venue || ''} onChange={(e) => setForm({ ...form, venue: e.target.value })} />
            </div>
            <Select
              label="Status"
              value={form.status || 'active'}
              onChange={(e) => setForm({ ...form, status: e.target.value as Show['status'] })}
              options={[
                { value: 'active', label: 'Active' },
                { value: 'inactive', label: 'Inactive' },
              ]}
            />
            <Textarea label="Description" value={form.description || ''} onChange={(e) => setForm({ ...form, description: e.target.value })} />
          </div>
        ) : (
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
            <div>
              <div className="text-xs text-navy-secondary/40">Dates</div>
              <div className="text-sm font-medium">{formatDateShort(show.startDate)} – {formatDateShort(show.endDate)}</div>
            </div>
            <div>
              <div className="text-xs text-navy-secondary/40">Location</div>
              <div className="text-sm font-medium">{show.location}</div>
            </div>
            <div>
              <div className="text-xs text-navy-secondary/40">Status</div>
              <Badge status={show.status as ShowStatus}>{show.status}</Badge>
            </div>
            {show.description && (
              <div className="col-span-full">
                <div className="text-xs text-navy-secondary/40">Description</div>
                <div className="text-sm">{show.description}</div>
              </div>
            )}
          </div>
        )}
      </Card>

      {/* Availability Matrix */}
      <Card>
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-navy-heading">Staff Availability</h2>
          <div className="flex items-center gap-3 text-[10px] text-navy-secondary/60">
            <span className="flex items-center gap-1"><span className="w-3 h-3 rounded bg-emerald-100 inline-block" /> Available</span>
            <span className="flex items-center gap-1"><span className="w-3 h-3 rounded bg-blue-100 inline-block" /> Booked</span>
            <span className="flex items-center gap-1"><span className="w-3 h-3 rounded bg-red-100 inline-block" /> Unavailable</span>
          </div>
        </div>
        {availabilities.length === 0 ? (
          <p className="text-sm text-navy-secondary/40">No availability submissions yet</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-xs">
              <thead>
                <tr>
                  <th className="text-left py-2 px-2 font-medium text-navy-secondary/60 sticky left-0 bg-white">Staff</th>
                  {dates.map((d) => (
                    <th key={d} className="py-2 px-1 font-medium text-navy-secondary/60 text-center min-w-[40px]">
                      {formatDateShort(d)}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {availabilities.map((a) => (
                  <tr key={a.id} className="border-t border-border-subtle">
                    <td className="py-2 px-2 font-medium text-navy sticky left-0 bg-white whitespace-nowrap">
                      <Link href={`/staff/${a.staffId}`} className="hover:text-pink-dark">{a.staffName}</Link>
                    </td>
                    {dates.map((d) => {
                      const bookedClient = bookedMap.get(`${a.staffId}:${d}`);
                      const isAvailable = a.availableDates.includes(d);
                      return (
                        <td key={d} className="py-2 px-1 text-center">
                          {bookedClient ? (
                            <span title={`Booked: ${bookedClient}`} className="inline-block w-5 h-5 bg-blue-100 text-blue-600 rounded text-[10px] leading-5 font-bold cursor-help">✓</span>
                          ) : isAvailable ? (
                            <span className="inline-block w-5 h-5 bg-emerald-100 rounded text-[10px] leading-5 text-emerald-600 font-bold">●</span>
                          ) : (
                            <span className="inline-block w-5 h-5 bg-red-50 text-red-300 rounded text-[10px] leading-5">–</span>
                          )}
                        </td>
                      );
                    })}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {/* Bookings for this show */}
      <Card>
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-navy-heading">Bookings ({showBookings.length})</h2>
        </div>
        <div className="space-y-2">
          {showBookings.map((b) => {
            const needed = totalNeeded(b);
            const assigned = totalAssigned(b);
            return (
              <Link
                key={b.id}
                href={`/bookings/${b.id}`}
                className="flex items-center justify-between p-3 rounded-xl hover:bg-cream-dark transition-colors"
              >
                <div className="flex items-center gap-3">
                  <Badge status={b.status}>{b.status}</Badge>
                  <span className="text-sm font-medium text-navy">
                    {useStore.getState().clients.find((c) => c.id === b.clientId)?.name || 'Unknown'}
                  </span>
                </div>
                <div className="text-xs text-navy-secondary/60">{assigned}/{needed} staff</div>
              </Link>
            );
          })}
        </div>
      </Card>
    </div>
  );
}
