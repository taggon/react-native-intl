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

  async getTraslator() {
    await this._promise;
    return this._getTranslation.bind(this);
  }

  getPlural(count/*: Number*/) {
    return count === 1 ? 0 : 1;
  }

  _getTranslation(msgid, /* plural_messages, ..., */ count) {
    var plural = this.getPlural(count === undefined ? 1 : count);
    var trans = this._catalog.translations;
    var messages = Array.from(arguments);

    // remove the counter
    messages.pop();

    if (trans && trans[msgid]) {
      return trans[msgid][plural] || trans[msgid][0];
    } else {
      return messages[plural] || messages[0];
    }
  }
}

module.exports = Translation;
