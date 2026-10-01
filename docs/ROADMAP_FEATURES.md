# KASEP - Feature Roadmap

## Priority Features

### 1. Monthly Budget Target (HIGH PRIORITY)
Set spending limits per category and track progress.

**Features:**
- Set budget per category (e.g., Makan: Rp 2.000.000)
- Progress bar showing spent vs budget
- Alert when reaching 80%, 100%
- Historical analysis: Compare target vs average spending
- Realistic goal indicator
- Carry over unused budget (optional)

**Database:**
```sql
CREATE TABLE budgets (
  id TEXT PRIMARY KEY,
  category TEXT NOT NULL,
  amount INTEGER NOT NULL,
  month INTEGER NOT NULL,
  year INTEGER NOT NULL,
  createdAt TEXT NOT NULL,
  UNIQUE(category, month, year)
)
```

**UI Components:**
- Budget setup screen (category grid with amount input)
- Budget progress cards on home screen
- Budget summary in reports

---

### 2. Recurring Transactions
Auto-record monthly expenses.

**Features:**
- Create recurring templates (title, amount, category, frequency)
- Frequency: daily, weekly, monthly, yearly
- Auto-create transactions on schedule
- Reminder before posting
- Skip/edit individual occurrences

**Use Cases:**
- Netflix, Spotify subscriptions
- Rent, utilities, internet bills
- Salary income on specific dates

---

### 3. Savings Goals
Track progress toward specific targets.

**Features:**
- Create goals with target amount and deadline
- Link to specific fund source
- Track progress with percentage
- Milestone celebrations (25%, 50%, 75%, 100%)
- Contribution history

**Examples:**
- "Liburan Bali - Rp 5.000.000 by Dec 2024"
- "Emergency Fund - Rp 10.000.000"
- "iPhone 16 - Rp 20.000.000"

---

### 4. Bill Reminders
Never miss payment due dates.

**Features:**
- Set recurring bills with due dates
- Notification 1-3 days before due
- One-tap "Mark as Paid" → creates transaction
- Overdue alerts
- Bill history

---

### 5. Spending Insights & Alerts
Smart notifications and analysis.

**Features:**
- "You spent 40% more on transport this week"
- "Unusual large transaction detected"
- Weekly/monthly spending summary notification
- Category trend analysis
- Spending predictions

---

## Implementation Priority

| # | Feature | Effort | Impact | Status |
|---|---------|--------|--------|--------|
| 1 | Monthly Budget Target | Medium | High | 🔜 Next |
| 2 | Recurring Transactions | Medium | High | Planned |
| 3 | Savings Goals | Medium | Medium | Planned |
| 4 | Bill Reminders | Low | Medium | Planned |
| 5 | Spending Insights | High | High | Future |

---

## Completed Features

- [x] Transaction management (income/expense)
- [x] Fund sources with balance tracking
- [x] Transfer between fund sources
- [x] Monthly reports & analysis
- [x] PDF/CSV export
- [x] Monthly notes journal
- [x] Receipt photo attachment
- [x] Biometric authentication
- [x] Category breakdown charts

---

## Technical Notes

- Database version: 5 (current)
- Next migration: v6 for budgets table
- Notification package needed for reminders
- Background service for recurring transactions
