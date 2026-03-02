'use client';

import { useState, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import { showService } from '@/lib/firebase/service';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input, Select } from '@/components/ui/Input';
import { useToast } from '@/components/ui/Toast';
import type { Show } from '@/types';

const LOCATIONS = ['ATL', 'NYC', 'LA', 'Vegas', 'Dallas'];
const SEASONS = ['Winter', 'Spring', 'Summer', 'Fall'];
const TYPES = ['Gift', 'Apparel', 'Bridal'];

export default function NewShowPage() {
  const router = useRouter();
  const { toast } = useToast();
  const [loading, setLoading] = useState(false);
  const [form, setForm] = useState({
    startDate: '', endDate: '', location: '', season: '', type: '',
    status: 'active' as Show['status'],
  });

  function set<K extends keyof typeof form>(key: K, value: typeof form[K]) {
    setForm((f) => ({ ...f, [key]: value }));
  }

  const generatedName = useMemo(() => {
    const parts: string[] = [];
    if (form.location) parts.push(form.location);
    if (form.season) parts.push(form.season);
    if (form.type) parts.push(form.type);
    if (form.startDate) parts.push(form.startDate.slice(0, 4));
    return parts.join(' ') || 'Untitled Show';
  }, [form.location, form.season, form.type, form.startDate]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    try {
      await showService.create({
        ...form,
        name: generatedName,
        venue: '',
        description: '',
      });
      toast('success', 'Show created');
      router.push('/shows');
    } catch {
      toast('error', 'Failed to create show');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      <h1 className="text-2xl font-semibold text-navy-heading">New Show</h1>
      <Card>
        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Generated name preview */}
          <div className="px-4 py-3 bg-cream-dark rounded-xl">
            <div className="text-xs text-navy-secondary/40 mb-1">Show Name</div>
            <div className="text-lg font-semibold text-navy">{generatedName}</div>
          </div>

          <div className="grid grid-cols-3 gap-4">
            <Select
              label="Location"
              value={form.location}
              onChange={(e) => set('location', e.target.value)}
              options={[
                { value: '', label: 'Select…' },
                ...LOCATIONS.map((l) => ({ value: l, label: l })),
              ]}
              required
            />
            <Select
              label="Season"
              value={form.season}
              onChange={(e) => set('season', e.target.value)}
              options={[
                { value: '', label: 'Select…' },
                ...SEASONS.map((s) => ({ value: s, label: s })),
              ]}
              required
            />
            <Select
              label="Type"
              value={form.type}
              onChange={(e) => set('type', e.target.value)}
              options={[
                { value: '', label: 'Select…' },
                ...TYPES.map((t) => ({ value: t, label: t })),
              ]}
              required
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <Input label="Start Date" type="date" value={form.startDate} onChange={(e) => set('startDate', e.target.value)} required />
            <Input label="End Date" type="date" value={form.endDate} onChange={(e) => set('endDate', e.target.value)} required />
          </div>

          <Select
            label="Status"
            value={form.status}
            onChange={(e) => set('status', e.target.value as Show['status'])}
            options={[
              { value: 'active', label: 'Active' },
              { value: 'inactive', label: 'Inactive' },
            ]}
          />

          <div className="flex justify-end gap-3 pt-4">
            <Button variant="secondary" type="button" onClick={() => router.back()}>Cancel</Button>
            <Button type="submit" loading={loading} disabled={!form.location || !form.season || !form.type}>Create Show</Button>
          </div>
        </form>
      </Card>
    </div>
  );
}
