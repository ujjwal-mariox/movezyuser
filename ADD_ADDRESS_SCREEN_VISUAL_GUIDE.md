# Add Address Screen - Visual Design Guide

## 🎨 User Interface Layout

```
┌─────────────────────────────────────┐
│        MAP SECTION (280px)          │
│  ┌───────────────────────────────┐  │
│  │  [Map Background Image]       │  │
│  │                               │  │
│  │       ⟲⟲⟲⟲                   │  │
│  │      ⟲   ◉ Location   ⟲       │  │  ← Ripple effect with
│  │     ⟲   [📍]  orange  ⟲       │  │     location pin
│  │  │   ◄─────────────── [Back] │  │
│  │                               │  │
│  └───────────────────────────────┘  │
├─────────────────────────────────────┤
│  WHITE FORM CARD (Rounded Corners)  │
│  ┌─────────────────────────────────┐│
│  │ Pick up from:                   ││
│  │ 📍 Coordinates (or set location)││
│  │                    [Change] {🔄} ││
│  ├─────────────────────────────────┤│
│  │ Full Name *                     ││
│  │ [👤 Enter your full name     ] ││
│  │                                 ││
│  │ Mobile Number *                 ││
│  │ [☎️  Enter 10-digit number    ] ││
│  │                                 ││
│  │ Save Address As:                ││
│  │ ◯ Home  ◯ Work  ◯ Other      ││
│  │                                 ││
│  │ House No / Flat No *            ││
│  │ [🏠 e.g., 123, Apt 4B        ] ││
│  │                                 ││
│  │ Area / Road Name *              ││
│  │ [📍 e.g., MG Road, Sector 5  ] ││
│  │                                 ││
│  │ City *          │ State *       ││
│  │ [📍 Bangalore] │ [🗺️ Karnataka]││
│  │                                 ││
│  │ Country *                       ││
│  │ [🌐 e.g., India              ] ││
│  │                                 ││
│  │ Pin Code *                      ││
│  │ [📮 e.g., 560001             ] ││
│  │                                 ││
│  │        ┌─────────────────────┐ ││
│  │        │  CONTINUE (Orange)  │ ││
│  │        └─────────────────────┘ ││
│  └─────────────────────────────────┘│
└─────────────────────────────────────┘
```

## 🎯 Interactive Elements

### Map Section
- **Ripple Animation**: Three concentric orange circles representing signal ripple
- **Location Pin**: Central solid orange circle with white location icon
- **Back Button**: White circular button with arrow icon (top-left)

### Pick Up From Section
- **Display**: Current location address or "Set your location"
- **Change Button**: Orange button to fetch GPS location
- **Loading State**: Spinner shows while fetching location

### Address Type Selector
- **Radio Style**: Three circular buttons for Home/Work/Other
- **Selection**: Orange border and background when selected
- **Behavior**: Disabled when editing existing address

### Form Fields
- **Input Icons**: Relevant icons before each field (person, phone, home, etc.)
- **Focus State**: Border highlight on focus
- **Error State**: Red error text below field if validation fails
- **Disabled State**: Gray text when field cannot be edited

### Continue Button
- **Normal**: Orange background, white text, full width
- **Loading**: Shows "Saving..." with disabled state
- **Edit Mode**: Text changes to "Update Address"

## 🌈 Color Palette

```
Primary Orange    #FF9800 (Location, buttons, highlights)
Background Gray   #F5F5F5 (Scaffold background)
Card White        #FFFFFF (Form container)
Light Gray        #F9F9F9 (Section backgrounds)
Border Gray       #E0E0E0 (Input borders, dividers)
Text Dark         #212121 (Primary text)
Text Gray         #757575 (Secondary labels)
Error Red         #D32F2F (Validation errors)
Success Green     #4CAF50 (Location set indicator)
```

## 📏 Dimensions

```
Map Height:                280px
Back Button:               40x40px
Location Pin:              40x40px (with ripple 80x80, 120x120)
Form Card:                 Margin top: 20px, Padding: 20px
Field Height:              ~48px (with label and padding)
Continue Button Height:    50px
Field Spacing:             16px (vertical), 12px (City/State gap)
Border Radius:
  - Form Card:             24px (top corners)
  - Fields:                8px
  - Change Button:         6px
  - Back Button:           50% (circle)
```

## ✨ Animations

1. **Ripple Effect** (Location Pin):
   - Subtle, non-animated background circles
   - Ready for animation enhancement

2. **Loading Spinner** (Change Button):
   - Circular progress indicator
   - Shows while fetching location

3. **Button States**:
   - Tap feedback (implicit with Flutter Material)
   - Loading state disables interaction
   - Success: Navigation transition

4. **Form Errors**:
   - Fade in error text on validation failure
   - Red text below affected field

## 🔐 Validation States

```
✅ Valid Input
- Green success indicator (location set)
- No error text visible
- Ready for submission

❌ Invalid Input
- Red error text visible below field
- Input remains focused
- Submit button disabled until fixed

⏳ Loading
- Button shows "Saving..."
- All inputs disabled
- Spinner animates
- Submit button disabled
```

## 📱 Mobile Considerations

- **Touch Targets**: All buttons ≥40px for easy tapping
- **Keyboard**: Smooth field navigation with Tab/Done keys
- **Scroll**: Form scrolls if content exceeds screen height
- **Orientation**: Responsive to portrait/landscape
- **Keyboard Overlap**: ScrollView accommodates keyboard

## 🎬 User Flow

1. **See Map**: User sees location visualization
2. **Set Location**: Tap "Change" button → GPS permission → Location fetched
3. **Fill Form**: Enter all required details
4. **Select Type**: Choose Home/Work/Other for address type
5. **Validate**: All fields validated before submission
6. **Submit**: Tap "Continue" → API call → Success/Error message
7. **Return**: Navigate back to saved addresses list

## 🔄 Edit Mode Differences

When editing an existing address:

```
✅ Can Edit           ❌ Cannot Edit
─────────────────────────────────────
House No / Flat No    Full Name
Area / Road Name      Mobile Number
City                  Country
State                 Address Type
Pin Code              
Location (Change)
```

- Button text: "Update Address" instead of "Continue"
- Pre-filled fields: Show existing values
- Disabled fields: Grayed out with strikethrough appearance

---

## 🎨 Design Pattern: Material 3 Compatibility

The design follows Material Design 3 principles:
- ✅ Clear visual hierarchy
- ✅ Consistent spacing and padding
- ✅ Intuitive interactive elements
- ✅ Accessible color contrast
- ✅ Responsive layout
- ✅ Smooth transitions

---

**File**: `lib/Screens/SavedAddress/add_address_screen.dart` (352 lines)  
**Status**: ✅ Implementation Complete
