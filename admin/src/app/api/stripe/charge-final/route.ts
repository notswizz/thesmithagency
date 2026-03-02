import { NextRequest, NextResponse } from 'next/server';
import Stripe from 'stripe';
import { doc, getDoc, updateDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase/config';

export async function POST(req: NextRequest) {
  try {
    if (!process.env.STRIPE_SECRET_KEY) {
      return NextResponse.json({ error: 'Stripe not configured' }, { status: 500 });
    }

    const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
    const { clientId, amount, bookingId } = await req.json();

    if (!clientId || !amount || !bookingId) {
      return NextResponse.json(
        { error: 'clientId, amount, and bookingId are required' },
        { status: 400 }
      );
    }

    // Fetch client's Stripe customer ID from Firestore
    const clientDoc = await getDoc(doc(db, 'clients', clientId));
    if (!clientDoc.exists()) {
      return NextResponse.json({ error: 'Client not found' }, { status: 404 });
    }

    const stripeCustomerId = clientDoc.data()?.stripeCustomerId;
    if (!stripeCustomerId) {
      return NextResponse.json(
        { error: 'Client has no saved payment method' },
        { status: 400 }
      );
    }

    // Get saved payment methods
    const paymentMethods = await stripe.paymentMethods.list({
      customer: stripeCustomerId,
      type: 'card',
    });

    if (paymentMethods.data.length === 0) {
      return NextResponse.json(
        { error: 'No saved payment methods found for this client' },
        { status: 400 }
      );
    }

    const paymentMethod = paymentMethods.data[0];

    // Charge the saved card off-session
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100), // Convert dollars to cents
      currency: 'usd',
      customer: stripeCustomerId,
      payment_method: paymentMethod.id,
      off_session: true,
      confirm: true,
      automatic_payment_methods: {
        enabled: true,
        allow_redirects: 'never',
      },
      metadata: {
        clientId,
        bookingId,
        bookingType: 'final',
      },
    });

    // Update booking in Firestore
    await updateDoc(doc(db, 'bookings', bookingId), {
      paymentStatus: 'paid',
      finalAmount: Math.round(amount * 100),
      stripeFinalPaymentId: paymentIntent.id,
      updatedAt: serverTimestamp(),
    });

    return NextResponse.json({
      success: true,
      paymentIntentId: paymentIntent.id,
      status: paymentIntent.status,
    });
  } catch (error) {
    console.error('Stripe charge-final error:', error);
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Payment failed' },
      { status: 500 }
    );
  }
}
