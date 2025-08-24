# Customer Signup and Login Flow Documentation

## Overview
This document describes the complete flow for adding customers through the admin system and allowing them to login through the main application.

## System Architecture

### 1. Admin System (Flutter)
- **Location**: `capstone/admin/`
- **Purpose**: Admin dashboard for managing gym members
- **Key Components**:
  - `customers_signup_modal.dart`: Modal for adding new customers
  - `customers.dart`: Dashboard showing all customers/memberships
  - `api_service.dart`: API client for communicating with PHP backend

### 2. Main Application (Flutter)
- **Location**: `capstone/lib/`
- **Purpose**: Customer-facing application for gym members
- **Key Components**:
  - `auth_service.dart`: Handles customer authentication
  - `auth_state.dart`: Manages authentication state
  - `login.dart`: Login modal for customers

### 3. Backend API (PHP)
- **Location**: `sample_api/`
- **Purpose**: RESTful API for customer management
- **Key Components**:
  - `class/User.php`: User management class
  - `class/Membership.php`: Membership management class
  - `customers/Signup.php`: Customer signup endpoint
  - `customers/Login.php`: Customer login endpoint

## Database Schema

### Required Tables

#### 1. `user` Table
```sql
CREATE TABLE `user` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `first_name` varchar(255) NOT NULL,
  `last_name` varchar(255) NOT NULL,
  `middle_name` varchar(255) DEFAULT NULL,
  `email` varchar(255) NOT NULL UNIQUE,
  `password` varchar(255) NOT NULL,
  `birthdate` date DEFAULT NULL,
  `phone_number` varchar(20) DEFAULT NULL,
  `emergency_contact_name` varchar(255) DEFAULT NULL,
  `emergency_contact_number` varchar(20) DEFAULT NULL,
  `img` varchar(255) DEFAULT NULL,
  `created_by` varchar(100) DEFAULT 'system',
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  `updated_by` varchar(100) DEFAULT NULL,
  `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
);
```

#### 2. `customers_address` Table
```sql
CREATE TABLE `customers_address` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `customer_id` int(11) NOT NULL,
  `street` varchar(255) DEFAULT NULL,
  `city` varchar(255) DEFAULT NULL,
  `state` varchar(255) DEFAULT NULL,
  `postal_code` varchar(20) DEFAULT NULL,
  `country` varchar(255) DEFAULT 'Philippines',
  `created_by` varchar(100) DEFAULT 'system',
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  `updated_by` varchar(100) DEFAULT NULL,
  `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `customer_id` (`customer_id`),
  FOREIGN KEY (`customer_id`) REFERENCES `user`(`id`) ON DELETE CASCADE
);
```

#### 3. `membership` Table
```sql
CREATE TABLE `membership` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `membership_type` varchar(50) NOT NULL,
  `start_date` datetime NOT NULL,
  `expiration_date` date NOT NULL,
  `status` varchar(20) DEFAULT 'active',
  `services` text DEFAULT NULL,
  `price` decimal(10,2) DEFAULT NULL,
  `membership_description` text DEFAULT NULL,
  `payment_method` varchar(100) DEFAULT NULL,
  `payment_amount_total` decimal(10,2) DEFAULT NULL,
  `pay_amount_paid` decimal(10,2) DEFAULT NULL,
  `reference_number` varchar(100) DEFAULT NULL,
  `pay_reference_image` varchar(255) DEFAULT NULL,
  `created_by` varchar(100) DEFAULT 'admin',
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  FOREIGN KEY (`user_id`) REFERENCES `user`(`id`) ON DELETE CASCADE
);
```

## API Endpoints

### 1. Customer Signup
- **Endpoint**: `POST /sample_api/customers/Signup.php`
- **Purpose**: Create new customer account with membership
- **Request Body**:
```json
{
  "first_name": "John",
  "last_name": "Doe",
  "middle_name": "M",
  "email": "john.doe@example.com",
  "password": "password123",
  "birthdate": "1990-01-01",
  "phone_number": "09123456789",
  "emergency_contact_name": "Jane Doe",
  "emergency_contact_number": "09123456788",
  "address": "123 Street, City, State, 1234, Country",
  "membership_type": "Monthly",
  "expiration_date": "2024-02-01",
  "created_by": "admin"
}
```

