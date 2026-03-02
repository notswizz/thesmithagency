"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.chargeClient = exports.createPaymentIntent = void 0;
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const stripe_1 = __importDefault(require("stripe"));
if (!admin.apps.length) {
    admin.initializeApp();
}
const db = admin.firestore();
function getStripe() {
    const key = process.env.STRIPE_SECRET_KEY;
    if (!key) {
        throw new https_1.HttpsError("failed-precondition", "Stripe secret key not configured");
    }
    return new stripe_1.default(key);
}
/**
 * Creates a PaymentIntent for a $100 deposit, with setup_future_usage
 * so the card is saved for off-session charges later.
 */
exports.createPaymentIntent = (0, https_1.onCall)(async (request) => {
    var _a;
    const { clientId, clientEmail, clientName, amount } = request.data;
    if (!clientId || !clientEmail || !amount) {
        throw new https_1.HttpsError("invalid-argument", "clientId, clientEmail, and amount are required");
    }
    const stripe = getStripe();
    const clientRef = db.collection("clients").doc(clientId);
    const clientDoc = await clientRef.get();
    if (!clientDoc.exists) {
        throw new https_1.HttpsError("not-found", "Client not found");
    }
    let stripeCustomerId = (_a = clientDoc.data()) === null || _a === void 0 ? void 0 : _a.stripeCustomerId;
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
    const ephemeralKey = await stripe.ephemeralKeys.create({ customer: stripeCustomerId }, { apiVersion: "2024-06-20" });
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
exports.chargeClient = (0, https_1.onCall)(async (request) => {
    var _a;
    const { clientId, amount, bookingId } = request.data;
    if (!clientId || !amount || !bookingId) {
        throw new https_1.HttpsError("invalid-argument", "clientId, amount, and bookingId are required");
    }
    const stripe = getStripe();
    const clientDoc = await db.collection("clients").doc(clientId).get();
    if (!clientDoc.exists) {
        throw new https_1.HttpsError("not-found", "Client not found");
    }
    const stripeCustomerId = (_a = clientDoc.data()) === null || _a === void 0 ? void 0 : _a.stripeCustomerId;
    if (!stripeCustomerId) {
        throw new https_1.HttpsError("failed-precondition", "Client has no saved payment method");
    }
    // Get saved payment methods
    const paymentMethods = await stripe.paymentMethods.list({
        customer: stripeCustomerId,
        type: "card",
    });
    if (paymentMethods.data.length === 0) {
        throw new https_1.HttpsError("failed-precondition", "No saved payment methods found for this client");
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
//# sourceMappingURL=stripe.js.map