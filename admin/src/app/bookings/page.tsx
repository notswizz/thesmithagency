'use client';

import { useState, useMemo } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useStore } from '@/lib/store';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { Table, Column } from '@/components/ui/Table';
import { SearchInput, SearchSuggestion } from '@/components/ui/SearchInput';
import { totalNeeded, totalAssigned, fillRatio } from '@/lib/utils/booking';
import { formatDateShort, toDateString } from '@/lib/utils/dates';
import { searchEntities } from '@/lib/utils/search';
import type { Booking } from '@/types';

export default function BookingsPage() {
  const { bookings, clients, shows } = useStore();
  const router = useRouter();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [showFilter, setShowFilter] = useState('all');
  const [paymentFilter, setPaymentFilter] = useState('all');

  const enriched = useMemo(() => {
    return bookings.map((b) => ({
      ...b,
      clientName: clients.find((c) => c.id === b.clientId)?.name || 'Unknown',
      showName: shows.find((s) => s.id === b.showId)?.name || 'Unknown',
      needed: totalNeeded(b),
      assigned: totalAssigned(b),
      fill: fillRatio(b),
    }));
  }, [bookings, clients, shows]);

  const suggestions = useMemo<SearchSuggestion[]>(() => {
    if (!search.trim()) return [];
    return searchEntities(enriched, search, ['clientName', 'showName'])
      .slice(0, 6)
      .map((b) => ({ label: b.clientName, sublabel: b.showName, icon: '📋' }));
  }, [enriched, search]);

  const filtered = useMemo(() => {
    let result = enriched;
    if (search) result = searchEntities(result, search, ['clientName', 'showName']);
    if (statusFilter !== 'all') result = result.filter((b) => b.status === statusFilter);
    if (showFilter !== 'all') result = result.filter((b) => b.showId === showFilter);
    if (paymentFilter !== 'all') result = result.filter((b) => (b.paymentStatus || 'unpaid') === paymentFilter);
    return result;
  }, [enriched, search, statusFilter, showFilter, paymentFilter]);

  type EnrichedBooking = (typeof enriched)[number];

  const columns: Column<EnrichedBooking>[] = [
    { key: 'clientName', header: 'Client', sortable: true, render: (b) => <span className="font-medium text-navy">{b.clientName}</span> },
    { key: 'showName', header: 'Show', sortable: true },
    {
      key: 'dates', header: 'Dates',
      render: (b) => {
        const dates = b.datesNeeded.map((d) => d.date).sort();
        if (dates.length === 0) return '—';
        return <span className="text-navy-secondary">{formatDateShort(dates[0])} – {formatDateShort(dates[dates.length - 1])}</span>;
      },
    },
    {
      key: 'staffing', header: 'Staffing',
      render: (b) => (
        <div className="flex items-center gap-2">
          <div className="w-16 bg-cream-dark rounded-full h-1.5">
            <div
              className={`h-1.5 rounded-full ${b.fill < 0.5 ? 'bg-red-400' : b.fill < 1 ? 'bg-amber-400' : 'bg-emerald-400'}`}
              style={{ width: `${b.fill * 100}%` }}
            />
          </div>
          <span className="text-xs text-navy-secondary/60">{b.assigned}/{b.needed}</span>
        </div>
      ),
    },
    { key: 'status', header: 'Status', render: (b) => <Badge status={b.status}>{b.status}</Badge> },
    {
      key: 'paymentStatus', header: 'Payment',
      render: (b) => b.paymentStatus ? <Badge status={b.paymentStatus as 'unpaid' | 'deposit_paid' | 'paid'}>{b.paymentStatus.replace('_', ' ')}</Badge> : <span className="text-xs text-navy-secondary/60">—</span>,
    },
    {
      key: 'balance', header: 'Balance',
      render: (b) => {
        const balance = b.balanceDue;
        if (balance == null) return <span className="text-xs text-navy-secondary/60">—</span>;
        const color = b.paymentStatus === 'paid' ? 'text-emerald-600' : b.paymentStatus === 'deposit_paid' ? 'text-amber-600' : 'text-red-500';
        return <span className={`text-sm font-medium ${color}`}>${(balance / 100).toFixed(2)}</span>;
      },
    },
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold text-navy-heading">Bookings</h1>
      </div>

      <div className="flex flex-col sm:flex-row gap-4">
        <div className="flex-1">
          <SearchInput placeholder="Search bookings…" value={search} onChange={setSearch} suggestions={suggestions} />
        </div>
        <select
          value={showFilter}
          onChange={(e) => setShowFilter(e.target.value)}
          className="px-3 py-2 text-sm rounded-lg ring-1 ring-border-light bg-white"
        >
          <option value="all">All shows</option>
          {shows.filter((s) => s.status !== 'inactive' && s.status !== 'cancelled').map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}
        </select>
        <div className="flex gap-2">
          {['all', 'pending', 'booked', 'completed'].map((s) => (
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
        <select
          value={paymentFilter}
          onChange={(e) => setPaymentFilter(e.target.value)}
          className="px-3 py-2 text-sm rounded-lg ring-1 ring-border-light bg-white"
        >
          <option value="all">All payments</option>
          <option value="unpaid">Unpaid</option>
          <option value="deposit_paid">Deposit paid</option>
          <option value="paid">Paid</option>
        </select>
      </div>

      <Card padding={false}>
        <Table
          columns={columns}
          data={filtered as (EnrichedBooking & Record<string, unknown>)[]}
          getRowKey={(b) => b.id as string}
          onRowClick={(b) => router.push(`/bookings/${b.id}`)}
        />
      </Card>
    </div>
  );
}
