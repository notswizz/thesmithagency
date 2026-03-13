export default function PrivacyPage() {
  return (
    <div style={{ margin: 0, padding: '40px 20px', background: '#0a0a0a', color: '#e0e0e0', fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif', lineHeight: 1.7, minHeight: '100vh' }}>
      <div style={{ maxWidth: 720, margin: '0 auto' }}>
        <h1 style={{ color: '#fff', fontSize: 28, marginBottom: 8 }}>Privacy Policy</h1>
        <p style={{ color: '#888', fontSize: 14, marginBottom: 32 }}>Last updated: March 12, 2026</p>

        <p>The Smith Agency (&ldquo;we&rdquo;, &ldquo;us&rdquo;, or &ldquo;our&rdquo;) operates the TSA Portal mobile application (the &ldquo;App&rdquo;). This Privacy Policy explains how we collect, use, disclose, and protect your personal information when you use our App.</p>

        <H2>1. Information We Collect</H2>

        <H3>Account Information</H3>
        <p>When you create an account, we collect:</p>
        <ul>
          <li><strong>Name and email address</strong> — provided directly or via Google Sign-In</li>
          <li><strong>Phone number</strong></li>
        </ul>

        <H3>Staff Profile Data</H3>
        <p>If you register as a staff member, we additionally collect:</p>
        <ul>
          <li>Physical address and city/location</li>
          <li>College or university</li>
          <li>Dress size, shoe size, and height</li>
          <li>Instagram handle</li>
          <li>Retail and wholesale experience level</li>
          <li>Skills</li>
          <li>Resume (uploaded file)</li>
          <li>Headshot photo</li>
        </ul>

        <H3>Staff Banking Information</H3>
        <p>To process direct deposit payments, we collect:</p>
        <ul>
          <li>Bank account holder name</li>
          <li>Bank routing number</li>
          <li>Bank account number</li>
          <li>Bank account type</li>
        </ul>

        <H3>Client Business Data</H3>
        <p>If you register as a client, we collect:</p>
        <ul>
          <li>Company name and website</li>
          <li>Contact person details (name, email, phone, role)</li>
          <li>Showroom addresses (city, building, floor, booth)</li>
        </ul>

        <H3>Payment Information</H3>
        <p>When you make a payment, your payment card details are collected and processed securely by Stripe. We do not store your full card number, CVV, or expiration date on our servers. We retain only a Stripe customer ID and payment intent ID for transaction records.</p>

        <H3>Automatically Collected Information</H3>
        <p>We collect crash reports and diagnostic data through Firebase Crashlytics to identify and fix bugs. This may include device type, operating system version, and crash logs. We do not collect analytics or usage tracking data.</p>

        <H2>2. How We Use Your Information</H2>
        <ul>
          <li>To create and manage your account</li>
          <li>To facilitate bookings between clients and staff</li>
          <li>To process client payments and deposits via Stripe</li>
          <li>To pay staff via direct deposit</li>
          <li>To communicate about bookings, schedules, and availability</li>
          <li>To diagnose crashes and improve app stability</li>
          <li>To enforce our Terms and Conditions</li>
        </ul>

        <H2>3. How We Share Your Information</H2>
        <p>We do not sell, rent, or trade your personal information. We share data only with the following third-party service providers, solely to operate our App:</p>
        <ul>
          <li><strong>Google Firebase</strong> — Authentication (Google Sign-In for staff, email/password for clients), cloud database (Firestore), file storage (Cloud Storage), crash reporting (Crashlytics), and cloud functions. <a href="https://firebase.google.com/support/privacy" style={{ color: '#ff1493' }}>Firebase Privacy Policy</a></li>
          <li><strong>Stripe</strong> — Payment processing for deposits, final charges, and cancellation fees. Stripe receives your name, email, and payment card details. <a href="https://stripe.com/privacy" style={{ color: '#ff1493' }}>Stripe Privacy Policy</a></li>
          <li><strong>Apple MapKit</strong> — Address autocomplete when entering showroom or staff addresses. Apple may receive partial address queries. <a href="https://www.apple.com/legal/privacy/" style={{ color: '#ff1493' }}>Apple Privacy Policy</a></li>
        </ul>
        <p>We may also disclose your information if required by law or to protect our legal rights.</p>

        <H2>4. Data Storage and Security</H2>
        <p>Your data is stored in Google Firebase&apos;s cloud infrastructure in the United States. Firebase provides encryption at rest and in transit. Banking information is stored in our secured Firestore database with access restricted to authorized personnel. Payment card data is handled entirely by Stripe&apos;s PCI-compliant infrastructure and is never stored on our servers.</p>
        <p>While we implement appropriate technical and organizational measures to protect your personal information, no method of electronic storage is 100% secure.</p>

        <H2>5. Data Retention</H2>
        <p>We retain your personal information for as long as your account is active or as needed to provide our services. Booking and payment records may be retained for up to seven years to comply with financial record-keeping requirements. You may request deletion of your account and associated personal data at any time by contacting us.</p>

        <H2>6. Your Rights</H2>
        <p>You have the right to:</p>
        <ul>
          <li>Access the personal data we hold about you</li>
          <li>Request correction of inaccurate data</li>
          <li>Request deletion of your account and data</li>
          <li>Withdraw consent for data processing</li>
          <li>Request a copy of your data in a portable format</li>
        </ul>
        <p>To exercise any of these rights, please contact us using the details below.</p>

        <H2>7. Tracking and Advertising</H2>
        <p>We do not track you across other apps or websites. We do not use advertising identifiers. We do not serve ads in the App. Firebase Analytics is disabled.</p>

        <H2>8. Children&apos;s Privacy</H2>
        <p>Our App is not directed to individuals under the age of 18. We do not knowingly collect personal information from children. If we learn that we have collected data from a child under 18, we will delete it promptly.</p>

        <H2>9. Changes to This Policy</H2>
        <p>We may update this Privacy Policy from time to time. We will notify you of material changes by posting the updated policy in the App and updating the &ldquo;Last updated&rdquo; date above. Your continued use of the App after changes are posted constitutes your acceptance of the revised policy.</p>

        <H2>10. Contact Us</H2>
        <p>If you have questions about this Privacy Policy, wish to exercise your data rights, or have concerns about how your information is handled, please contact us at:</p>
        <p><strong>The Smith Agency</strong><br />
        Email: <a href="mailto:privacy@thesmithagency.com" style={{ color: '#ff1493' }}>privacy@thesmithagency.com</a></p>
      </div>
    </div>
  );
}

function H2({ children }: { children: React.ReactNode }) {
  return <h2 style={{ color: '#ff1493', fontSize: 20, marginTop: 32, marginBottom: 12 }}>{children}</h2>;
}

function H3({ children }: { children: React.ReactNode }) {
  return <h3 style={{ color: '#fff', fontSize: 16, marginTop: 20, marginBottom: 8 }}>{children}</h3>;
}
