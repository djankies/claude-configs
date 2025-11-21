class PaymentMethodFactory {
  static createCreditCardPayment(amount, cardNumber, cardHolder, expiryMonth, expiryYear, cvv, currency = 'USD') {
    return {
      method: 'credit_card',
      amount,
      currency,
      cardNumber,
      cardHolder,
      expiryMonth,
      expiryYear,
      cvv
    };
  }

  static createPayPalPayment(amount, email, password, currency = 'USD') {
    return {
      method: 'paypal',
      amount,
      currency,
      email,
      password
    };
  }

  static createBankTransferPayment(amount, accountNumber, routingNumber, accountHolder, currency = 'USD') {
    return {
      method: 'bank_transfer',
      amount,
      currency,
      accountNumber,
      routingNumber,
      accountHolder
    };
  }

  static getRequiredFields(method) {
    const fieldMap = {
      credit_card: ['amount', 'cardNumber', 'cardHolder', 'expiryMonth', 'expiryYear', 'cvv'],
      paypal: ['amount', 'email', 'password'],
      bank_transfer: ['amount', 'accountNumber', 'routingNumber', 'accountHolder']
    };

    return fieldMap[method] || [];
  }

  static getFieldDescriptions(method) {
    const descriptions = {
      credit_card: {
        cardNumber: 'Credit card number (13-19 digits)',
        cardHolder: 'Name on card',
        expiryMonth: 'Expiry month (1-12)',
        expiryYear: 'Expiry year (YY or YYYY)',
        cvv: 'Card security code (3-4 digits)',
        amount: 'Payment amount',
        currency: 'Currency code (default: USD)'
      },
      paypal: {
        email: 'PayPal account email',
        password: 'PayPal account password',
        amount: 'Payment amount',
        currency: 'Currency code (default: USD)'
      },
      bank_transfer: {
        accountNumber: 'Bank account number (8-17 digits)',
        routingNumber: 'Bank routing number (9 digits)',
        accountHolder: 'Account holder name',
        amount: 'Payment amount',
        currency: 'Currency code (default: USD)'
      }
    };

    return descriptions[method] || {};
  }
}

module.exports = PaymentMethodFactory;
