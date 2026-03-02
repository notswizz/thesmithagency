'use client';

import { useState, useMemo } from 'react';
import Link from 'next/link';
import { useStore } from '@/lib/store';
import { Card } from '@/components/ui/Card';
import { Avatar } from '@/components/ui/Avatar';
import { SearchInput, SearchSuggestion } from '@/components/ui/SearchInput';
import { searchEntities } from '@/lib/utils/search';

export default function StaffPage() {
  const { staff, bookings } = useStore();
  const [search, setSearch] = useState('');
  const [locationFilter, setLocationFilter] = useState('all');
  const [statusFilter, setStatusFilter] = useState<'all' | 'approved' | 'pending'>('all');

  const locations = useMemo(() => {
    const locs = new Set(staff.map((s) => s.location).filter(Boolean));
    return Array.from(locs).sort();
  }, [staff]);

  const suggestions = useMemo<SearchSuggestion[]>(() => {
    if (!search.trim()) return [];
    return searchEntities(staff, search, ['name', 'email', 'location'])
      .slice(0, 6)
      .map((s) => ({ label: s.name, sublabel: s.location || s.email, icon: '👤' }));
  }, [staff, search]);

  const filtered = useMemo(() => {
    let result = staff;
    if (search) result = searchEntities(result, search, ['name', 'email', 'location']);
    if (locationFilter !== 'all') result = result.filter((s) => s.location === locationFilter);
    if (statusFilter === 'approved') result = result.filter((s) => s.applicationFormApproved);
    if (statusFilter === 'pending') result = result.filter((s) => !s.applicationFormApproved);
    return result;
  }, [staff, search, locationFilter, statusFilter]);

  function getBookingCount(staffId: string) {
    return bookings.filter((b) =>
      b.status !== 'cancelled' &&
      b.datesNeeded.some((d) => d.staffIds.includes(staffId))
    ).length;
  }

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-semibold text-navy-heading">Staff ({staff.length})</h1>

      <div className="flex flex-col sm:flex-row gap-4">
        <div className="flex-1">
          <SearchInput placeholder="Search staff…" value={search} onChange={setSearch} suggestions={suggestions} />
        </div>
        <select
          value={locationFilter}
          onChange={(e) => setLocationFilter(e.target.value)}
          className="px-3 py-2 text-sm rounded-lg ring-1 ring-border-light bg-white"
        >
          <option value="all">All locations</option>
          {locations.map((l) => <option key={l} value={l}>{l}</option>)}
        </select>
        <div className="flex gap-2">
          {(['all', 'approved', 'pending'] as const).map((s) => (
            <button
              key={s}
              onClick={() => setStatusFilter(s)}
              className={`px-3 py-2 text-xs font-medium rounded-lg capitalize transition-colors ${
                statusFilter === s ? 'bg-pink-dark text-white' : 'bg-white text-navy-secondary ring-1 ring-border-light hover:bg-cream-dark'
              }`}
            >
              {s}
            </button>
          ))}
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
        {filtered.map((s) => {
          const avatarSrc = s.photoURL;
          const bookingCount = getBookingCount(s.id);
          return (
            <Link key={s.id} href={`/staff/${s.id}`}>
              <Card padding={false} className="hover:ring-border-light transition-all cursor-pointer overflow-hidden">
                <div className="flex flex-col items-center pt-6 pb-4 px-4">
                  <Avatar
                    src={avatarSrc}
                    name={s.name}
                    size="lg"
                    status={s.applicationFormApproved ? 'approved' : 'pending'}
                  />
                  <div className="mt-3 text-center">
                    <div className="font-semibold text-navy truncate">{s.name}</div>
                    <div className="text-xs text-navy-secondary/40 mt-0.5">{s.location}{s.college ? ` · ${s.college}` : ''}</div>
                  </div>
                </div>
                <div className="border-t border-border-subtle px-4 py-3 flex items-center justify-between text-xs text-navy-secondary/60">
                  <span>{bookingCount} booking{bookingCount !== 1 ? 's' : ''}</span>
                  <span className="font-medium text-navy">${s.payRate}/hr</span>
                </div>
              </Card>
            </Link>
          );
        })}
      </div>

      {filtered.length === 0 && (
        <div className="text-center py-12 text-navy-secondary/40">No staff found</div>
      )}
    </div>
  );
}
