# Testing Guide - Authentication Modal System

This guide provides comprehensive test scenarios to validate the authentication modal system's functionality, security, and user experience.

## Setup

```bash
npm install
npm run dev
```

Visit `http://localhost:3000`

## Test Scenarios

### 1. User Registration Flow

**Test Case 1.1: Successful Registration**
1. Click "Sign In" button in navbar
2. Click "Don't have an account? Sign up"
3. Enter valid credentials:
   - Name: `John Doe`
   - Email: `john@example.com`
   - Password: `Password123`
4. Click "Create Account"

**Expected:**
- Loading spinner appears
- Modal closes after 1 second
- User name appears in navbar
- Dashboard is accessible

**Test Case 1.2: Invalid Email Format**
1. Open signup modal
2. Enter invalid email: `notanemail`
3. Submit form

**Expected:**
- Error message: "Invalid email format"
- Form stays open
- Other fields retain values

**Test Case 1.3: Weak Password**
1. Open signup modal
2. Enter password without uppercase: `password123`
3. Submit form

**Expected:**
- Error: "Password must contain at least one uppercase letter"

**Test Case 1.4: Short Password**
1. Open signup modal
2. Enter password: `Pass1`
3. Submit form

**Expected:**
- Error: "Password must be at least 8 characters"

**Test Case 1.5: Missing Name**
1. Open signup modal
2. Leave name field empty
3. Submit form

**Expected:**
- Error: "Name is required"

**Test Case 1.6: Duplicate Email**
1. Create account with `test@example.com`
2. Logout
3. Try to create another account with `test@example.com`

**Expected:**
- Error: "An account with this email already exists"

### 2. User Login Flow

**Test Case 2.1: Successful Login**
1. Create account (if not exists)
2. Logout
3. Click "Sign In"
4. Enter correct credentials
5. Submit

**Expected:**
- Modal closes
- User info appears in navbar
- Auth state persists across navigation

**Test Case 2.2: Wrong Password**
1. Open login modal
2. Enter correct email but wrong password
3. Submit

**Expected:**
- Error: "Invalid email or password"
- Form stays open

**Test Case 2.3: Non-existent Email**
1. Open login modal
2. Enter email that doesn't exist
3. Submit

**Expected:**
- Error: "Invalid email or password"
- No user enumeration (same error as wrong password)

### 3. Global State Management

**Test Case 3.1: State Persistence on Navigation**
1. Login successfully
2. Navigate to Dashboard
3. Navigate to Settings
4. Navigate back to Home

**Expected:**
- User stays logged in
- Name shows in navbar on all pages
- No re-authentication required

**Test Case 3.2: State Persistence on Refresh**
1. Login successfully
2. Refresh the page (F5)

**Expected:**
- User remains logged in
- All user data intact
- Theme preference preserved

**Test Case 3.3: Logout Clears State**
1. Login successfully
2. Click "Sign Out"
3. Check localStorage

**Expected:**
- User data removed from navbar
- localStorage cleared of user data
- Redirected to unauthenticated state

### 4. Modal Functionality

**Test Case 4.1: Open from Navbar**
1. Click "Sign In" in navbar

**Expected:**
- Modal opens with login form
- Background darkened
- Body scroll disabled

**Test Case 4.2: Open from Dashboard (Protected)**
1. Logout
2. Navigate to `/dashboard`

**Expected:**
- Modal automatically opens
- Message about authentication required

**Test Case 4.3: Open from Settings**
1. Navigate to Settings
2. Click any "Open Modal" button

**Expected:**
- Modal opens correctly
- All buttons trigger same modal

**Test Case 4.4: Close with Escape Key**
1. Open modal
2. Press Escape key

**Expected:**
- Modal closes
- Focus returns to page

**Test Case 4.5: Close by Clicking Outside**
1. Open modal
2. Click on darkened background

**Expected:**
- Modal closes

**Test Case 4.6: Close Button**
1. Open modal
2. Click X button in header

**Expected:**
- Modal closes

**Test Case 4.7: Multiple Modals Don't Stack**
1. Open modal from one location
2. While modal is open, trigger from another location

**Expected:**
- No stacking or duplicate modals
- Same modal instance used

### 5. Theme Functionality

**Test Case 5.1: Toggle Theme from Navbar**
1. Click moon/sun icon in navbar
2. Observe page colors

**Expected:**
- Theme switches between light/dark
- All components update colors
- Icon changes appropriately

**Test Case 5.2: Toggle Theme from Settings**
1. Go to Settings page
2. Click "Toggle Theme" button
3. Observe visual preview boxes

**Expected:**
- Theme updates globally
- Preview shows current selection
- Navbar icon updates

**Test Case 5.3: Theme Persistence**
1. Set theme to dark mode
2. Refresh page

**Expected:**
- Dark mode persists
- No flash of light mode

**Test Case 5.4: Theme in Modal**
1. Switch to dark mode
2. Open authentication modal

**Expected:**
- Modal renders in dark mode
- Consistent styling

### 6. Form Validation

**Test Case 6.1: Client-side Required Fields**
1. Open signup modal
2. Try to submit without filling fields

