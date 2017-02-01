'use strict';

const { RNIntl } = require('react-native').NativeModules;

class Translation {
  _locale = null;
  _promise = null;
  _catalog = null;

  constructor(locale/*: String*/) {
    this._locale = locale;

    this._promise = RNIntl.loadCatalog(locale).then(
      catalog => {
        this._catalog = catalog;

        // creat getPlural function
        if (catalog.headers && catalog.headers['Plural-Forms']) {
          this.getPlural = new Function('n', `var plural; var ${catalog.headers['Plural-Forms']} ; return plural;`);
        }
      },
      error => {
        this._catalog = {translations:{}};
      }
    );
  }

  async getTranslator() {
    await this._promise;
    return this._getTranslation.bind(this);
  }

  getPlural(count/*: Number*/) {
    return count === 1 ? 0 : 1;
  }

  _getTranslation(msgid, /* plural_messages, ..., count: Number */) {
    const count  = arguments[arguments.length - 1];
    const plural = this.getPlural(typeof count === 'number' ? count : 1);
    const trans  = this._catalog.translations;
    const messages = Array.from(arguments);

    // remove the counter
    if (typeof count === 'number') {
      messages.pop();
    }

    if (trans && trans[msgid]) {
      return trans[msgid][plural] || trans[msgid][0];
    } else {
      return messages[plural] || messages[0];
    }
  }
}

module.exports = Translation;
