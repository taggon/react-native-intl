'use strict';

const { RNIntl } = require('react-native').NativeModules;
const BaseFormat = require('./BaseFormat');
const DEFAULTS = {
  localeMatcher: 'best fit',
  style: 'decimal',
  currencyDisplay: 'symbol',
  useGrouping: true
};

class NumberFormat extends BaseFormat {
  constructor(locales, options) {
    super(locales, options);

    this.options = Object.assign({}, DEFAULTS, options);
  }

  format(number) {
    return RNIntl.formatNumber(number, this.locales[0], this.options).then( value => value );
  }
}

module.exports = NumberFormat;
