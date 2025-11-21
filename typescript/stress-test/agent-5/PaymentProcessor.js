class PaymentProcessor {
  constructor() {
    this.supportedMethods = ['credit_card', 'paypal', 'bank_transfer'];
  }

  async process(paymentData) {
    try {
      this.validatePaymentMethod(paymentData.method);
      this.validatePaymentData(paymentData);

      const result = await this.executePayment(paymentData);
      return {
        success: true,
        transactionId: this.generateTransactionId(),
        method: paymentData.method,
        amount: paymentData.amount,
        currency: paymentData.currency || 'USD',
        timestamp: new Date().toISOString(),
        ...result
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
        method: paymentData.method,
        timestamp: new Date().toISOString()
      };
    }
  }

  validatePaymentMethod(method) {
    if (!method) {
      throw new Error('Payment method is required');
    }
    if (!this.supportedMethods.includes(method)) {
      throw new Error(`Unsupported payment method: ${method}. Supported methods: ${this.supportedMethods.join(', ')}`);
    }
  }

  validatePaymentData(paymentData) {
    if (!paymentData.amount || paymentData.amount <= 0) {
      throw new Error('Invalid payment amount. Amount must be greater than 0');
    }

    switch (paymentData.method) {
      case 'credit_card':
        this.validateCreditCard(paymentData);
        break;
      case 'paypal':
        this.validatePayPal(paymentData);
        break;
      case 'bank_transfer':
        this.validateBankTransfer(paymentData);
        break;
    }
  }

  validateCreditCard(data) {
    const required = ['cardNumber', 'cardHolder', 'expiryMonth', 'expiryYear', 'cvv'];
    const missing = required.filter(field => !data[field]);

    if (missing.length > 0) {
      throw new Error(`Missing required credit card fields: ${missing.join(', ')}`);
    }

    if (!this.isValidCardNumber(data.cardNumber)) {
      throw new Error('Invalid credit card number');
    }

    if (!this.isValidCVV(data.cvv)) {
      throw new Error('Invalid CVV. Must be 3 or 4 digits');
    }

    if (!this.isValidExpiry(data.expiryMonth, data.expiryYear)) {
      throw new Error('Card has expired or invalid expiry date');
    }
  }

  validatePayPal(data) {
    const required = ['email', 'password'];
    const missing = required.filter(field => !data[field]);

    if (missing.length > 0) {
      throw new Error(`Missing required PayPal fields: ${missing.join(', ')}`);
    }

    if (!this.isValidEmail(data.email)) {
      throw new Error('Invalid PayPal email address');
    }
  }

  validateBankTransfer(data) {
    const required = ['accountNumber', 'routingNumber', 'accountHolder'];
    const missing = required.filter(field => !data[field]);

    if (missing.length > 0) {
      throw new Error(`Missing required bank transfer fields: ${missing.join(', ')}`);
    }

    if (!this.isValidAccountNumber(data.accountNumber)) {
      throw new Error('Invalid bank account number');
    }

    if (!this.isValidRoutingNumber(data.routingNumber)) {
      throw new Error('Invalid routing number. Must be 9 digits');
    }
  }

  isValidCardNumber(cardNumber) {
    const cleaned = cardNumber.replace(/\s|-/g, '');
    if (!/^\d{13,19}$/.test(cleaned)) {
      return false;
    }
    return this.luhnCheck(cleaned);
  }

  luhnCheck(cardNumber) {
    let sum = 0;
    let isEven = false;

    for (let i = cardNumber.length - 1; i >= 0; i--) {
      let digit = parseInt(cardNumber[i], 10);

      if (isEven) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      isEven = !isEven;
    }

    return sum % 10 === 0;
  }

  isValidCVV(cvv) {
    return /^\d{3,4}$/.test(cvv);
  }

  isValidExpiry(month, year) {
    const now = new Date();
    const currentYear = now.getFullYear();
    const currentMonth = now.getMonth() + 1;

    const expiryMonth = parseInt(month, 10);
    const expiryYear = parseInt(year, 10);

    if (expiryMonth < 1 || expiryMonth > 12) {
      return false;
    }

    const fullYear = expiryYear < 100 ? 2000 + expiryYear : expiryYear;

    if (fullYear < currentYear) {
      return false;
    }

    if (fullYear === currentYear && expiryMonth < currentMonth) {
      return false;
    }

    return true;
  }

  isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  isValidAccountNumber(accountNumber) {
    return /^\d{8,17}$/.test(accountNumber);
  }

  isValidRoutingNumber(routingNumber) {
    return /^\d{9}$/.test(routingNumber);
  }

  async executePayment(paymentData) {
    switch (paymentData.method) {
      case 'credit_card':
        return await this.processCreditCard(paymentData);
      case 'paypal':
        return await this.processPayPal(paymentData);
      case 'bank_transfer':
        return await this.processBankTransfer(paymentData);
    }
  }

  async processCreditCard(data) {
    await this.simulateProcessingDelay();

    const lastFour = data.cardNumber.slice(-4);
    return {
      processor: 'credit_card_gateway',
      maskedCard: `****-****-****-${lastFour}`,
      cardHolder: data.cardHolder
    };
  }

  async processPayPal(data) {
    await this.simulateProcessingDelay();

    return {
      processor: 'paypal_gateway',
      paypalEmail: data.email,
      payerId: this.generatePayerId()
    };
  }

  async processBankTransfer(data) {
    await this.simulateProcessingDelay();

    const maskedAccount = data.accountNumber.slice(0, 2) + '****' + data.accountNumber.slice(-4);
    return {
      processor: 'bank_transfer_gateway',
      maskedAccount: maskedAccount,
      accountHolder: data.accountHolder,
      estimatedCompletionDays: 3
    };
  }

  simulateProcessingDelay() {
    return new Promise(resolve => setTimeout(resolve, Math.random() * 100));
  }

  generateTransactionId() {
    return 'TXN-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9).toUpperCase();
  }

  generatePayerId() {
    return 'PAYER-' + Math.random().toString(36).substr(2, 12).toUpperCase();
  }
}

module.exports = PaymentProcessor;
