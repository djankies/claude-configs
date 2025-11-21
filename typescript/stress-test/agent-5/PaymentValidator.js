class PaymentValidator {
  static validateAmount(amount) {
    const errors = [];

    if (amount === undefined || amount === null) {
      errors.push('Amount is required');
      return errors;
    }

    if (typeof amount !== 'number') {
      errors.push('Amount must be a number');
      return errors;
    }

    if (amount <= 0) {
      errors.push('Amount must be greater than 0');
    }

    if (amount > 999999.99) {
      errors.push('Amount exceeds maximum allowed (999999.99)');
    }

    if (!Number.isFinite(amount)) {
      errors.push('Amount must be a finite number');
    }

    const decimalPlaces = (amount.toString().split('.')[1] || '').length;
    if (decimalPlaces > 2) {
      errors.push('Amount cannot have more than 2 decimal places');
    }

    return errors;
  }

  static validateCurrency(currency) {
    const errors = [];
    const supportedCurrencies = ['USD', 'EUR', 'GBP', 'CAD', 'AUD', 'JPY', 'CNY', 'INR'];

    if (!currency) {
      return errors;
    }

    if (typeof currency !== 'string') {
      errors.push('Currency must be a string');
      return errors;
    }

    if (!supportedCurrencies.includes(currency.toUpperCase())) {
      errors.push(`Unsupported currency: ${currency}. Supported: ${supportedCurrencies.join(', ')}`);
    }

    return errors;
  }

  static validateCreditCardData(data) {
    const errors = [];

    if (!data.cardNumber) {
      errors.push('Card number is required');
    } else if (typeof data.cardNumber !== 'string') {
      errors.push('Card number must be a string');
    }

    if (!data.cardHolder) {
      errors.push('Card holder name is required');
    } else if (typeof data.cardHolder !== 'string') {
      errors.push('Card holder name must be a string');
    } else if (data.cardHolder.length < 2) {
      errors.push('Card holder name is too short');
    }

    if (!data.expiryMonth) {
      errors.push('Expiry month is required');
    }

    if (!data.expiryYear) {
      errors.push('Expiry year is required');
    }

    if (!data.cvv) {
      errors.push('CVV is required');
    } else if (typeof data.cvv !== 'string') {
      errors.push('CVV must be a string');
    }

    return errors;
  }

  static validatePayPalData(data) {
    const errors = [];

    if (!data.email) {
      errors.push('Email is required');
    } else if (typeof data.email !== 'string') {
      errors.push('Email must be a string');
    }

    if (!data.password) {
      errors.push('Password is required');
    } else if (typeof data.password !== 'string') {
      errors.push('Password must be a string');
    } else if (data.password.length < 6) {
      errors.push('Password is too short (minimum 6 characters)');
    }

    return errors;
  }

  static validateBankTransferData(data) {
    const errors = [];

    if (!data.accountNumber) {
      errors.push('Account number is required');
    } else if (typeof data.accountNumber !== 'string') {
      errors.push('Account number must be a string');
    }

    if (!data.routingNumber) {
      errors.push('Routing number is required');
    } else if (typeof data.routingNumber !== 'string') {
      errors.push('Routing number must be a string');
    }

    if (!data.accountHolder) {
      errors.push('Account holder name is required');
    } else if (typeof data.accountHolder !== 'string') {
      errors.push('Account holder name must be a string');
    } else if (data.accountHolder.length < 2) {
      errors.push('Account holder name is too short');
    }

    return errors;
  }

  static validatePaymentData(paymentData) {
    const errors = [];

    if (!paymentData || typeof paymentData !== 'object') {
      errors.push('Payment data must be an object');
      return errors;
    }

    if (!paymentData.method) {
      errors.push('Payment method is required');
      return errors;
    }

    errors.push(...this.validateAmount(paymentData.amount));
    errors.push(...this.validateCurrency(paymentData.currency));

    switch (paymentData.method) {
      case 'credit_card':
        errors.push(...this.validateCreditCardData(paymentData));
        break;
      case 'paypal':
        errors.push(...this.validatePayPalData(paymentData));
        break;
      case 'bank_transfer':
        errors.push(...this.validateBankTransferData(paymentData));
        break;
      default:
        errors.push(`Unknown payment method: ${paymentData.method}`);
    }

    return errors;
  }

  static isValid(paymentData) {
    return this.validatePaymentData(paymentData).length === 0;
  }
}

module.exports = PaymentValidator;
