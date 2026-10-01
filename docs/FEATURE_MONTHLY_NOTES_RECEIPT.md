# Feature Implementation: Monthly Notes & Receipt Photo

## Overview
Two new features for KASEP cash flow app:
1. **Monthly Notes** - Journal/notes per month for financial reflections
2. **Receipt Photo** - Attach photo evidence to transactions

---

## Feature 1: Monthly Notes

### Description
A monthly journal feature where users can:
- Write financial reflections for each month
- Set goals for next month
- Review past months' notes
- Track spending habits and insights

### UI/UX Design
- Access from Home Screen header (new icon button)
- Full-screen editor with month selector
- Card-based preview on home (optional)
- Matches existing theme (eucalyptus green accent, rounded corners)

### Database Schema
```sql
CREATE TABLE monthly_notes (
  id TEXT PRIMARY KEY,
  year INTEGER NOT NULL,
  month INTEGER NOT NULL,
  content TEXT NOT NULL,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL,
  UNIQUE(year, month)
)
```

### Files to Create/Modify
1. `lib/models/monthly_note.dart` - Data model
2. `lib/core/storage/monthly_note_repository.dart` - CRUD operations
3. `lib/core/storage/database_helper.dart` - Add table & migration
4. `lib/features/monthly_notes/screens/monthly_notes_screen.dart` - Main screen
5. `lib/features/home/screens/home_screen.dart` - Add access button

---

## Feature 2: Receipt Photo Attachment

### Description
Attach receipt photos to transactions:
- Take photo or pick from gallery
- Store locally in app directory
- View photo in transaction details
- Delete photo option

### Database Changes
Add column to transactions table:
```sql
ALTER TABLE transactions ADD COLUMN receiptPath TEXT
```

### Files to Create/Modify
1. `lib/models/transaction.dart` - Add receiptPath field
2. `lib/core/storage/database_helper.dart` - Migration v5
3. `lib/core/storage/transaction_repository.dart` - Handle receipt path
4. `lib/features/transactions/screens/add_transaction_screen.dart` - Add photo button
5. `lib/features/transactions/screens/edit_transaction_screen.dart` - View/edit photo
6. `lib/features/transactions/widgets/receipt_photo_picker.dart` - Reusable widget

---

## Implementation Steps

### Step 1: Database Changes
- [x] Add monthly_notes table
- [x] Add receiptPath column to transactions
- [x] Create migration v5

### Step 2: Models
- [x] Create MonthlyNote model
- [x] Update Transaction model with receiptPath

### Step 3: Repositories
- [x] Create MonthlyNoteRepository
- [x] Update TransactionRepository for receipt

### Step 4: Monthly Notes UI
- [x] Create MonthlyNotesScreen
- [x] Add month selector
- [x] Rich text editor area
- [x] Save/auto-save functionality
- [x] Add access from home screen

### Step 5: Receipt Photo UI
- [x] Create ReceiptPhotoPicker widget
- [x] Integrate in AddTransactionScreen
- [x] Integrate in EditTransactionScreen
- [x] Full-screen photo viewer
- [x] Delete photo option

### Step 6: Testing & Polish
- [ ] Test on device
- [ ] Handle edge cases
- [ ] Performance optimization

---

## Design Specifications

### Colors (from app_colors.dart)
- Primary Accent: `#147D68` (eucalyptus green)
- Secondary Accent: `#F0A35E` (warm clay)
- Background: `#F7F8FA`
- Surface: `#FFFFFF`
- Text: `#17211D`

### Border Radius
- Cards: 16-20px
- Buttons: 12-16px
- Chips: 20px (pill shape)

### Shadows
- Cards: subtle, 0.1-0.2 opacity
- Elevated: 10-20 blur, accent color tint

### Typography
- Headers: Roboto Bold, 16-24px
- Body: Roboto Regular, 13-15px
- Labels: Roboto Medium, 10-12px, letter-spacing 1.2

---

## Progress Tracking

| Task | Status | Date |
|------|--------|------|
| Database schema design | Done | 2026-09-23 |
| MonthlyNote model | Done | 2026-09-23 |
| Transaction model update | Done | 2026-09-23 |
| Database migration (v5) | Done | 2026-09-23 |
| MonthlyNoteRepository | Done | 2026-09-23 |
| MonthlyNotesScreen | Done | 2026-09-23 |
| ReceiptPhotoPicker widget | Done | 2026-09-23 |
| AddTransactionScreen update | Done | 2026-09-23 |
| EditTransactionScreen update | Done | 2026-09-23 |
| Home screen integration | Done | 2026-09-23 |
| Testing | Pending | - |

---

## Notes
- Receipt photos stored in app documents directory
- File naming: `receipt_{transactionId}.jpg`
- Max image size: 1024x1024, quality 85%
- Monthly notes auto-save on text change (debounced)

---

## UI Improvements

### Export Screen - Period Picker (Redesigned)

**Before:** Simple list with 12 months for current year only

**After:**
- Visual 4x3 month grid for easy selection
- Year selector with left/right arrows
- Tap year to show year picker (last 10 years)
- Current month highlighted with accent border + dot
- Selected month filled with accent color
- Future months disabled (grayed out)
- Quick buttons: "Bulan Ini" and "Bulan Lalu"
- Smooth animations on selection
- Modern rounded card design
