# KisanSetu (కిసాన్ సేతు / किसान सेतु)
> **"Less Waiting. More Transparency."**
> A production-ready full-stack Progressive Web App (PWA) connecting farmers with government procurement centres (FCI, Markfed, PACS) and local IKP (Indira Kranthi Patham) centres with real-time queues, smart recommendations, digital token scheduling, and end-to-end procurement tracking.

---

## 🌾 Highlights & Key Capabilities

1. **Single-File Zero-Dependency Architecture (`index.html`)**:
   - Ready to run immediately on any machine with Python or by opening `index.html` directly in modern web browsers.
   - Built with React 18, Tailwind CSS, Leaflet OpenStreetMap, Lucide Icons, and Web Speech Voice APIs.
   - Deployable in seconds to Vercel, Netlify, Cloudflare Pages, or GitHub Pages.

2. **Full-Spectrum Farmer Workflow**:
   - **Mobile OTP Login**: Enter mobile number (`9848022338`), receive SMS verification code.
   - **Mandatory Land Passbook Verification**: Validates Pattadar Passbook, Survey Number, and Khata number through simulated Dharani/Meebhoomi RoR Government API gateway.
   - **Crop Produce Registration**: Locked until land is verified. Features official 2025-26 MSP rates (Paddy Grade A ₹2320/qtl, Cotton ₹7121/qtl, Wheat, Maize, etc.).
   - **Smart Recommendation Engine**: Evaluates distance + queue load + wait time + open capacity across major FCI godowns, Markfed yards, and local **IKP centres**.
   - **Digital Token & QR Pass**: Visual QR code pass, slot reservation, and vehicle registration.
   - **Live Queue & Waiting Estimation**: Real-time counter of farmers ahead and dynamic arrival advisories.
   - **10-Stage Procurement Tracking**:
     1. Registered → 2. Land Verified → 3. Crop Registered → 4. Token Generated → 5. Arrived at Gate → 6. Quality Check (Moisture % & Grade) → 7. Weighbridge Slip → 8. Procured → 9. Payment Processing → 10. Direct Benefit Transfer (DBT) Paid.
   - **Payment Breakdown**: Gross valuation, moisture discount guard (FAQ limit 17%), and Bank DBT UTR record.

3. **Officer Terminal**:
   - Live queue dispatching: Call Next, Mark Arrived, Skip, Pause/Resume line.
   - Quality inspection terminal: Moisture meter (FAQ threshold 17%), foreign matter %, FAQ grading (Grade A / Common).
   - Electronic weighbridge terminal: Gross, Tare, and Net Quintals calculation with digital weight slip (`WSP-2026-TG-XXXX`).
   - Broadcaster for emergency centre announcements.

4. **District Admin Dashboard**:
   - Multi-centre grid monitoring (FCI, Markfed, PACS, and local IKP centres).
   - Real-time overcrowding alerts (>80% capacity yellow alert, >95% red alert).
   - Analytics metrics: Daily tonnage, average wait times (reduced by 68%), and DBT disbursement status.
   - Immutable audit trail.

5. **Multilingual & Voice AI Assistant**:
   - **3 Languages**: English, తెలుగు (Telugu), हिन्दी (Hindi) with instant switcher.
   - **Browser Voice Assistant**: Web Speech API speech recognition and text-to-speech audio feedback.
     - *"Check my token" / "నా టోకెన్ చూడండి" / "मेरा टोकन दिखाओ"*
     - *"How many farmers are ahead?" / "నా ముందు ఎంతమంది రైతులు ఉన్నారు?" / "मेरे आगे कितने किसान हैं?"
     - *"Find nearest centre" / "సమీప కేంద్రాన్ని చూపించు" / "निकटतम केंद्र खोजें"*
     - *"Show today's schedule" / "ఈరోజు షెడ్యూల్ చూపించు" / "आज का शेड्यूल दिखाओ"*
     - *"Check procurement status" / "సేకరణ స్థితి ఎలా ఉంది?" / "खरीद की स्थिति जांचें"*
   - **KisanSetu AI Assistant**: Specialized conversational drawer answering questions based on live authenticated farmer state.

6. **Farmer Mobile SMS History**:
   - Real-time simulated SMS drawer with timestamps sent to the farmer's registered phone number.

7. **Production PostgreSQL / Supabase Schema (`supabase_schema.sql`)**:
   - 18 normalized tables with Row Level Security (RLS) policies and official MSP seed data.

---

## 🚀 Quick Start Instructions

### Option 1: Run with Python Local Server (Recommended)
Open PowerShell or Terminal in this folder and run:
```powershell
python -m http.server 3000
```
Then visit:
👉 **[http://localhost:3000](http://localhost:3000)**

### Option 2: Direct Browser Open
Simply double-click `index.html` in Windows File Explorer or open with Google Chrome, Microsoft Edge, or Firefox.

### Option 3: Deploy to Vercel or Netlify
Because the app is self-contained in `index.html`, `manifest.json`, and `sw.js`:
- Drag-and-drop this folder into **Netlify Drop** ([app.netlify.com/drop](https://app.netlify.com/drop)), OR
- Push to GitHub and deploy with 0 configuration on **Vercel** or **GitHub Pages**.

---

## 🗄️ Supabase Database Setup

To link to a live Supabase project:
1. Create a project at [supabase.com](https://supabase.com).
2. Go to the **SQL Editor** tab in your Supabase dashboard.
3. Copy and paste the contents of `supabase_schema.sql` and run it.
4. In the KisanSetu app, click the **Supabase** button in the top navigation bar to enter your Project URL and Anon Key.
