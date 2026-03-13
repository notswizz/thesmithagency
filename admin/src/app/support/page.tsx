export default function SupportPage() {
  return (
    <div style={{ margin: 0, padding: '40px 20px', background: '#0a0a0a', color: '#e0e0e0', fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif', lineHeight: 1.7, minHeight: '100vh' }}>
      <div style={{ maxWidth: 720, margin: '0 auto' }}>
        <h1 style={{ color: '#fff', fontSize: 28, marginBottom: 8 }}>Support</h1>
        <p style={{ color: '#888', fontSize: 14, marginBottom: 32 }}>The Smith Agency — TSA Portal</p>

        <p>Need help with the TSA Portal app? We&apos;re here to assist you.</p>

        <h2 style={{ color: '#ff1493', fontSize: 20, marginTop: 32, marginBottom: 12 }}>Contact Us</h2>
        <p>For questions, issues, or feedback about the app, please reach out to us at:</p>
        <p><strong>Email:</strong> <a href="mailto:lillian@thesmithagency.net" style={{ color: '#ff1493' }}>lillian@thesmithagency.net</a></p>

        <h2 style={{ color: '#ff1493', fontSize: 20, marginTop: 32, marginBottom: 12 }}>Common Questions</h2>

        <h3 style={{ color: '#fff', fontSize: 16, marginTop: 20, marginBottom: 8 }}>How do I sign in?</h3>
        <p>Staff members sign in using their Google account. Clients sign in with their email and password provided during onboarding.</p>

        <h3 style={{ color: '#fff', fontSize: 16, marginTop: 20, marginBottom: 8 }}>How do I update my profile?</h3>
        <p>Navigate to the Profile tab in the app to update your personal information, address, and other details.</p>

        <h3 style={{ color: '#fff', fontSize: 16, marginTop: 20, marginBottom: 8 }}>How do payments work?</h3>
        <p>Clients pay deposits and final charges through the app via Stripe. Staff members receive payments via direct deposit after completing their bookings.</p>

        <h3 style={{ color: '#fff', fontSize: 16, marginTop: 20, marginBottom: 8 }}>How do I delete my account?</h3>
        <p>To request account deletion, please email us at <a href="mailto:lillian@thesmithagency.net" style={{ color: '#ff1493' }}>lillian@thesmithagency.net</a> and we will process your request and remove your data.</p>

        <h2 style={{ color: '#ff1493', fontSize: 20, marginTop: 32, marginBottom: 12 }}>Privacy</h2>
        <p>Read our <a href="/privacy" style={{ color: '#ff1493' }}>Privacy Policy</a> to learn how we handle your data.</p>
      </div>
    </div>
  );
}
