'use strict';

const { RNIntl } = require('react-native').NativeModules;

class BaseFormat {
  constructor(locales, options) {
    if (typeof locales === 'undefined') {
      locales = RNIntl.systemLocale;
    }
    this.locales = BaseFormat.supportedLocalesOf(locales);
    this.options = options || {};
  }

  static supportedLocalesOf(locales) {
    if (typeof locales === 'string') {
      locales = [locales];
    }

    var allLocales = RNIntl.availableLocales;
    return locales.filter( item => allLocales.indexOf(item.replace(/-u-.+$/, '')) >= 0 );
  }

  resolvedOptions() {
    return this.options;
  }
}

module.exports = BaseFormat;
