# API Integration Setup Guide

## Overview
The admin signup modal now integrates with your PHP API to store user information in the database using the `User` and `CustomersAddress` classes.

## Setup Instructions

### 1. Database Setup
Ensure your database has these tables:
- `user` - stores user information
- `customers_address` - stores address information

### 2. XAMPP Configuration
1. Start XAMPP (Apache and MySQL)
2. Ensure `sample_api` folder is in `C:/xampp/htdocs/`
3. Verify the API endpoints are accessible

### 3. API Endpoint Configuration
The Flutter app is configured to connect to:
- Base URL: `http://localhost/sample_api`
- Signup Endpoint: `http://localhost/sample_api/users/Signup.php`

If your setup is different, update the `baseUrl` in `lib/services/api_service.dart`.

## Testing the Integration

### 1. Basic API Test
1. Run the admin Flutter app
2. Navigate to Membership Management
3. Look for the bug icon (🐛) in the app bar (debug mode only)
4. Click it to open the API Test page
5. Test each step:
   - Test API Connection
   - Test Signup Endpoint
   - Test Actual Signup

### 2. Full Integration Test
1. Go back to Membership Management
2. Click "Add New Member"
3. Fill out the complete form:
   - Personal Information (name, birthdate, membership type)
   - Address Information (street, city, state, postal code, country)
   - Emergency Contact & Profile Image
   - Contact Details & Password
4. Submit the form
5. Check for success message

## Data Flow

### What Gets Stored Where:

**User Table (`user`):**
- `first_name` ← First Name
- `last_name` ← Last Name
- `middle_name` ← Middle Name (optional)
- `email` ← Email
- `password` ← Hashed Password
- `birthdate` ← Formatted birthdate (YYYY-MM-DD)
- `phone_number` ← Contact Number
- `emergency_contact_name` ← Emergency Contact Name
- `emergency_contact_number` ← Emergency Contact Phone
- `created_by` ← "admin" (automatic)
- `created_at` ← Current timestamp
- `img` ← Profile image (if uploaded)

**Address Table (`customers_address`):**
- `customer_id` ← Links to user.id
- `street` ← Street
- `city` ← City
- `state` ← State/Province
- `postal_code` ← Postal Code
- `country` ← Country
- `created_by` ← "system" (automatic)
- `created_at` ← Current timestamp

## API Response Handling

### Success Response:
```json
{
  "success": true,
  "message": "User registered successfully",
  "user": { ... },
  "access_token": "...",
  "refresh_token": "...",
  "token_type": "Bearer",
  "expires_in": 86400
}
```

### Error Response:
```json
{
  "success": false,
  "message": "Error description"
}
```

## Troubleshooting

### Common Issues:

1. **Connection Failed**
   - Check if XAMPP is running
   - Verify the API URL in `api_service.dart`
   - Check browser: `http://localhost/sample_api/users/getAllUsers.php`

2. **Database Errors**
   - Ensure database tables exist
   - Check database connection in `Database.php`
   - Verify table structure matches API expectations

3. **CORS Issues**
   - Headers are set in `Signup.php` for cross-origin requests
   - If needed, add more CORS headers

4. **Validation Errors**
   - Check required fields in the PHP API
   - Ensure email format is valid
   - Password must be at least 6 characters

### Debug Output:
The API service includes console logging. Check the Flutter debug console for:
- Request URLs
- Request bodies
- Response status codes
- Response data

## Files Modified/Created:

### New Files:
- `lib/services/api_service.dart` - HTTP client for API communication
- `lib/debug/api_test_page.dart` - Testing interface
- `API_INTEGRATION_README.md` - This guide

### Modified Files:
- `lib/modal/membership_signup_modal.dart` - Added API integration
- `lib/dashboard/memberships.dart` - Added debug button and imports

## Security Notes:
- Passwords are hashed on the server side
- JWT tokens are generated for authentication
- Input validation is handled by both client and server
- CORS headers allow cross-origin requests

## Next Steps:
1. Test the integration thoroughly
2. Consider adding member management features (edit, delete)
3. Implement membership plan assignment
4. Add image upload functionality
5. Create reporting and analytics features
