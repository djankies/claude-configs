const { PaymentProcessor, PaymentMethodFactory } = require('./index');

async function runExamples() {
  const processor = new PaymentProcessor();

  console.log('=== Payment Processing Service Examples ===\n');

  console.log('1. Credit Card Payment (Success):');
  const creditCardPayment = PaymentMethodFactory.createCreditCardPayment(
    99.99,
    '4532015112830366',
    'John Doe',
    '12',
    '25',
    '123',
    'USD'
  );
  const result1 = await processor.process(creditCardPayment);
  console.log(JSON.stringify(result1, null, 2));

  console.log('\n2. PayPal Payment (Success):');
  const paypalPayment = PaymentMethodFactory.createPayPalPayment(
    150.00,
    'user@example.com',
    'securepass123',
    'USD'
  );
  const result2 = await processor.process(paypalPayment);
  console.log(JSON.stringify(result2, null, 2));

  console.log('\n3. Bank Transfer Payment (Success):');
  const bankTransferPayment = PaymentMethodFactory.createBankTransferPayment(
    500.00,
    '123456789012',
    '111000025',
    'Jane Smith',
    'USD'
  );
  const result3 = await processor.process(bankTransferPayment);
  console.log(JSON.stringify(result3, null, 2));

  console.log('\n4. Invalid Credit Card (Failure):');
  const invalidCard = PaymentMethodFactory.createCreditCardPayment(
    50.00,
    '1234567890123456',
    'Invalid User',
    '12',
    '25',
    '999',
    'USD'
  );
  const result4 = await processor.process(invalidCard);
  console.log(JSON.stringify(result4, null, 2));

  console.log('\n5. Missing Required Fields (Failure):');
  const incompletePayment = {
    method: 'credit_card',
    amount: 75.00
  };
  const result5 = await processor.process(incompletePayment);
  console.log(JSON.stringify(result5, null, 2));

  console.log('\n6. Invalid Payment Amount (Failure):');
  const invalidAmount = PaymentMethodFactory.createCreditCardPayment(
    -10.00,
    '4532015112830366',
    'Test User',
    '12',
    '25',
    '123',
    'USD'
  );
  const result6 = await processor.process(invalidAmount);
  console.log(JSON.stringify(result6, null, 2));

  console.log('\n7. Expired Card (Failure):');
  const expiredCard = PaymentMethodFactory.createCreditCardPayment(
    100.00,
    '4532015112830366',
    'Past User',
    '01',
    '20',
    '123',
    'USD'
  );
  const result7 = await processor.process(expiredCard);
  console.log(JSON.stringify(result7, null, 2));

  console.log('\n8. Invalid PayPal Email (Failure):');
  const invalidPayPal = PaymentMethodFactory.createPayPalPayment(
    200.00,
    'not-an-email',
    'password123',
    'USD'
  );
  const result8 = await processor.process(invalidPayPal);
  console.log(JSON.stringify(result8, null, 2));
}

runExamples().catch(console.error);
