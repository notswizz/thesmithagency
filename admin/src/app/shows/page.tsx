'use client';

import { useState, useMemo } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useStore } from '@/lib/store';
import { showService } from '@/lib/firebase/service';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { Table, Column } from '@/components/ui/Table';
import { formatDateShort } from '@/lib/utils/dates';
import type { Show, ShowStatus } from '@/types';

export default function ShowsPage() {
  const { shows, bookings } = useStore();
  const router = useRouter();
  const [statusFilter, setStatusFilter] = useState('active');
  const [locationFilter, setLocationFilter] = useState('all');

  const locations = useMemo(() => {
    const set = new Set<string>();
    for (const s of shows) {
      if (s.location) set.add(s.location);
    }
    return Array.from(set).sort();
  }, [shows]);

  const filtered = useMemo(() => {
    let result = shows;
    if (statusFilter !== 'all') result = result.filter((s) => s.status === statusFilter);
    if (locationFilter !== 'all') result = result.filter((s) => s.location === locationFilter);
    return result;
  }, [shows, statusFilter, locationFilter]);

  const columns: Column<Show>[] = [
    { key: 'name', header: 'Name', sortable: true, render: (s) => <span className="font-medium text-navy">{s.name}</span> },
    { key: 'startDate', header: 'Dates', sortable: true, render: (s) => <span className="text-navy-secondary">{formatDateShort(s.startDate)} – {formatDateShort(s.endDate)}</span> },
    { key: 'location', header: 'Location', sortable: true },
    {
      key: 'status', header: 'Status',
      render: (s) => (
        <button
          onClick={(e) => {
            e.stopPropagation();
            const next = s.status === 'active' ? 'inactive' : 'active';
            showService.update(s.id as string, { status: next });
          }}
          className="cursor-pointer"
        >
          <Badge status={s.status as ShowStatus}>{s.status}</Badge>
        </button>
      ),
    },
    {
      key: 'bookings', header: 'Bookings',
      render: (s) => {
        const count = bookings.filter((b) => b.showId === s.id && b.status !== 'cancelled').length;
        return <span className="text-navy-secondary">{count}</span>;
      },
    },
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold text-navy-heading">Shows</h1>
        <Link href="/shows/new">
          <Button>+ New Show</Button>
        </Link>
      </div>

      <div className="flex flex-wrap gap-3">
        <div className="flex gap-2">
          {['all', 'active', 'inactive'].map((s) => (
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
        {locations.length > 1 && (
          <select
            value={locationFilter}
            onChange={(e) => setLocationFilter(e.target.value)}
            className="px-3 py-2 text-xs rounded-lg ring-1 ring-border-light bg-white text-navy-secondary"
          >
            <option value="all">All locations</option>
            {locations.map((l) => <option key={l} value={l}>{l}</option>)}
          </select>
        )}
      </div>

      <Card padding={false}>
        <Table
          columns={columns}
          data={filtered as (Show & Record<string, unknown>)[]}
          getRowKey={(s) => s.id as string}
          onRowClick={(s) => router.push(`/shows/${s.id}`)}
        />
      </Card>
    </div>
  );
}
