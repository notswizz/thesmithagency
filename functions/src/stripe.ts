import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import Stripe from "stripe";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

function getStripe(): Stripe {
  const key = process.env.STRIPE_SECRET_KEY;
  if (!key) {
    throw new HttpsError("failed-precondition", "Stripe secret key not configured");
  }
  return new Stripe(key);
}

/**
 * Creates a PaymentIntent for a $100 deposit, with setup_future_usage
 * so the card is saved for off-session charges later.
 */
export const createPaymentIntent = onCall(async (request) => {
  const { clientId, clientEmail, clientName, amount } = request.data as {
    clientId: string;
    clientEmail: string;
    clientName: string;
    amount: number;
  };

  if (!clientId || !clientEmail || !amount) {
    throw new HttpsError(
      "invalid-argument",
      "clientId, clientEmail, and amount are required"
    );
  }

  const stripe = getStripe();
  const clientRef = db.collection("clients").doc(clientId);
  const clientDoc = await clientRef.get();

  if (!clientDoc.exists) {
    throw new HttpsError("not-found", "Client not found");
  }

  let stripeCustomerId = clientDoc.data()?.stripeCustomerId as
    | string
    | undefined;

  // Create Stripe customer if one doesn't exist yet
  if (!stripeCustomerId) {
    const customer = await stripe.customers.create({
      email: clientEmail,
      name: clientName || undefined,
      metadata: { firebaseClientId: clientId },
    });
    stripeCustomerId = customer.id;
    await clientRef.update({ stripeCustomerId });
  }

  // Create ephemeral key for the mobile SDK
  const ephemeralKey = await stripe.ephemeralKeys.create(
    { customer: stripeCustomerId },
    { apiVersion: "2024-06-20" }
  );

  // Create PaymentIntent with setup_future_usage to save the card
  const paymentIntent = await stripe.paymentIntents.create({
    amount,
    currency: "usd",
    customer: stripeCustomerId,
    setup_future_usage: "off_session",
    automatic_payment_methods: { enabled: true },
    metadata: {
      clientId,
      bookingType: "deposit",
    },
  });

  return {
    clientSecret: paymentIntent.client_secret,
    customerId: stripeCustomerId,
    ephemeralKey: ephemeralKey.secret,
    paymentIntentId: paymentIntent.id,
  };
});

/**
 * Charges a client's saved payment method off-session for the final balance.
 */
export const chargeClient = onCall(async (request) => {
  const { clientId, amount, bookingId } = request.data as {
    clientId: string;
    amount: number;
    bookingId: string;
  };

  if (!clientId || !amount || !bookingId) {
    throw new HttpsError(
      "invalid-argument",
      "clientId, amount, and bookingId are required"
    );
  }

  const stripe = getStripe();
  const clientDoc = await db.collection("clients").doc(clientId).get();

  if (!clientDoc.exists) {
    throw new HttpsError("not-found", "Client not found");
  }

  const stripeCustomerId = clientDoc.data()?.stripeCustomerId as
    | string
    | undefined;

  if (!stripeCustomerId) {
    throw new HttpsError(
      "failed-precondition",
      "Client has no saved payment method"
    );
  }

  // Get saved payment methods
  const paymentMethods = await stripe.paymentMethods.list({
    customer: stripeCustomerId,
    type: "card",
  });

  if (paymentMethods.data.length === 0) {
    throw new HttpsError(
      "failed-precondition",
      "No saved payment methods found for this client"
    );
  }

  const paymentMethod = paymentMethods.data[0];

  // Charge the saved card off-session
  const paymentIntent = await stripe.paymentIntents.create({
    amount,
    currency: "usd",
    customer: stripeCustomerId,
    payment_method: paymentMethod.id,
    off_session: true,
    confirm: true,
    automatic_payment_methods: {
      enabled: true,
      allow_redirects: "never",
    },
    metadata: {
      clientId,
      bookingId,
      bookingType: "final",
    },
  });

  // Update booking in Firestore
  await db.collection("bookings").doc(bookingId).update({
    paymentStatus: "paid",
    finalAmount: amount,
    stripeFinalPaymentId: paymentIntent.id,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    success: true,
    paymentIntentId: paymentIntent.id,
    status: paymentIntent.status,
  };
});
