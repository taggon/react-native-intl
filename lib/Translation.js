'use strict';

const { RNIntl } = require('react-native').NativeModules;

class Translation {
	_locale = null;
	_promise = null;
	_catalog = null;

	constructor(locale/*: String*/) {
		this._locale = locale;
		this._promise = RNIntl.loadCatalog(locale);
	}

	translate(msgid, count) {
		if (this._catalog) {
			return Promise.resolve(this._getTranslation(msgid, count));
		}

		return this._promise.then(
			catalog => {
				this._catalog = catalog;

				// creat getPlural function
				if (catalog.headers && catalog.headers['Plural-Forms']) {
					this.getPlural = new Function('n', `var plural; var ${catalog.headers['Plural-Forms']} ; return plural;`);
				}

				return this._getTranslation(msgid, count);
			},
			error => {console.log(error);
				return msgid;
			}
		);
	}

	getPlural(count/*: Number*/) {
		return 0;
	}

	_getTranslation(msgid, count) {
		var plural = this.getPlural(count === undefined ? 1 : count);
		var trans = this._catalog.translations;

		if (trans && trans[msgid]) {
			return trans[msgid][plural] || trans[msgid][0];
		} else {
			return msgid;
		}
	}
}

module.exports = Translation;