### 2. Customer Login
- **Endpoint**: `POST /sample_api/customers/Login.php`
- **Purpose**: Authenticate customer and return JWT tokens
- **Request Body**:
```json
{
  "email": "john.doe@example.com",
  "password": "password123"
}
```

### 3. Get All Customers
- **Endpoint**: `GET /sample_api/customers/getAllCustomers.php`
- **Purpose**: Retrieve all customer data for admin dashboard

### 4. Get All Memberships
- **Endpoint**: `GET /sample_api/memberships/getAllMemberships.php`
- **Purpose**: Retrieve all membership data with customer information

## Complete Flow

### Step 1: Admin Creates Customer
1. Admin opens the admin dashboard (`customers.dart`)
2. Admin clicks "Add Member" button
3. Admin fills out the signup form (`customers_signup_modal.dart`)
4. Form data is sent to `ApiService.signupUser()`
5. API service calls `POST /sample_api/customers/Signup.php`
6. PHP backend:
   - Creates user record in `user` table
   - Stores address in `customers_address` table
   - Creates membership record in `membership` table
   - Returns success response with user ID

### Step 2: Customer Can Login
1. Customer opens the main app (`capstone/lib/`)
2. Customer clicks login button
3. Customer enters email and password
4. App calls `AuthService.login()`
5. API service calls `POST /sample_api/customers/Login.php`
6. PHP backend:
   - Validates credentials
   - Returns JWT tokens and user data
7. App stores tokens and updates authentication state
8. Customer is logged in and can access member features

## Security Features

### Password Hashing
- Passwords are hashed using PHP's `password_hash()` function
- Login verification uses `password_verify()` for secure comparison

### JWT Authentication
- Access tokens valid for 24 hours
- Refresh tokens valid for 7 days
- Tokens contain user ID and basic information

### Input Validation
- Email format validation
- Password strength requirements (minimum 6 characters)
- Phone number format validation
- Birthdate format validation

## Error Handling

### Common Error Scenarios
1. **Email Already Exists**: Returns 409 Conflict status
2. **Invalid Input**: Returns 400 Bad Request status
3. **Database Errors**: Returns 500 Internal Server Error
4. **Network Issues**: Returns appropriate error messages

### Error Response Format
```json
{
  "success": false,
  "message": "Error description"
}
```

## Testing the Flow

### 1. Test Customer Creation
1. Start XAMPP and ensure MySQL is running
2. Open admin dashboard in Flutter
3. Try to add a new customer
4. Check database tables for new records

### 2. Test Customer Login
1. Use the created customer credentials
2. Try to login through the main app
3. Verify JWT tokens are received
4. Check authentication state is updated

### 3. Verify Data Consistency
1. Check that customer appears in admin dashboard
2. Verify membership information is displayed
3. Ensure address data is properly stored

## Troubleshooting

### Common Issues

#### 1. Database Connection
- Ensure XAMPP MySQL service is running
- Check database credentials in `Database.php`
- Verify database `db_sample` exists

#### 2. API Endpoints
- Check file paths in `sample_api/` directory
- Ensure PHP files have proper permissions
- Verify CORS headers are set correctly

#### 3. Flutter API Calls
- Check base URL in `api_service.dart`
- Ensure network permissions are set
- Verify JSON parsing in response handling

### Debug Steps
1. Check browser developer tools for network requests
2. Review PHP error logs in XAMPP
3. Add print statements in Flutter code
4. Verify database table structure matches schema

## Future Enhancements

### Potential Improvements
1. **Email Verification**: Send confirmation emails to new customers
2. **Password Reset**: Implement forgot password functionality
3. **Profile Management**: Allow customers to update their information
4. **Membership Renewal**: Automated renewal notifications
5. **Payment Integration**: Connect with payment gateways
6. **Mobile App**: Native mobile applications for customers

### Scalability Considerations
1. **Database Indexing**: Add indexes for frequently queried fields
2. **Caching**: Implement Redis for session management
3. **API Rate Limiting**: Prevent abuse of authentication endpoints
4. **Load Balancing**: Distribute API requests across multiple servers
