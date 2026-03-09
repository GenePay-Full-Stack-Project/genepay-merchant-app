# Transaction Screens Integration Guide

## Overview
The transaction screens have been integrated with the backend payment service API to fetch real transaction data and support operations like viewing transaction history, details, and processing refunds.

## Files Modified

### 1. Transaction API Service
**File:** `lib/services/transaction_api_service.dart`

A dedicated service for handling transaction-related API calls:

- **`getMerchantTransactions()`** - Fetch paginated transaction list for a merchant
- **`getTransactionById()`** - Get detailed information about a specific transaction
- **`refundTransaction()`** - Process a refund for a completed transaction
- **`getTotalSales()`** - Calculate total sales with optional date filters
- **`getTodaySales()`** - Get today's sales for the merchant
- **`getTransactionStats()`** - Get transaction statistics (completed, pending, failed, etc.)

#### Data Models:
- `PaginatedTransactionResponse` - Handles paginated API responses
- `TransactionStats` - Contains transaction statistics

### 2. Transaction History Screen
**File:** `lib/screens/transaction/transaction_history_screen.dart`

**Key Changes:**
- Fetches real transaction data from the backend API
- Displays merchant's transaction history with pagination support
- Shows total received amount (completed transactions only)
- Filters transactions by status (All, Successful, Pending)
- Animated staggered list with loading and error states
- Navigates to details screen with transaction ID

**API Integration:**
```dart
final response = await _transactionService.getMerchantTransactions(
  merchantId,
  size: 100,
);
```

**Data Mapping:**
- Backend `status: "COMPLETED"` → Display success state
- Backend `userName` → Display customer name
- Backend `amount` → Display transaction amount in LKR
- Backend `createdAt` → Formatted date/time display

### 3. Transaction Details Screen
**File:** `lib/screens/transaction/transaction_details_screen.dart`

**Key Changes:**
- Loads transaction details by transaction ID
- Displays comprehensive transaction information
- Supports refund functionality for completed transactions
- Shows transaction status with color-coded badges
- Loading and error states with retry functionality

**API Integration:**
```dart
final transaction = await _transactionService.getTransactionById(transactionId);
```

**Refund Flow:**
```dart
await _transactionService.refundTransaction(
  transactionId,
  'Merchant initiated refund',
);
```

**Status Display:**
- `COMPLETED` - Green badge
- `PENDING` - Orange badge
- `FAILED` - Red badge
- `REFUNDED` - Blue badge

## Backend Endpoints Used

### GET `/api/v1/payments/merchant/{merchantId}`
Fetch merchant transactions with pagination.

**Query Parameters:**
- `page` (default: 0)
- `size` (default: 20)

**Response:** Paginated list of transactions

### GET `/api/v1/payments/{transactionId}`
Get transaction details by ID.

**Response:** Single transaction object

### POST `/api/v1/payments/{transactionId}/refund`
Process a refund for a transaction.

**Query Parameters:**
- `reason` - Refund reason

**Response:** Updated transaction object

## Data Model Structure

### TransactionResponse
```dart
class TransactionResponse {
  final int id;
  final String transactionId;      // e.g., "TXN-20250001"
  final int userId;
  final String userName;
  final int merchantId;
  final String merchantName;
  final double amount;
  final String currency;           // e.g., "LKR"
  final String status;             // COMPLETED, PENDING, FAILED, REFUNDED
  final String type;
  final String? description;
  final bool biometricVerified;
  final DateTime createdAt;
  final DateTime? completedAt;
}
```

## Setup Requirements

### 1. Merchant ID Storage
The merchant ID must be stored in SharedPreferences after login:
```dart
final prefs = await SharedPreferences.getInstance();
await prefs.setInt('merchant_id', merchantId);
```

### 2. API Base URL
Configured in `api_service.dart`:
```dart
static const String baseUrl = 'http://10.0.2.2:8080';  // Android emulator
```

For physical devices, update to your server's IP address.

### 3. Authentication
Ensure the auth token is set in `ApiService` after successful login.

## Features Implemented

### Transaction History Screen
✅ Real-time transaction data fetching  
✅ Loading states with spinner  
✅ Error handling with retry option  
✅ Total received amount calculation  
✅ Filter by status (All/Successful/Pending)  
✅ Animated staggered list  
✅ Date formatting (Today, Yesterday, etc.)  
✅ Navigation to details screen

### Transaction Details Screen
✅ Fetch transaction by ID  
✅ Display complete transaction information  
✅ Refund functionality with confirmation  
✅ Status-based UI (colors, icons)  
✅ Loading and error states  
✅ Animated card entrance  
✅ Disable refund for non-completed transactions

## Usage Example

### Navigating to Transaction History
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => TransactionHistoryScreen(),
  ),
);
```

### Navigating to Transaction Details
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => TransactionDetailsScreen(
      transactionId: 'TXN-20250001',
    ),
  ),
);
```

## Error Handling

Both screens implement comprehensive error handling:

1. **Network Errors** - Display error message with retry button
2. **Authentication Errors** - Caught and displayed to user
3. **Data Not Found** - Show appropriate message
4. **Refund Errors** - Display error snackbar

## Testing

### Prerequisites
1. Backend payment service must be running
2. Merchant must be logged in
3. Test transactions should exist in the database

### Test Scenarios
1. View transaction list with various statuses
2. Filter transactions by status
3. View transaction details
4. Process a refund
5. Handle no transactions case
6. Handle network errors
7. Handle invalid transaction ID

## Future Enhancements

- [ ] Search functionality for transactions
- [ ] Date range filtering
- [ ] Export transaction reports
- [ ] Pagination with infinite scroll
- [ ] Pull-to-refresh
- [ ] Transaction receipts
- [ ] Email notifications for refunds
- [ ] Bulk operations

## Notes

- Currency is displayed as "LKR" (Sri Lankan Rupees)
- Dates are formatted in a user-friendly way (Today, Yesterday, etc.)
- Search and date range pickers are currently disabled (placeholder)
- Refunds can only be processed for COMPLETED transactions
- The export button is shown but not yet functional
