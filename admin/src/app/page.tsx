'use client';

import { useState, useMemo } from 'react';
import Link from 'next/link';
import { useStore } from '@/lib/store';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { formatDateShort, toDateString, getMonthDays, getMonthName, getDayName, isInRange } from '@/lib/utils/dates';

interface ActivityItem {
  id: string;
  type: 'booking' | 'staff' | 'client' | 'availability' | 'show';
  label: string;
  detail: string;
  href: string;
  timestamp: number;
  icon: string;
  color: string;
}

export default function DashboardPage() {
  const { staff, shows, bookings, clients, availability } = useStore();

  // Stats
  const stats = useMemo(() => {
    const activeStaff = staff.filter((s) => s.applicationFormApproved).length;
    const totalBookings = bookings.length;
    const totalDaysBooked = bookings.reduce(
      (sum, b) => sum + (b.datesNeeded?.reduce((ds, d) => ds + d.staffIds.filter(Boolean).length, 0) || 0),
      0
    );
    return { activeStaff, totalClients: clients.length, totalBookings, totalDaysBooked };
  }, [staff, bookings, clients]);

  // Activity feed — combine all entity types
  const activity = useMemo<ActivityItem[]>(() => {
    const items: ActivityItem[] = [];

    for (const b of bookings) {
      const ts = b.createdAt?.seconds || 0;
      const clientName = clients.find((c) => c.id === b.clientId)?.name || 'Unknown';
      const showName = shows.find((s) => s.id === b.showId)?.name || 'Unknown';
      items.push({
        id: `booking-${b.id}`,
        type: 'booking',
        label: `New booking from ${clientName}`,
        detail: showName,
        href: `/bookings/${b.id}`,
        timestamp: ts,
        icon: '📋',
        color: 'bg-amber-50 text-amber-600',
      });
    }

    for (const s of staff) {
      const ts = s.createdAt?.seconds || 0;
      items.push({
        id: `staff-${s.id}`,
        type: 'staff',
        label: `${s.name} joined`,
        detail: s.location || 'No location',
        href: `/staff/${s.id}`,
        timestamp: ts,
        icon: '👤',
        color: 'bg-emerald-50 text-emerald-600',
      });
    }

    for (const c of clients) {
      const ts = c.createdAt?.seconds || 0;
      items.push({
        id: `client-${c.id}`,
        type: 'client',
        label: `${c.name} signed up`,
        detail: c.email || '',
        href: `/clients/${c.id}`,
        timestamp: ts,
        icon: '🏢',
        color: 'bg-pink-50 text-pink-dark',
      });
    }

    for (const a of availability) {
      const ts = a.createdAt?.seconds || 0;
      items.push({
        id: `avail-${a.id}`,
        type: 'availability',
        label: `${a.staffName} submitted availability`,
        detail: `${a.showName} — ${a.availableDates.length} dates`,
        href: `/shows/${a.showId}`,
        timestamp: ts,
        icon: '📅',
        color: 'bg-blue-50 text-blue-600',
      });
    }

    return items
      .filter((i) => i.timestamp > 0)
      .sort((a, b) => b.timestamp - a.timestamp)
      .slice(0, 15);
  }, [bookings, staff, clients, availability, shows]);

  // Calendar state
  const today = new Date();
  const [viewYear, setViewYear] = useState(today.getFullYear());
  const [viewMonth, setViewMonth] = useState(today.getMonth());

  const days = useMemo(() => getMonthDays(viewYear, viewMonth), [viewYear, viewMonth]);
  const startDow = days[0].getDay();
  const todayStr = toDateString(today);

  // Shows that overlap with current month view
  const monthShows = useMemo(() => {
    const monthStart = toDateString(new Date(viewYear, viewMonth, 1));
    const monthEnd = toDateString(new Date(viewYear, viewMonth + 1, 0));
    return shows.filter(
      (s) => s.status === 'active' && s.startDate <= monthEnd && s.endDate >= monthStart
    );
  }, [shows, viewYear, viewMonth]);

  function getShowsForDate(dateStr: string) {
    return monthShows.filter((s) => isInRange(dateStr, s.startDate, s.endDate));
  }

  function prevMonth() {
    if (viewMonth === 0) { setViewMonth(11); setViewYear((y) => y - 1); }
    else setViewMonth((m) => m - 1);
  }

  function nextMonth() {
    if (viewMonth === 11) { setViewMonth(0); setViewYear((y) => y + 1); }
    else setViewMonth((m) => m + 1);
  }

  function formatTimestamp(seconds: number): string {
    const now = Date.now() / 1000;
    const diff = now - seconds;
    if (diff < 3600) return `${Math.max(1, Math.floor(diff / 60))}m ago`;
    if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
    if (diff < 604800) return `${Math.floor(diff / 86400)}d ago`;
    const d = new Date(seconds * 1000);
    return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  }

  const statCards = [
    { label: 'Active Staff', value: stats.activeStaff, color: 'text-emerald-600', bg: 'bg-emerald-50', href: '/staff' },
    { label: 'Total Clients', value: stats.totalClients, color: 'text-pink-dark', bg: 'bg-pink-50', href: '/clients' },
    { label: 'Total Bookings', value: stats.totalBookings, color: 'text-amber-600', bg: 'bg-amber-50', href: '/bookings' },
    { label: 'Days Booked', value: stats.totalDaysBooked, color: 'text-blue-600', bg: 'bg-blue-50', href: '/bookings' },
  ];

  return (
    <div className="space-y-6">
      {/* Stats Row */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {statCards.map((s) => (
          <Link key={s.label} href={s.href}>
            <Card className="hover:ring-border-light transition-all cursor-pointer">
              <div className="flex flex-col">
                <span className="text-[11px] font-medium text-navy-secondary/60 uppercase tracking-wider">{s.label}</span>
                <span className={`text-3xl font-semibold mt-1 ${s.color}`}>{s.value}</span>
              </div>
            </Card>
          </Link>
        ))}
      </div>

      <div className="grid lg:grid-cols-5 gap-6">
        {/* Shows Calendar — takes 3 cols */}
        <div className="lg:col-span-3">
          <Card>
            <div className="flex items-center justify-between mb-5">
              <h2 className="text-lg font-semibold text-navy-heading">Shows Calendar</h2>
              <div className="flex items-center gap-3">
                <button onClick={prevMonth} className="p-1.5 hover:bg-cream-dark rounded-lg text-navy-secondary transition-colors">
                  <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" /></svg>
                </button>
                <span className="text-sm font-semibold text-navy-heading min-w-[140px] text-center">
                  {getMonthName(viewMonth)} {viewYear}
                </span>
                <button onClick={nextMonth} className="p-1.5 hover:bg-cream-dark rounded-lg text-navy-secondary transition-colors">
                  <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" /></svg>
                </button>
              </div>
            </div>

            <div className="grid grid-cols-7 gap-px bg-border-subtle rounded-xl overflow-hidden ring-1 ring-border-light">
              {/* Day headers */}
              {[0, 1, 2, 3, 4, 5, 6].map((d) => (
                <div key={d} className="bg-cream-dark py-2 text-center text-[11px] font-medium text-navy-secondary/60 uppercase tracking-wider">
                  {getDayName(d)}
                </div>
              ))}
              {/* Padding */}
              {Array.from({ length: startDow }).map((_, i) => (
                <div key={`pad-${i}`} className="bg-white min-h-[80px]" />
              ))}
              {/* Days */}
              {days.map((day) => {
                const dateStr = toDateString(day);
                const isToday = dateStr === todayStr;
                const dayShows = getShowsForDate(dateStr);
                return (
                  <div
                    key={dateStr}
                    className={`bg-white min-h-[80px] p-1.5 ${isToday ? 'ring-2 ring-inset ring-pink-dark/30' : ''}`}
                  >
                    <div className={`text-xs font-medium mb-1 ${isToday ? 'text-pink-dark' : 'text-navy-secondary/60'}`}>
                      {day.getDate()}
                    </div>
                    <div className="space-y-0.5">
                      {dayShows.slice(0, 2).map((s) => (
                        <Link
                          key={s.id}
                          href={`/shows/${s.id}`}
                          className="block text-[10px] leading-tight px-1 py-0.5 rounded bg-emerald-50 text-emerald-700 truncate hover:bg-emerald-100 transition-colors"
                        >
                          {s.name}
                        </Link>
                      ))}
                      {dayShows.length > 2 && (
                        <div className="text-[10px] text-navy-secondary/40 px-1">+{dayShows.length - 2} more</div>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Legend */}
            {monthShows.length > 0 && (
              <div className="mt-4 flex flex-wrap gap-3">
                {monthShows.map((s) => (
                  <Link
                    key={s.id}
                    href={`/shows/${s.id}`}
                    className="flex items-center gap-1.5 text-xs text-navy-secondary hover:text-navy transition-colors"
                  >
                    <span className="w-2 h-2 rounded-full bg-emerald-400" />
                    {s.name}
                    <span className="text-navy-secondary/40">
                      {formatDateShort(s.startDate)} – {formatDateShort(s.endDate)}
                    </span>
                  </Link>
                ))}
              </div>
            )}
          </Card>
        </div>

        {/* Recent Activity — takes 2 cols */}
        <div className="lg:col-span-2">
          <Card>
            <h2 className="text-lg font-semibold text-navy-heading mb-4">Recent Activity</h2>
            <div className="space-y-1 overflow-y-auto max-h-[400px] scrollbar-hide">
              {activity.length === 0 && <p className="text-sm text-navy-secondary/40">No recent activity</p>}
              {activity.map((item) => (
                <Link
                  key={item.id}
                  href={item.href}
                  className="flex items-start gap-3 py-2.5 px-2 rounded-lg hover:bg-cream-dark transition-colors group"
                >
                  <span className={`w-7 h-7 rounded-lg ${item.color} flex items-center justify-center text-xs flex-shrink-0 mt-0.5`}>
                    {item.icon}
                  </span>
                  <div className="flex-1 min-w-0">
                    <div className="text-sm text-navy font-medium truncate group-hover:text-navy-heading">{item.label}</div>
                    <div className="text-xs text-navy-secondary/40 truncate">{item.detail}</div>
                  </div>
                  <span className="text-[11px] text-navy-secondary/40 flex-shrink-0 mt-0.5">
                    {formatTimestamp(item.timestamp)}
                  </span>
                </Link>
              ))}
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
}
