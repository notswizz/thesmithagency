'use client';

import { useState, useEffect, useMemo } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import { useStore } from '@/lib/store';
import { staffService, availabilityService } from '@/lib/firebase/service';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Avatar } from '@/components/ui/Avatar';
import { useToast } from '@/components/ui/Toast';
import { formatDate, formatDateShort } from '@/lib/utils/dates';
import type { Staff, Availability } from '@/types';

export default function StaffDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const { toast } = useToast();
  const { staff, bookings, shows } = useStore();
  const person = staff.find((s) => s.id === id);

  const [editing, setEditing] = useState(false);
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState<Partial<Staff>>({});
  const [availabilities, setAvailabilities] = useState<Availability[]>([]);
  const [activeSection, setActiveSection] = useState<'bookings' | 'availability'>('bookings');

  useEffect(() => {
    if (person) setForm(person);
  }, [person]);

  useEffect(() => {
    availabilityService.getByStaff(id).then(setAvailabilities);
  }, [id]);

  const staffBookings = useMemo(
    () => bookings.filter((b) => b.datesNeeded.some((d) => d.staffIds.includes(id))),
    [bookings, id]
  );

  async function save() {
    setSaving(true);
    try {
      const { id: _, createdAt: _c, updatedAt: _u, ...data } = form as Staff;
      await staffService.update(id, data);
      toast('success', 'Staff updated');
      setEditing(false);
    } catch {
      toast('error', 'Failed to update');
    } finally {
      setSaving(false);
    }
  }

  async function toggleApproval() {
    try {
      await staffService.update(id, { applicationFormApproved: !person?.applicationFormApproved });
      toast('success', person?.applicationFormApproved ? 'Application rejected' : 'Application approved');
    } catch {
      toast('error', 'Failed to update');
    }
  }

  async function handleDelete() {
    if (!confirm(`Delete ${person?.name}? This cannot be undone.`)) return;
    try {
      await staffService.delete(id);
      toast('success', 'Staff member deleted');
      router.push('/staff');
    } catch {
      toast('error', 'Failed to delete');
    }
  }

  if (!person) {
    return <div className="text-center py-12 text-navy-secondary/40">Staff member not found</div>;
  }

  const editFields = [
    { label: 'Email', key: 'email' as const },
    { label: 'Phone', key: 'phone' as const },
    { label: 'Location', key: 'location' as const },
    { label: 'Address', key: 'address' as const },
    { label: 'College', key: 'college' as const },
    { label: 'Dress Size', key: 'dressSize' as const },
    { label: 'Shoe Size', key: 'shoeSize' as const },
    { label: 'Instagram', key: 'instagram' as const },
    { label: 'Role', key: 'role' as const },
    { label: 'Pay Rate', key: 'payRate' as const },
  ];

  return (
    <div className="space-y-6 max-w-4xl">
      <button onClick={() => router.back()} className="text-sm text-navy-secondary/40 hover:text-navy-secondary transition-colors">← Back</button>

      {/* Profile */}
      <Card>
        {/* Top: Photo + Info + Actions */}
        <div className="flex gap-6">
          <div className="flex-shrink-0">
            {person.photoURL ? (
              <img
                src={person.photoURL}
                alt={person.name}
                className="w-24 h-24 rounded-2xl object-cover ring-1 ring-border-light"
                referrerPolicy="no-referrer"
              />
            ) : (
              <Avatar src={person.photoURL} name={person.name} size="lg" status={person.applicationFormApproved ? 'approved' : 'pending'} />
            )}
          </div>

          <div className="flex-1 min-w-0 py-0.5">
            <div className="flex items-start justify-between">
              <div className="space-y-2.5">
                {/* Name + badges */}
                <div>
                  <h1 className="text-2xl font-semibold text-navy-heading tracking-tight">{person.name}</h1>
                  <div className="flex items-center gap-2 mt-1.5">
                    <Badge variant={person.applicationFormApproved ? 'emerald' : 'amber'}>
                      {person.applicationFormApproved ? 'Approved' : 'Pending'}
                    </Badge>
                    {person.location && (
                      <span className="text-xs text-navy-secondary/60 bg-cream-dark px-2.5 py-0.5 rounded-full font-medium">
                        {person.location}
                      </span>
                    )}
                    {person.payRate && (
                      <span className="text-xs font-bold text-pink-dark bg-pink-dark/8 px-2.5 py-0.5 rounded-full">
                        ${person.payRate}/hr
                      </span>
                    )}
                  </div>
                </div>

                {/* Contact icons + details row */}
                <div className="flex items-center gap-1 flex-wrap">
                  {person.email && (
                    <a href={`mailto:${person.email}`} className="p-1.5 rounded-lg text-navy-secondary/30 hover:text-navy-secondary hover:bg-cream-dark transition-all" title={person.email}>
                      <svg className="w-[18px] h-[18px]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M21.75 6.75v10.5a2.25 2.25 0 01-2.25 2.25h-15a2.25 2.25 0 01-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25m19.5 0v.243a2.25 2.25 0 01-1.07 1.916l-7.5 4.615a2.25 2.25 0 01-2.36 0L3.32 8.91a2.25 2.25 0 01-1.07-1.916V6.75" />
                      </svg>
                    </a>
                  )}
                  {person.phone && (
                    <a href={`tel:${person.phone}`} className="p-1.5 rounded-lg text-navy-secondary/30 hover:text-navy-secondary hover:bg-cream-dark transition-all" title={person.phone}>
                      <svg className="w-[18px] h-[18px]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 6.75c0 8.284 6.716 15 15 15h2.25a2.25 2.25 0 002.25-2.25v-1.372c0-.516-.351-.966-.852-1.091l-4.423-1.106c-.44-.11-.902.055-1.173.417l-.97 1.293c-.282.376-.769.542-1.21.38a12.035 12.035 0 01-7.143-7.143c-.162-.441.004-.928.38-1.21l1.293-.97c.363-.271.527-.734.417-1.173L6.963 3.102a1.125 1.125 0 00-1.091-.852H4.5A2.25 2.25 0 002.25 4.5v2.25z" />
                      </svg>
                    </a>
                  )}
                  {person.instagram && (
                    <a href={`https://instagram.com/${person.instagram.replace('@', '')}`} target="_blank" rel="noopener noreferrer" className="p-1.5 rounded-lg text-navy-secondary/30 hover:text-navy-secondary hover:bg-cream-dark transition-all" title={`@${person.instagram.replace('@', '')}`}>
                      <svg className="w-[18px] h-[18px]" fill="currentColor" viewBox="0 0 24 24">
                        <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z" />
                      </svg>
                    </a>
                  )}
                  {person.resumeURL && (
                    <a href={person.resumeURL} target="_blank" rel="noopener noreferrer" className="p-1.5 rounded-lg text-navy-secondary/30 hover:text-pink-dark hover:bg-pink-dark/5 transition-all" title="View Resume">
                      <svg className="w-[18px] h-[18px]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z" />
                      </svg>
                    </a>
                  )}
                  {(person.email || person.phone || person.instagram || person.resumeURL) && (person.address || person.college || person.dressSize || person.shoeSize) && (
                    <span className="text-navy-secondary/12 mx-0.5">|</span>
                  )}
                  {person.address && (
                    <a href={`https://maps.google.com/?q=${encodeURIComponent(person.address)}`} target="_blank" rel="noopener noreferrer" className="p-1.5 rounded-lg text-navy-secondary/30 hover:text-navy-secondary hover:bg-cream-dark transition-all" title={person.address}>
                      <svg className="w-[18px] h-[18px]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M15 10.5a3 3 0 11-6 0 3 3 0 016 0z" />
                        <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1115 0z" />
                      </svg>
                    </a>
                  )}
                  {person.college && (
                    <span className="flex items-center gap-1 text-[13px] text-navy-secondary/50 mr-2">
                      <svg className="w-3.5 h-3.5 text-navy-secondary/30" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M4.26 10.147a60.438 60.438 0 00-.491 6.347A48.627 48.627 0 0112 20.904a48.627 48.627 0 018.232-4.41 60.46 60.46 0 00-.491-6.347m-15.482 0a50.57 50.57 0 00-2.658-.813A59.906 59.906 0 0112 3.493a59.903 59.903 0 0110.399 5.84c-.896.248-1.783.52-2.658.814m-15.482 0A50.697 50.697 0 0112 13.489a50.702 50.702 0 017.74-3.342" />
                      </svg>
                      {person.college}
                    </span>
                  )}
                  {person.dressSize && (
                    <span className="text-[11px] uppercase tracking-wider text-navy-secondary/35 font-medium mr-2">Dress {person.dressSize}</span>
                  )}
                  {person.shoeSize && (
                    <span className="text-[11px] uppercase tracking-wider text-navy-secondary/35 font-medium">Shoe {person.shoeSize}</span>
                  )}
                </div>
              </div>

              {/* Actions */}
              <div className="flex gap-2 flex-shrink-0">
                {!person.applicationFormApproved && (
                  <Button size="sm" onClick={toggleApproval}>Approve</Button>
                )}
                {editing ? (
                  <>
                    <Button variant="danger" size="sm" onClick={handleDelete}>Delete</Button>
                    <Button variant="secondary" size="sm" onClick={() => setEditing(false)}>Cancel</Button>
                    <Button size="sm" onClick={save} loading={saving}>Save</Button>
                  </>
                ) : (
                  <Button variant="secondary" size="sm" onClick={() => setEditing(true)}>Edit</Button>
                )}
              </div>
            </div>
          </div>
        </div>

        {editing && (
          <div className="mt-6 pt-6 border-t border-border-subtle">
            <div className="grid grid-cols-2 gap-4">
              {editFields.map((f) => (
                <Input
                  key={f.key}
                  label={f.label}
                  value={String(form[f.key] || '')}
                  onChange={(e) => setForm({ ...form, [f.key]: f.key === 'payRate' ? Number(e.target.value) : e.target.value })}
                  type={f.key === 'payRate' ? 'number' : 'text'}
                />
              ))}
            </div>
          </div>
        )}
      </Card>

      {/* Bookings & Availability Toggle */}
      <Card>
        <div className="flex items-center gap-1 mb-4 bg-cream-dark rounded-lg p-1 w-fit">
          <button
            onClick={() => setActiveSection('bookings')}
            className={`px-4 py-1.5 text-sm font-medium rounded-md transition-all ${
              activeSection === 'bookings'
                ? 'bg-white text-navy-heading shadow-sm'
                : 'text-navy-secondary/60 hover:text-navy-secondary'
            }`}
          >
            Bookings ({staffBookings.length})
          </button>
          <button
            onClick={() => setActiveSection('availability')}
            className={`px-4 py-1.5 text-sm font-medium rounded-md transition-all ${
              activeSection === 'availability'
                ? 'bg-white text-navy-heading shadow-sm'
                : 'text-navy-secondary/60 hover:text-navy-secondary'
            }`}
          >
            Availability ({availabilities.length})
          </button>
        </div>

        <div className="max-h-[400px] overflow-y-auto scrollbar-hide">
          {activeSection === 'bookings' && (
            <div className="space-y-1">
              {staffBookings.length === 0 && <p className="text-sm text-navy-secondary/40 py-4">No bookings yet</p>}
              {staffBookings.map((b) => {
                const show = shows.find((s) => s.id === b.showId);
                const assignedDates = b.datesNeeded.filter((d) => d.staffIds.includes(id)).map((d) => d.date).sort();
                return (
                  <Link
                    key={b.id}
                    href={`/bookings/${b.id}`}
                    className="flex items-center justify-between p-3 rounded-xl hover:bg-cream-dark transition-colors group"
                  >
                    <div className="min-w-0">
                      <div className="text-sm font-medium text-navy group-hover:text-navy-heading">{show?.name || 'Unknown'}</div>
                      <div className="text-xs text-navy-secondary/40 mt-0.5">
                        {assignedDates.length} day{assignedDates.length !== 1 ? 's' : ''}
                        {assignedDates.length > 0 && (
                          <> · {formatDateShort(assignedDates[0])}{assignedDates.length > 1 && ` – ${formatDateShort(assignedDates[assignedDates.length - 1])}`}</>
                        )}
                      </div>
                    </div>
                    <Badge status={b.status}>{b.status}</Badge>
                  </Link>
                );
              })}
            </div>
          )}

          {activeSection === 'availability' && (
            <div className="space-y-1">
              {availabilities.length === 0 && <p className="text-sm text-navy-secondary/40 py-4">No availability submitted</p>}
              {availabilities.map((a) => (
                <Link
                  key={a.id}
                  href={`/shows/${a.showId}`}
                  className="block p-3 rounded-xl hover:bg-cream-dark transition-colors group"
                >
                  <div className="flex items-center justify-between">
                    <div className="text-sm font-medium text-navy group-hover:text-navy-heading">{a.showName}</div>
                    <span className="text-xs text-navy-secondary/40">{a.availableDates.length} date{a.availableDates.length !== 1 ? 's' : ''}</span>
                  </div>
                  <div className="flex flex-wrap gap-1.5 mt-2">
                    {a.availableDates.sort().map((d) => (
                      <span key={d} className="text-[11px] bg-cream-dark group-hover:bg-white px-2 py-0.5 rounded-md text-navy-secondary/60 transition-colors">
                        {formatDateShort(d)}
                      </span>
                    ))}
                  </div>
                </Link>
              ))}
            </div>
          )}
        </div>
      </Card>

      {/* Direct Deposit */}
      <Card>
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-sm font-semibold text-navy-heading">Direct Deposit</h2>
          {person.directDepositCompleted ? (
            <Badge variant="emerald">Completed</Badge>
          ) : (
            <Badge variant="amber">Not Submitted</Badge>
          )}
        </div>
        {person.directDepositCompleted ? (
          <div className="grid grid-cols-2 gap-4">
            <div>
              <div className="text-[11px] font-medium text-navy-secondary/50 uppercase tracking-wider mb-1">Account Holder</div>
              <div className="text-sm text-navy">{person.bankAccountHolderName || '—'}</div>
            </div>
            <div>
              <div className="text-[11px] font-medium text-navy-secondary/50 uppercase tracking-wider mb-1">Account Type</div>
              <div className="text-sm text-navy capitalize">{person.bankAccountType || '—'}</div>
            </div>
            <div>
              <div className="text-[11px] font-medium text-navy-secondary/50 uppercase tracking-wider mb-1">Routing Number</div>
              <div className="text-sm text-navy font-mono">{person.bankRoutingNumber || '—'}</div>
            </div>
            <div>
              <div className="text-[11px] font-medium text-navy-secondary/50 uppercase tracking-wider mb-1">Account Number</div>
              <div className="text-sm text-navy font-mono">{person.bankAccountNumber || '—'}</div>
            </div>
          </div>
        ) : (
          <p className="text-sm text-navy-secondary/40">Staff member has not submitted direct deposit information yet.</p>
        )}
      </Card>
    </div>
  );
}
