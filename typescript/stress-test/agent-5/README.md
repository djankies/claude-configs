# Payment Processing Service

A robust payment processing service that handles multiple payment methods with comprehensive validation and error handling.

## Features

- **Multiple Payment Methods**: Credit Card, PayPal, Bank Transfer
- **Method-Specific Validation**: Each payment method has unique validation rules
- **Clear Error Messages**: Detailed error messages for debugging and user feedback
- **Transaction Management**: Generates unique transaction IDs and tracks processing
- **Data Masking**: Sensitive data (card numbers, account numbers) is masked in responses
- **Async Processing**: Simulates real-world async payment gateway interactions

## Payment Methods

### Credit Card

Required Fields:
- `cardNumber` - 13-19 digit card number (Luhn algorithm validated)
- `cardHolder` - Name on card
- `expiryMonth` - 1-12
- `expiryYear` - YY or YYYY format
- `cvv` - 3 or 4 digits
- `amount` - Payment amount (> 0)

### PayPal

Required Fields:
- `email` - Valid email address
- `password` - Account password (minimum 6 characters)
- `amount` - Payment amount (> 0)

### Bank Transfer

Required Fields:
- `accountNumber` - 8-17 digit account number
- `routingNumber` - 9 digit routing number
- `accountHolder` - Account holder name
- `amount` - Payment amount (> 0)

## Usage

### Basic Processing

```javascript
const { PaymentProcessor, PaymentMethodFactory } = require('./index');

const processor = new PaymentProcessor();

const payment = PaymentMethodFactory.createCreditCardPayment(
  99.99,
  '4532015112830366',
  'John Doe',
  '12',
  '25',
  '123',
  'USD'
);

const result = await processor.process(payment);

if (result.success) {
  console.log('Payment successful!');
  console.log('Transaction ID:', result.transactionId);
} else {
  console.log('Payment failed:', result.error);
}
```

### Manual Payment Construction

```javascript
const payment = {
  method: 'paypal',
  amount: 50.00,
  currency: 'USD',
  email: 'user@example.com',
  password: 'securepass'
};

const result = await processor.process(payment);
```

### Validation Only

```javascript
const { PaymentValidator } = require('./index');

const errors = PaymentValidator.validatePaymentData(payment);

if (errors.length > 0) {
  console.log('Validation errors:', errors);
}

if (PaymentValidator.isValid(payment)) {
  console.log('Payment data is valid');
}
```

### Get Required Fields

```javascript
const { PaymentMethodFactory } = require('./index');

const fields = PaymentMethodFactory.getRequiredFields('credit_card');
const descriptions = PaymentMethodFactory.getFieldDescriptions('credit_card');
```

## Response Format

### Success Response

```json
{
  "success": true,
  "transactionId": "TXN-1637012345678-ABC123XYZ",
  "method": "credit_card",
  "amount": 99.99,
  "currency": "USD",
  "timestamp": "2024-11-21T10:30:45.123Z",
  "processor": "credit_card_gateway",
  "maskedCard": "****-****-****-0366",
  "cardHolder": "John Doe"
}
```

### Failure Response

```json
{
  "success": false,
  "error": "Invalid credit card number",
  "method": "credit_card",
  "timestamp": "2024-11-21T10:30:45.123Z"
}
```

## Running Examples

```bash
node example.js
```

This will run various payment scenarios demonstrating both successful and failed transactions.

## Running Tests

```bash
node test.js
```

Runs comprehensive tests covering:
- All payment methods
- Validation rules
- Error handling
- Edge cases
- Factory methods

## Error Handling

The service provides specific error types:

- `ValidationError` - Invalid payment data
- `ProcessingError` - Payment gateway issues
- `InsufficientFundsError` - Not enough funds
- `AuthenticationError` - Authentication failed
- `UnsupportedMethodError` - Payment method not supported

## Security Features

- Card numbers are masked in responses
- Account numbers are partially hidden
- Sensitive data is not logged
- Luhn algorithm validation for credit cards
- Email format validation
- Input sanitization

## Supported Currencies

USD, EUR, GBP, CAD, AUD, JPY, CNY, INR

Default: USD

## File Structure

```tree
/Users/daniel/Projects/claude-configs/stress-test/agent-5/
├── PaymentProcessor.js          # Main processor with validation and execution
├── PaymentMethodFactory.js      # Factory for creating payment objects
├── PaymentValidator.js          # Standalone validation utilities
├── PaymentError.js              # Custom error classes
├── index.js                     # Main export file
├── example.js                   # Usage examples
├── test.js                      # Comprehensive test suite
└── README.md                    # This file
```

## API Reference

### PaymentProcessor

- `process(paymentData)` - Process a payment and return result
- `validatePaymentMethod(method)` - Validate payment method is supported
- `validatePaymentData(paymentData)` - Validate all payment data

### PaymentMethodFactory

- `createCreditCardPayment(...)` - Create credit card payment object
- `createPayPalPayment(...)` - Create PayPal payment object
- `createBankTransferPayment(...)` - Create bank transfer payment object
- `getRequiredFields(method)` - Get required fields for a method
- `getFieldDescriptions(method)` - Get field descriptions for a method

### PaymentValidator

- `validatePaymentData(paymentData)` - Returns array of validation errors
- `isValid(paymentData)` - Returns boolean indicating validity
- `validateAmount(amount)` - Validate amount field
- `validateCurrency(currency)` - Validate currency field

## Production Considerations

Before deploying to production:

1. Replace simulated payment processing with real gateway integrations
2. Implement proper authentication for PayPal and other services
3. Add rate limiting and fraud detection
4. Implement proper logging and monitoring
5. Add database integration for transaction records
6. Implement webhook handlers for async payment updates
7. Add retry logic for failed transactions
8. Implement proper secret management
9. Add comprehensive audit logging
10. Set up PCI DSS compliance measures

## License

MIT
