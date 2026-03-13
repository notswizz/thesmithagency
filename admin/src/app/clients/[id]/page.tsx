'use client';

import { useState, useEffect, useMemo } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import { useStore } from '@/lib/store';
import { clientService, contactService, showroomService } from '@/lib/firebase/service';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Modal } from '@/components/ui/Modal';
import { Tabs } from '@/components/ui/Tabs';
import { useToast } from '@/components/ui/Toast';
import { totalNeeded, totalAssigned } from '@/lib/utils/booking';
import type { Contact, Showroom } from '@/types';

export default function ClientDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const { toast } = useToast();
  const { clients, bookings, shows } = useStore();
  const client = clients.find((c) => c.id === id);

  const [tab, setTab] = useState('bookings');
  const [contacts, setContacts] = useState<Contact[]>([]);
  const [showrooms, setShowrooms] = useState<Showroom[]>([]);
  const [editing, setEditing] = useState(false);
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState({ name: '', email: '', website: '' });

  // Contact modal
  const [showContactModal, setShowContactModal] = useState(false);
  const [contactForm, setContactForm] = useState({ name: '', email: '', phone: '', role: '' });
  const [savingContact, setSavingContact] = useState(false);

  // Showroom modal
  const [showShowroomModal, setShowShowroomModal] = useState(false);
  const [showroomForm, setShowroomForm] = useState({ city: '', buildingNumber: '', floorNumber: '', boothNumber: '' });
  const [savingShowroom, setSavingShowroom] = useState(false);

  // Admin notes
  const [adminNotes, setAdminNotes] = useState('');
  const [savingNotes, setSavingNotes] = useState(false);

  useEffect(() => {
    if (client) {
      setForm({ name: client.name, email: client.email, website: client.website });
      setAdminNotes((client as Record<string, unknown>).adminNotes as string || '');
    }
  }, [client]);

  useEffect(() => {
    contactService.getByClient(id).then(setContacts);
    showroomService.getByClient(id).then(setShowrooms);
  }, [id]);

  const clientBookings = useMemo(
    () => bookings.filter((b) => b.clientId === id),
    [bookings, id]
  );

  async function saveClient() {
    setSaving(true);
    try {
      await clientService.update(id, form);
      toast('success', 'Client updated');
      setEditing(false);
    } catch {
      toast('error', 'Failed to update');
    } finally {
      setSaving(false);
    }
  }

  async function addContact(e: React.FormEvent) {
    e.preventDefault();
    setSavingContact(true);
    try {
      await contactService.create({ ...contactForm, clientId: id });
      setContacts(await contactService.getByClient(id));
      setShowContactModal(false);
      setContactForm({ name: '', email: '', phone: '', role: '' });
      toast('success', 'Contact added');
    } catch {
      toast('error', 'Failed to add contact');
    } finally {
      setSavingContact(false);
    }
  }

  async function deleteContact(contactId: string) {
    await contactService.delete(contactId);
    setContacts((prev) => prev.filter((c) => c.id !== contactId));
    toast('success', 'Contact removed');
  }

  async function addShowroom(e: React.FormEvent) {
    e.preventDefault();
    setSavingShowroom(true);
    try {
      await showroomService.create({ ...showroomForm, clientId: id });
      setShowrooms(await showroomService.getByClient(id));
      setShowShowroomModal(false);
      setShowroomForm({ city: '', buildingNumber: '', floorNumber: '', boothNumber: '' });
      toast('success', 'Showroom added');
    } catch {
      toast('error', 'Failed to add showroom');
    } finally {
      setSavingShowroom(false);
    }
  }

  async function deleteShowroom(showroomId: string) {
    await showroomService.delete(showroomId);
    setShowrooms((prev) => prev.filter((s) => s.id !== showroomId));
    toast('success', 'Showroom removed');
  }

  if (!client) {
    return <div className="text-center py-12 text-navy-secondary/40">Client not found</div>;
  }

  return (
    <div className="space-y-6 max-w-4xl">
      <button onClick={() => router.back()} className="text-sm text-navy-secondary/40 hover:text-navy-secondary">← Back</button>

      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-navy-heading">{client.name}</h1>
          <div className="text-sm text-navy-secondary/40 mt-1">{client.email}</div>
        </div>
        <div className="flex gap-2">
          {editing ? (
            <>
              <Button variant="secondary" size="sm" onClick={() => setEditing(false)}>Cancel</Button>
              <Button size="sm" onClick={saveClient} loading={saving}>Save</Button>
            </>
          ) : (
            <Button variant="secondary" size="sm" onClick={() => setEditing(true)}>Edit</Button>
          )}
        </div>
      </div>

      {editing && (
        <Card>
          <div className="grid grid-cols-2 gap-4">
            <Input label="Name" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
            <Input label="Email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} />
            <Input label="Website" value={form.website} onChange={(e) => setForm({ ...form, website: e.target.value })} />
          </div>
        </Card>
      )}

      <Tabs
        tabs={[
          { key: 'bookings', label: 'Bookings', count: clientBookings.length },
          { key: 'contacts', label: 'Contacts', count: contacts.length },
          { key: 'showrooms', label: 'Showrooms', count: showrooms.length },
        ]}
        active={tab}
        onChange={setTab}
      />

      {tab === 'bookings' && (
        <div className="space-y-2">
          {clientBookings.length === 0 && <div className="text-center py-8 text-navy-secondary/40">No bookings yet</div>}
          {clientBookings.map((b) => {
            const show = shows.find((s) => s.id === b.showId);
            return (
              <Link key={b.id} href={`/bookings/${b.id}`}>
                <Card className="hover:ring-border-light transition-all cursor-pointer">
                  <div className="flex items-center justify-between">
                    <div>
                      <span className="font-medium text-navy">{show?.name || 'Unknown'}</span>
                      <span className="text-xs text-navy-secondary/40 ml-2">
                        {totalAssigned(b)}/{totalNeeded(b)} staff
                      </span>
                    </div>
                    <Badge status={b.status}>{b.status}</Badge>
                  </div>
                </Card>
              </Link>
            );
          })}
        </div>
      )}

      {tab === 'contacts' && (
        <div className="space-y-3">
          <div className="flex justify-end">
            <Button size="sm" onClick={() => setShowContactModal(true)}>+ Add Contact</Button>
          </div>
          {contacts.map((c) => (
            <Card key={c.id}>
              <div className="flex items-center justify-between">
                <div>
                  <div className="font-medium text-navy">{c.name}</div>
                  <div className="text-xs text-navy-secondary/40">{c.role} · {c.email} · {c.phone}</div>
                </div>
                <button onClick={() => deleteContact(c.id)} className="text-xs text-red-400 hover:text-red-600">Remove</button>
              </div>
            </Card>
          ))}
          {contacts.length === 0 && <div className="text-center py-8 text-navy-secondary/40">No contacts</div>}
        </div>
      )}

      {tab === 'showrooms' && (
        <div className="space-y-3">
          <div className="flex justify-end">
            <Button size="sm" onClick={() => setShowShowroomModal(true)}>+ Add Showroom</Button>
          </div>
          {showrooms.map((s) => (
            <Card key={s.id}>
              <div className="flex items-center justify-between">
                <div>
                  <div className="font-medium text-navy">{s.city}</div>
                  <div className="text-xs text-navy-secondary/40">
                    Building {s.buildingNumber} · Floor {s.floorNumber} · Booth {s.boothNumber}
                  </div>
                </div>
                <button onClick={() => deleteShowroom(s.id)} className="text-xs text-red-400 hover:text-red-600">Remove</button>
              </div>
            </Card>
          ))}
          {showrooms.length === 0 && <div className="text-center py-8 text-navy-secondary/40">No showrooms</div>}
        </div>
      )}

      {/* Contact Modal */}
      <Modal open={showContactModal} onClose={() => setShowContactModal(false)} title="Add Contact">
        <form onSubmit={addContact} className="space-y-4">
          <Input label="Name" value={contactForm.name} onChange={(e) => setContactForm({ ...contactForm, name: e.target.value })} required />
          <Input label="Email" value={contactForm.email} onChange={(e) => setContactForm({ ...contactForm, email: e.target.value })} />
          <Input label="Phone" value={contactForm.phone} onChange={(e) => setContactForm({ ...contactForm, phone: e.target.value })} />
          <Input label="Role" value={contactForm.role} onChange={(e) => setContactForm({ ...contactForm, role: e.target.value })} />
          <div className="flex justify-end gap-3">
            <Button variant="secondary" type="button" onClick={() => setShowContactModal(false)}>Cancel</Button>
            <Button type="submit" loading={savingContact}>Add</Button>
          </div>
        </form>
      </Modal>

      {/* Admin Notes */}
      <Card>
        <h2 className="text-sm font-semibold text-navy-heading mb-3">Admin Notes</h2>
        <textarea
          value={adminNotes}
          onChange={(e) => setAdminNotes(e.target.value)}
          placeholder="Internal notes about this client..."
          rows={4}
          className="w-full px-3 py-2 rounded-lg ring-1 ring-border-light text-sm focus:outline-none focus:ring-2 focus:ring-pink-dark resize-y"
        />
        <div className="flex justify-end mt-3">
          <Button
            size="sm"
            loading={savingNotes}
            onClick={async () => {
              setSavingNotes(true);
              try {
                await clientService.update(id, { adminNotes });
                toast('success', 'Notes saved');
              } catch {
                toast('error', 'Failed to save notes');
              } finally {
                setSavingNotes(false);
              }
            }}
          >
            Save Notes
          </Button>
        </div>
      </Card>

      {/* Showroom Modal */}
      <Modal open={showShowroomModal} onClose={() => setShowShowroomModal(false)} title="Add Showroom">
        <form onSubmit={addShowroom} className="space-y-4">
          <Input label="City" value={showroomForm.city} onChange={(e) => setShowroomForm({ ...showroomForm, city: e.target.value })} required placeholder="ATL, LA, DAL, NYC, LV, NSH, MIA" />
          <Input label="Building Number" value={showroomForm.buildingNumber} onChange={(e) => setShowroomForm({ ...showroomForm, buildingNumber: e.target.value })} />
          <Input label="Floor Number" value={showroomForm.floorNumber} onChange={(e) => setShowroomForm({ ...showroomForm, floorNumber: e.target.value })} />
          <Input label="Booth Number" value={showroomForm.boothNumber} onChange={(e) => setShowroomForm({ ...showroomForm, boothNumber: e.target.value })} />
          <div className="flex justify-end gap-3">
            <Button variant="secondary" type="button" onClick={() => setShowShowroomModal(false)}>Cancel</Button>
            <Button type="submit" loading={savingShowroom}>Add</Button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
