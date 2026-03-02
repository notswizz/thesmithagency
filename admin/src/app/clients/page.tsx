'use client';

import { useState, useMemo } from 'react';
import Link from 'next/link';
import { useStore } from '@/lib/store';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Modal } from '@/components/ui/Modal';
import { useToast } from '@/components/ui/Toast';
import { SearchInput, SearchSuggestion } from '@/components/ui/SearchInput';
import { clientService } from '@/lib/firebase/service';
import { searchEntities } from '@/lib/utils/search';

export default function ClientsPage() {
  const { clients, bookings } = useStore();
  const { toast } = useToast();
  const [search, setSearch] = useState('');
  const [showCreate, setShowCreate] = useState(false);
  const [creating, setCreating] = useState(false);
  const [form, setForm] = useState({ name: '', email: '', website: '' });

  const suggestions = useMemo<SearchSuggestion[]>(() => {
    if (!search.trim()) return [];
    return searchEntities(clients, search, ['name', 'email'])
      .slice(0, 6)
      .map((c) => ({ label: c.name, sublabel: c.email, icon: '🏢' }));
  }, [clients, search]);

  const filtered = useMemo(() => {
    if (!search) return clients;
    return searchEntities(clients, search, ['name', 'email']);
  }, [clients, search]);

  function getBookingCount(clientId: string) {
    return bookings.filter((b) => b.clientId === clientId).length;
  }

  async function handleCreate(e: React.FormEvent) {
    e.preventDefault();
    setCreating(true);
    try {
      await clientService.create(form);
      toast('success', 'Client created');
      setShowCreate(false);
      setForm({ name: '', email: '', website: '' });
    } catch {
      toast('error', 'Failed to create client');
    } finally {
      setCreating(false);
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold text-navy-heading">Clients ({clients.length})</h1>
      </div>

      <SearchInput placeholder="Search clients…" value={search} onChange={setSearch} suggestions={suggestions} />

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        {filtered.map((c) => (
          <Link key={c.id} href={`/clients/${c.id}`}>
            <Card className="hover:ring-border-light transition-all cursor-pointer">
              <div className="font-medium text-navy">{c.name}</div>
              <div className="text-xs text-navy-secondary/40 mt-1">{c.email}</div>
              <div className="text-xs text-navy-secondary/60 mt-2">{getBookingCount(c.id)} bookings</div>
            </Card>
          </Link>
        ))}
      </div>

      {filtered.length === 0 && <div className="text-center py-12 text-navy-secondary/40">No clients found</div>}

      <Modal open={showCreate} onClose={() => setShowCreate(false)} title="New Client">
        <form onSubmit={handleCreate} className="space-y-4">
          <Input label="Name" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} required />
          <Input label="Email" type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} required />
          <Input label="Website" value={form.website} onChange={(e) => setForm({ ...form, website: e.target.value })} />
          <div className="flex justify-end gap-3 pt-2">
            <Button variant="secondary" type="button" onClick={() => setShowCreate(false)}>Cancel</Button>
            <Button type="submit" loading={creating}>Create</Button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