**Expected:**
- Browser validation prevents submission
- Fields marked as required

**Test Case 6.2: Server-side Validation**
1. Bypass client validation (dev tools)
2. Submit incomplete form

**Expected:**
- Server returns validation errors
- Errors displayed in UI

**Test Case 6.3: Field-level Errors**
1. Enter invalid email
2. Enter weak password
3. Submit

**Expected:**
- Each field shows its specific error
- Errors appear below respective fields

### 7. Loading States

**Test Case 7.1: Form Submission Loading**
1. Fill valid credentials
2. Click submit
3. Observe button state

**Expected:**
- Button shows spinner
- Text changes to "Processing..."
- Button disabled during submission
- All inputs disabled

**Test Case 7.2: Form Stays Disabled During Request**
1. Submit form
2. Try to change form mode during processing

**Expected:**
- Toggle button disabled
- Cannot switch between login/signup

### 8. Accessibility

**Test Case 8.1: Keyboard Navigation**
1. Open modal
2. Use Tab key to navigate
3. Use Enter to submit

**Expected:**
- Focus moves through all fields
- Submit works with Enter key
- Can close with Escape

**Test Case 8.2: ARIA Labels**
1. Inspect modal with screen reader
2. Check form labels

**Expected:**
- All inputs have labels
- Modal has proper role
- Errors announced to screen reader

**Test Case 8.3: Focus Management**
1. Open modal
2. Check where focus lands

**Expected:**
- Focus moves into modal
- Focus trapped in modal while open
- Focus returns on close

### 9. Edge Cases

**Test Case 9.1: Rapid Modal Toggling**
1. Quickly open and close modal multiple times

**Expected:**
- No memory leaks
- Event listeners cleaned up
- No duplicate modals

**Test Case 9.2: Submit Spam**
1. Submit form multiple times rapidly

**Expected:**
- Only one request processed
- Button disabled prevents spam

**Test Case 9.3: Network Error Handling**
1. Simulate network error (dev tools)
2. Submit form

**Expected:**
- Error message displayed
- Form remains interactive
- Can retry submission

**Test Case 9.4: Very Long Input**
1. Enter extremely long name (>1000 chars)
2. Submit

**Expected:**
- Handled gracefully
- No UI breaking

**Test Case 9.5: Special Characters**
1. Enter name with emojis: `John 👨‍💻 Doe`
2. Enter email with special chars
3. Submit

**Expected:**
- Handled correctly
- No XSS vulnerabilities

### 10. Security

**Test Case 10.1: Password Not Visible**
1. Enter password
2. Inspect password field

**Expected:**
- Password masked with dots
- Not visible in browser dev tools value

**Test Case 10.2: No Sensitive Data in URL**
1. Submit form
2. Check URL bar

**Expected:**
- No credentials in URL
- Clean URL structure

**Test Case 10.3: LocalStorage Security**
1. Login
2. Open browser dev tools
3. Check localStorage

**Expected:**
- Password NOT stored
- Only user ID, name, email stored
- No sensitive tokens visible

**Test Case 10.4: Error Message Security**
1. Try to login with non-existent email
2. Try to login with wrong password

**Expected:**
- Same error message for both
- Prevents user enumeration

### 11. Cross-Browser Testing

Test in:
- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)

**Expected:**
- Consistent behavior across all browsers
- No console errors
- Proper styling

### 12. Responsive Design

**Test Case 12.1: Mobile View**
1. Resize to mobile viewport (375px)
2. Open modal

**Expected:**
- Modal fits screen
- All buttons accessible
- Text readable

**Test Case 12.2: Tablet View**
1. Resize to tablet viewport (768px)
2. Test all features

**Expected:**
- Layout adapts appropriately
- Touch interactions work

**Test Case 12.3: Desktop View**
1. Test on large screen (1920px+)

**Expected:**
- Proper centering
- Max-width constraints respected

## Performance Testing

### Load Time
- Initial page load < 2s
- Modal open animation smooth (60fps)
- Theme switch instant

### Memory Leaks
- Open/close modal 100 times
- Check memory usage
- Should remain stable

### Network
- Authentication request < 1s
- Proper loading indicators
- Graceful failure handling

## Automated Testing Checklist

- [ ] Unit tests for validation functions
- [ ] Integration tests for auth flow
- [ ] E2E tests for complete user journey
- [ ] Performance benchmarks
- [ ] Accessibility audit (WAVE, axe)
- [ ] Security scan

## Known Limitations

1. Mock authentication (not production database)
2. No password reset flow
3. No email verification
4. No OAuth integration
5. Session doesn't expire
6. No rate limiting
7. No CAPTCHA

## Production Readiness Checklist

- [ ] Replace mock auth with real backend
- [ ] Add HTTPS requirement
- [ ] Implement session management
- [ ] Add rate limiting
- [ ] Set up monitoring
- [ ] Add password reset
- [ ] Add email verification
- [ ] Implement OAuth
- [ ] Add audit logging
- [ ] CAPTCHA integration
- [ ] CSRF token validation
- [ ] Input sanitization review
- [ ] Security headers
- [ ] Content Security Policy
- [ ] Regular security audits
