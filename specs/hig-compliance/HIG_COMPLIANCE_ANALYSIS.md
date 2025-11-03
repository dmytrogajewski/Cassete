# GNOME HIG Compliance Analysis for Cassette

This document analyzes the Cassette application's compliance with the GNOME Human Interface Guidelines (HIG).

## Executive Summary

The application generally follows GNOME HIG principles but has several areas that need improvement for full compliance. Overall compliance: **~70%**.

---

## Design Principles

### ✅ Compliance
- **Make it Simple**: The app focuses on music playback with a clear, focused interface
- **Reduce User Effort**: Automatic caching, intuitive navigation, and clear visual feedback

### ⚠️ Areas for Improvement
- Some custom styling may reduce compatibility with accessibility features
- Some complex operations could benefit from more progressive disclosure

---

## UI Styling & Visual Design

### ✅ Compliance
- Uses Adwaita (libadwaita) as the base style
- Supports light and dark themes through system settings
- Uses standard GTK/Adwaita widgets

### ❌ Issues Found

1. **Custom Styling Overuse** (`data/style.css`)
   - Extensive custom CSS that may conflict with system themes
   - Custom gradients and backgrounds (e.g., `.plus-button` with gradient background)
   - Custom border-radius values that may not match HIG standards
   - Recommendation: Minimize custom styling; use Adwaita's built-in style options

2. **Color Usage**
   - Uses custom accent colors and gradients
   - The `.plus-button` uses a custom gradient background which may not respect high-contrast mode
   - Recommendation: Use system accent colors and test with high-contrast mode

3. **Hard-coded Styles**
   - Border radius values (12px, 6px) instead of using system defaults
   - Custom padding values that may not scale properly
   - Recommendation: Use Adwaita's standard spacing and sizing

---

## Accessibility

### ✅ Compliance
- Uses standard GTK widgets which provide basic accessibility
- Some tooltips are implemented (`tooltip-text` properties found)
- Keyboard navigation appears to be functional with actions

### ❌ Critical Issues

1. **Missing Accessible Names**
   - No explicit `accessible-name` or `accessible-label` properties found for custom widgets
   - Custom widgets like `TrackRow`, `PlayerBar`, etc. may not have descriptive names for screen readers
   - Recommendation: Add `accessible-name` properties to all interactive widgets

2. **Keyboard Shortcuts Help Overlay**
   - Menu references `win.show-help-overlay` action (line 28 in `primary-menu-button.vala`)
   - Action not implemented in `window.vala` ACTION_ENTRIES
   - Recommendation: Implement `show-help-overlay` action with `Adw.ShortcutsWindow`

3. **Focus Indicators**
   - Need to verify that all interactive elements have visible focus indicators
   - Custom styled elements may not show focus properly
   - Recommendation: Test keyboard navigation and ensure focus is visible

4. **High-Contrast Mode Testing**
   - Custom CSS may not work correctly in high-contrast mode
   - Recommendation: Test with high-contrast mode enabled

5. **Large Text Mode**
   - Custom padding and sizing may not scale with large text mode
   - Recommendation: Use relative units and test with large text mode

---

## Keyboard Navigation & Shortcuts

### ✅ Compliance
- Standard shortcuts implemented:
  - `<primary>q` - Quit
  - `space` - Play/Pause
  - `<Alt>Left/Right` - Previous/Next track
  - `<Ctrl>s` - Change shuffle
  - `<Ctrl>r` - Change repeat
- Actions are properly defined using `ActionEntry[]`
- Shortcuts are discoverable through the primary menu

### ⚠️ Issues

1. **Missing Standard Shortcuts**
   - No `Ctrl+F` for search (if search exists)
   - No `Ctrl+W` for close window
   - No `Ctrl+N` for new playlist (if applicable)
   - Recommendation: Implement standard GNOME shortcuts where applicable

2. **Text Input Interference**
   - Code at line 154-159 in `application.vala` shows workaround for space key interfering with text input
   - This suggests potential keyboard navigation issues
   - Recommendation: Review focus handling for text inputs

---

## Navigation Patterns

### ✅ Compliance

1. **Sidebar Navigation**
   - Uses `Adw.OverlaySplitView` for sidebar (complies with HIG)
   - Sidebar can be collapsed/expanded
   - Clear labels and icons
   - Keyboard accessible (via sidebar navigation)

2. **Header Bars**
   - Uses `Adw.HeaderBar` in sidebar
   - Contains primary menu button
   - Window controls properly positioned

3. **Main Navigation**
   - View switcher pattern appears to be implemented
   - Uses standard navigation patterns

### ⚠️ Areas for Improvement
- Verify that sidebar navigation fully supports keyboard-only navigation
- Ensure sidebar works correctly in adaptive layouts (mobile/tablet)

---

## Dialogs & Feedback

### ✅ Compliance

1. **Preferences Dialog**
   - Uses `AdwPreferencesDialog` (standard HIG pattern)
   - Properly organized with pages and groups
   - Uses `AdwSwitchRow` for toggles (correct pattern)
   - Clear titles and descriptions

