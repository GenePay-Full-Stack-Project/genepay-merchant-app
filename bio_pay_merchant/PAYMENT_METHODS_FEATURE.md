# Merchant Payment Methods

This feature allows merchants to manage their payment cards for receiving payments.

## Files Created

### Models
- `lib/models/card_response.dart` - Card data model
- `lib/models/add_card_request.dart` - Add card request model

### Screens
- `lib/screens/payment_methods/payment_methods_screen.dart` - Main card management screen
- `lib/screens/payment_methods/add_card_screen.dart` - Add new card screen

### Services
- Updated `lib/services/api_service.dart` with card management endpoints:
  - `addMerchantCard()` - Add a new card
  - `getMerchantCards()` - Get all merchant cards
  - `getMerchantDefaultCard()` - Get default card
  - `setMerchantDefaultCard()` - Set a card as default
  - `removeMerchantCard()` - Remove a card

## Features

### Payment Methods Screen
- View all added payment cards
- See which card is set as default (highlighted with orange border)
- Set any card as default for receiving payments
- Remove cards from account
- Pull-to-refresh to reload cards
- Add new card via floating action button

### Add Card Screen
- Card number input with automatic formatting (spaces every 4 digits)
- Name on card
- Expiry date (MM/YY format)
- CVV (3-4 digits, hidden)
- Optional card nickname
- Form validation for all fields
- Terms and conditions checkbox
- Secure encryption notice

## Navigation

The Payment Methods screen can be accessed from:
- Merchant Dashboard → Quick Actions → "Payment Cards" button

## API Endpoints Used

All endpoints are prefixed with `/api/v1/cards/merchant/{merchantId}`:

- `POST /` - Add new card
- `GET /` - Get all cards
- `GET /default` - Get default card
- `PUT /{cardId}/set-default` - Set default card
- `DELETE /{cardId}` - Remove card

## Card Brand Detection

The UI displays appropriate logos for:
- Visa (blue logo)
- Mastercard (red/orange overlapping circles)
- Generic card icon for other brands

## Security Features

- CVV field is obscured during input
- Card numbers are masked (showing only last 4 digits)
- All card data is transmitted securely to the backend
- Validation prevents invalid card data submission

## Usage Flow

1. Merchant navigates to Payment Methods from dashboard
2. If no cards exist, see empty state with prompt to add card
3. Click "Add Card" floating button
4. Fill in card details with validation
5. Agree to terms and submit
6. Card is verified and added to merchant account
7. Merchant can set default card for receiving payments
8. Merchant can remove cards no longer needed
