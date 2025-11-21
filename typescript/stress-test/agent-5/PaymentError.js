class PaymentError extends Error {
  constructor(message, code, details = {}) {
    super(message);
    this.name = 'PaymentError';
    this.code = code;
    this.details = details;
    this.timestamp = new Date().toISOString();
  }

  toJSON() {
    return {
      name: this.name,
      message: this.message,
      code: this.code,
      details: this.details,
      timestamp: this.timestamp
    };
  }
}

class ValidationError extends PaymentError {
  constructor(message, validationErrors = []) {
    super(message, 'VALIDATION_ERROR', { validationErrors });
    this.name = 'ValidationError';
  }
}

class ProcessingError extends PaymentError {
  constructor(message, processor) {
    super(message, 'PROCESSING_ERROR', { processor });
    this.name = 'ProcessingError';
  }
}

class InsufficientFundsError extends PaymentError {
  constructor(message, availableAmount, requestedAmount) {
    super(message, 'INSUFFICIENT_FUNDS', { availableAmount, requestedAmount });
    this.name = 'InsufficientFundsError';
  }
}

class AuthenticationError extends PaymentError {
  constructor(message, method) {
    super(message, 'AUTHENTICATION_ERROR', { method });
    this.name = 'AuthenticationError';
  }
}

class UnsupportedMethodError extends PaymentError {
  constructor(message, method, supportedMethods) {
    super(message, 'UNSUPPORTED_METHOD', { method, supportedMethods });
    this.name = 'UnsupportedMethodError';
  }
}

module.exports = {
  PaymentError,
  ValidationError,
  ProcessingError,
  InsufficientFundsError,
  AuthenticationError,
  UnsupportedMethodError
};