2. **Alert Dialogs**
   - Uses `Adw.AlertDialog` for confirmations (destructive actions)
   - Properly styled destructive buttons (`Adw.ResponseAppearance.DESTRUCTIVE`)
   - Default and close responses set appropriately
   - Examples: cache deletion, logout confirmations

3. **Toasts**
   - Uses `Adw.Toast` for non-critical messages
   - Auto-dismissing behavior
   - Non-intrusive placement

4. **About Dialog**
   - Uses `Adw.AboutDialog` (standard pattern)
   - Includes proper credits and links

### ⚠️ Issues

1. **Dialog Spacing**
   - Some dialogs may not follow standard spacing guidelines
   - Recommendation: Verify margins and padding match HIG recommendations

2. **Dialog Accessibility**
   - Ensure all dialogs can be dismissed with Escape key (appears to be implemented)
   - Verify keyboard navigation within dialogs

---

## Controls & Widgets

### ✅ Compliance

1. **Buttons**
   - Uses appropriate button styles (flat, circular, etc.)
   - Proper use of `Gtk.Button` with icons
   - Tooltips provided where appropriate

2. **Switches**
   - Uses `AdwSwitchRow` in preferences (correct pattern)
   - Clear labels and descriptions
   - Immediate effect (as per HIG)

3. **Menus**
   - Uses `Adw.PopoverMenu` pattern
   - Organized menu items
   - Keyboard navigable

### ⚠️ Issues

1. **Button Labels**
   - Some icon-only buttons may need better accessible labels
   - Recommendation: Ensure all icon buttons have tooltips and accessible names

2. **Custom Controls**
   - Custom widgets (TrackRow, PlayerBar, etc.) should be verified for accessibility
   - Recommendation: Add comprehensive accessible descriptions

---

## Lists & Views

### ✅ Compliance
- Uses standard list patterns
- Visual feedback for selected/active items
- Clear visual hierarchy

### ⚠️ Issues

1. **List Accessibility**
   - Verify keyboard navigation in lists (arrow keys, Enter, etc.)
   - Ensure screen readers can navigate list items properly

2. **Track Rows**
   - Custom `TrackRow` widget needs accessibility attributes
   - Recommendation: Add `accessible-name` based on track info (title, artist)

---

## Typography

### ✅ Compliance
- Uses system fonts (default GTK behavior)
- Uses semantic labels (`caption`, `dim-label` CSS classes)
- Text is not overlaid on complex backgrounds

### ⚠️ Issues

1. **Font Styles**
   - Some custom CSS classes (`.unbold`, `.menu-button`) override default weights
   - Recommendation: Use standard Adwaita font styles where possible

2. **Unicode Usage**
   - Verify proper Unicode characters are used (quotes, ellipses, etc.)
   - Recommendation: Review strings for proper Unicode characters

---

## Player Bar

### ✅ Compliance
- Uses bottom bar pattern (`Adw.ToolbarView` with bottom bar)
- Standard playback controls
- Clear visual feedback

### ⚠️ Issues

1. **Custom Styling**
   - Player bar uses custom Grid layout
   - Custom spacing and margins
   - Recommendation: Verify it scales correctly with different screen sizes

2. **Accessibility**
   - Player controls need proper accessible names
   - Time labels should be properly labeled for screen readers

---

## Recommendations Priority

### High Priority
1. **Implement help overlay** (`win.show-help-overlay` action)
2. **Add accessible names** to all custom widgets and interactive elements
3. **Test with high-contrast mode** and fix custom styling issues
4. **Reduce custom CSS** - use Adwaita's built-in styles where possible

### Medium Priority
1. **Add standard keyboard shortcuts** (Ctrl+F, Ctrl+W, etc.)
2. **Verify keyboard-only navigation** throughout the app
3. **Test with large text mode** and fix scaling issues
4. **Improve focus indicators** for custom styled elements

### Low Priority
1. **Review Unicode usage** in strings
2. **Optimize dialog spacing** to match HIG exactly
3. **Add more comprehensive tooltips** where missing

---

## Testing Checklist

Before declaring full HIG compliance, test:

- [ ] High-contrast mode (all UI elements visible and functional)
- [ ] Large text mode (UI scales correctly)
- [ ] Keyboard-only navigation (every element reachable)
- [ ] Screen reader (all elements have proper names)
- [ ] On-screen keyboard (works on touch devices)
- [ ] Adaptive layouts (sidebar, mobile views)
- [ ] Help overlay (keyboard shortcuts discoverable)
- [ ] Focus indicators (visible on all interactive elements)
- [ ] Color contrast (meets WCAG standards)
- [ ] Custom widgets accessibility (properly labeled)

---

## Conclusion

Cassette follows many GNOME HIG principles but needs improvements primarily in:
1. **Accessibility** - Missing accessible names and help overlay
2. **Custom Styling** - Too much custom CSS that may conflict with system themes
3. **Keyboard Navigation** - Needs verification and some standard shortcuts

The core architecture using libadwaita and standard widgets is solid, making compliance achievable with focused improvements.

