# Privacy Policy

**Last Updated: June 27, 2026**

This privacy policy governs your use of the software application **AI Expense Tracker** (hereinafter referred to as the "App"), created by **Setups Works** (developed by **Nitheesh Rajendran**). 

The App is designed as an offline-first, privacy-respecting personal finance manager that automates expense tracking. We are committed to protecting your personal information and your privacy.

---

## 1. Information Collection and Usage

### A. SMS Permissions (Sensitive Data Access)
To automate your expense tracking, the App requests permission to read and receive SMS messages (`READ_SMS` and `RECEIVE_SMS`). 
* **Scope of Access**: The App scans your incoming SMS messages to identify transaction, debit, credit, and account balance notifications from your financial institutions.
* **On-Device Processing**: All SMS parsing is performed **entirely on your local device**.
* **Zero Upload Policy**: Your raw SMS messages, transaction details, and financial logs are stored in a local SQLite database on your device. **We do not collect, transmit, upload, or share your SMS messages or financial data to any external servers or third parties.**
* **OTP & Spam Protection**: The App ignores security one-time passwords (OTPs), promotional alerts, and personal chats.

### B. Personal and Financial Information
All financial records, categorized budgets, savings goals, and subscriptions are managed locally on your device. 
* We do not have databases or servers that store your personal account details, balances, or transactions.
* If you delete the App, all locally stored financial records are permanently deleted from your device.

### C. AI Assistant (Aria)
The App features an optional AI-powered assistant (Aria) to analyze your spending. 
* To use Aria, you can optionally provide your own Groq API key.
* The API key is stored securely in your device's hardware-backed encrypted storage.
* Conversation prompts and selected local spending categories are sent directly to the AI service provider (Groq) for processing. No personal identifiers (like names or account numbers) are included in these requests.

---

## 2. Third-Party Services

The App integrates the following third-party software development kits (SDKs) which may collect information under their own privacy policies:

### Google AdMob (Google Mobile Ads)
The App uses Google AdMob to display advertisements. Google may collect and use information such as:
* Your device's advertising identifier (e.g., Android Advertising ID).
* Device characteristics (manufacturer, model, OS version, language).
* IP address (for location-based ad targeting).
* You can manage ad personalization settings via your device's settings menu (e.g., "Google > Ads > Opt out of Ads Personalization").
* **Link to Google Play Services Privacy Policy**: [Google Privacy & Terms](https://policies.google.com/privacy)

---

## 3. Data Retention and Deletion
* **Local Data**: Since all data is stored locally on your device's SQLite storage, you can delete your data at any time by clearing the App's cache/storage in your Android settings or by uninstalling the App.
* **No Account Registration**: The App does not require account creation, logins, or profiles, meaning we do not store any user accounts.

---

## 4. Children’s Privacy
The App does not address anyone under the age of 13. We do not knowingly collect personally identifiable information from children under 13. In the case we discover that a child under 13 has provided us with personal information, we immediately delete this from our local caches (if any).

---

## 5. Changes to This Privacy Policy
We may update our Privacy Policy from time to time. You are advised to review this page periodically for any changes. We will notify you of any changes by updating the "Last Updated" date at the top of this Privacy Policy.

---

## 6. Contact Us
If you have any questions or suggestions about this Privacy Policy, please contact us at:
* **Developer**: Nitheesh Rajendran / Setups Works
* **Email**: nitheeshdr@gmail.com
* **GitHub Repository**: [nitheeshdr/AI-Expense-Tracker-App](https://github.com/nitheeshdr/AI-Expense-Tracker-App)
