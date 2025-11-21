const { PaymentProcessor, PaymentMethodFactory, PaymentValidator } = require('./index');

async function runTests() {
  let passed = 0;
  let failed = 0;

  function assert(condition, testName) {
    if (condition) {
      console.log(`✓ ${testName}`);
      passed++;
    } else {
      console.log(`✗ ${testName}`);
      failed++;
    }
  }

  console.log('=== Payment Processor Tests ===\n');

  const processor = new PaymentProcessor();

  console.log('--- Credit Card Tests ---');

  const validCard = PaymentMethodFactory.createCreditCardPayment(
    100.00,
    '4532015112830366',
    'Test User',
    '12',
    '25',
    '123'
  );
  const cardResult = await processor.process(validCard);
  assert(cardResult.success === true, 'Valid credit card payment succeeds');
  assert(cardResult.transactionId.startsWith('TXN-'), 'Transaction ID is generated');
  assert(cardResult.maskedCard === '****-****-****-0366', 'Card number is masked');

  const invalidCardNumber = PaymentMethodFactory.createCreditCardPayment(
    100.00,
    '1111111111111111',
    'Test User',
    '12',
    '25',
    '123'
  );
  const invalidResult = await processor.process(invalidCardNumber);
  assert(invalidResult.success === false, 'Invalid card number fails');
  assert(invalidResult.error.includes('Invalid credit card number'), 'Error message is clear');

  const expiredCard = PaymentMethodFactory.createCreditCardPayment(
    100.00,
    '4532015112830366',
    'Test User',
    '01',
    '20',
    '123'
  );
  const expiredResult = await processor.process(expiredCard);
  assert(expiredResult.success === false, 'Expired card fails');

  const missingCVV = {
    method: 'credit_card',
    amount: 100.00,
    cardNumber: '4532015112830366',
    cardHolder: 'Test User',
    expiryMonth: '12',
    expiryYear: '25'
  };
  const missingCVVResult = await processor.process(missingCVV);
  assert(missingCVVResult.success === false, 'Missing CVV fails');

  console.log('\n--- PayPal Tests ---');

  const validPayPal = PaymentMethodFactory.createPayPalPayment(
    50.00,
    'test@example.com',
    'password123'
  );
  const paypalResult = await processor.process(validPayPal);
  assert(paypalResult.success === true, 'Valid PayPal payment succeeds');
  assert(paypalResult.paypalEmail === 'test@example.com', 'PayPal email is stored');
  assert(paypalResult.payerId.startsWith('PAYER-'), 'Payer ID is generated');

  const invalidEmail = PaymentMethodFactory.createPayPalPayment(
    50.00,
    'invalid-email',
    'password123'
  );
  const invalidEmailResult = await processor.process(invalidEmail);
  assert(invalidEmailResult.success === false, 'Invalid email fails');

  const missingPassword = {
    method: 'paypal',
    amount: 50.00,
    email: 'test@example.com'
  };
  const missingPasswordResult = await processor.process(missingPassword);
  assert(missingPasswordResult.success === false, 'Missing password fails');

  console.log('\n--- Bank Transfer Tests ---');

  const validBankTransfer = PaymentMethodFactory.createBankTransferPayment(
    200.00,
    '123456789012',
    '111000025',
    'Account Holder'
  );
  const bankResult = await processor.process(validBankTransfer);
  assert(bankResult.success === true, 'Valid bank transfer succeeds');
  assert(bankResult.maskedAccount === '12****9012', 'Account number is masked');
  assert(bankResult.estimatedCompletionDays === 3, 'Completion days provided');

  const invalidRouting = PaymentMethodFactory.createBankTransferPayment(
    200.00,
    '123456789012',
    '12345',
    'Account Holder'
  );
  const invalidRoutingResult = await processor.process(invalidRouting);
  assert(invalidRoutingResult.success === false, 'Invalid routing number fails');

  const invalidAccount = PaymentMethodFactory.createBankTransferPayment(
    200.00,
    '123',
    '111000025',
    'Account Holder'
  );
  const invalidAccountResult = await processor.process(invalidAccount);
  assert(invalidAccountResult.success === false, 'Invalid account number fails');

  console.log('\n--- Amount Validation Tests ---');

  const negativeAmount = PaymentMethodFactory.createCreditCardPayment(
    -50.00,
    '4532015112830366',
    'Test User',
    '12',
    '25',
    '123'
  );
  const negativeResult = await processor.process(negativeAmount);
  assert(negativeResult.success === false, 'Negative amount fails');

  const zeroAmount = PaymentMethodFactory.createCreditCardPayment(
    0,
    '4532015112830366',
    'Test User',
    '12',
    '25',
    '123'
  );
  const zeroResult = await processor.process(zeroAmount);
  assert(zeroResult.success === false, 'Zero amount fails');

  console.log('\n--- Payment Method Validation Tests ---');

  const unsupportedMethod = {
    method: 'crypto',
    amount: 100.00
  };
  const unsupportedResult = await processor.process(unsupportedMethod);
  assert(unsupportedResult.success === false, 'Unsupported method fails');

  const missingMethod = {
    amount: 100.00,
    cardNumber: '4532015112830366'
  };
  const missingMethodResult = await processor.process(missingMethod);
  assert(missingMethodResult.success === false, 'Missing method fails');

  console.log('\n--- PaymentValidator Tests ---');

  const validCardData = PaymentMethodFactory.createCreditCardPayment(
    100.00,
    '4532015112830366',
    'Test User',
    '12',
    '25',
    '123'
  );
  const validationErrors = PaymentValidator.validatePaymentData(validCardData);
  assert(validationErrors.length === 0, 'Valid payment data has no errors');
  assert(PaymentValidator.isValid(validCardData), 'isValid returns true for valid data');

  const invalidData = {
    method: 'credit_card',
    amount: -10
  };
  const errors = PaymentValidator.validatePaymentData(invalidData);
  assert(errors.length > 0, 'Invalid payment data has errors');
  assert(!PaymentValidator.isValid(invalidData), 'isValid returns false for invalid data');

  console.log('\n--- PaymentMethodFactory Tests ---');

  const ccRequiredFields = PaymentMethodFactory.getRequiredFields('credit_card');
  assert(ccRequiredFields.includes('cardNumber'), 'Credit card required fields include cardNumber');
  assert(ccRequiredFields.includes('cvv'), 'Credit card required fields include cvv');

  const paypalRequiredFields = PaymentMethodFactory.getRequiredFields('paypal');
  assert(paypalRequiredFields.includes('email'), 'PayPal required fields include email');

  const ccDescriptions = PaymentMethodFactory.getFieldDescriptions('credit_card');
  assert(typeof ccDescriptions.cardNumber === 'string', 'Field descriptions are provided');

  console.log('\n=== Test Summary ===');
  console.log(`Passed: ${passed}`);
  console.log(`Failed: ${failed}`);
  console.log(`Total: ${passed + failed}`);

  if (failed === 0) {
    console.log('\n✓ All tests passed!');
  } else {
    console.log(`\n✗ ${failed} test(s) failed`);
    process.exit(1);
  }
}

runTests().catch(error => {
  console.error('Test execution failed:', error);
  process.exit(1);
});
