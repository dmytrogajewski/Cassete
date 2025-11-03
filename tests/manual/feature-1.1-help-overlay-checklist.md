# Manual Verification Checklist: Feature 1.1 - Keyboard Shortcuts Help Overlay

## Prerequisites
- [ ] Application built and installed
- [ ] Application can be launched successfully

## Test 1: Help Overlay Opens from Menu
- [ ] Launch Cassette application
- [ ] Click the primary menu button (☰ icon, top-right)
- [ ] Click "Keyboard Shortcuts" menu item
- [ ] **Expected:** Help overlay dialog opens
- [ ] **Expected:** Dialog shows "Keyboard Shortcuts" title
- [ ] **Expected:** Dialog shows two groups: "Playback" and "Application"
- [ ] **Result:** [ ] PASS [ ] FAIL

## Test 2: F1 Key Opens Help Overlay
- [ ] Launch Cassette application
- [ ] Press F1 key
- [ ] **Expected:** Help overlay dialog opens immediately
- [ ] **Expected:** Same content as menu method
- [ ] **Result:** [ ] PASS [ ] FAIL

## Test 3: All Shortcuts Are Visible and Readable
- [ ] Open help overlay (via menu or F1)
- [ ] Verify "Playback" group contains:
  - [ ] Play/Pause - Space
  - [ ] Previous Track - Alt + ←
  - [ ] Next Track - Alt + →
  - [ ] Change Shuffle - Ctrl + S
  - [ ] Change Repeat - Ctrl + R
  - [ ] Mute - Ctrl + M
- [ ] Verify "Application" group contains:
  - [ ] Quit - Ctrl + Q
  - [ ] Share Current Track - Ctrl + Shift + C
  - [ ] Parse URL from Clipboard - Ctrl + Shift + V
  - [ ] Show Keyboard Shortcuts - F1
- [ ] **Result:** [ ] PASS [ ] FAIL

## Test 4: Help Overlay in Light Theme
- [ ] Set system to light theme
- [ ] Open help overlay
- [ ] **Expected:** All text is readable
- [ ] **Expected:** No contrast issues
- [ ] **Expected:** Dialog looks consistent with GNOME apps
- [ ] **Result:** [ ] PASS [ ] FAIL

## Test 5: Help Overlay in Dark Theme
- [ ] Set system to dark theme
- [ ] Open help overlay
- [ ] **Expected:** All text is readable
- [ ] **Expected:** No contrast issues
- [ ] **Expected:** Dialog looks consistent with GNOME apps
- [ ] **Result:** [ ] PASS [ ] FAIL

## Test 6: Dialog Can Be Closed
- [ ] Open help overlay
- [ ] Press Escape key
- [ ] **Expected:** Dialog closes
- [ ] Click outside dialog (if applicable)
- [ ] **Expected:** Dialog closes
- [ ] **Result:** [ ] PASS [ ] FAIL

## Test 7: Keyboard Navigation in Dialog
- [ ] Open help overlay
- [ ] Use Tab to navigate
- [ ] **Expected:** Focus moves through shortcut items
- [ ] **Expected:** Focus indicators are visible
- [ ] **Result:** [ ] PASS [ ] FAIL

## Summary
- Date tested: ___________
- Tester: ___________
- Overall result: [ ] PASS [ ] FAIL
- Notes: 
  _________________________________
  _________________________________
  _________________________________

