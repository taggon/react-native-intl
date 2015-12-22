'use strict';

const { RNIntl } = require('react-native').NativeModules;
const BaseFormat = require('./BaseFormat');

const DEFAULTS = {
  localeMatcher: 'best fit',
  formatMatcher: 'best fit'
};

const DATE_FIELDS = {
  era: { 'narrow': 'GGG', 'short': 'GGGGG', 'long': 'GGGG' },
  year: { 'numeric': 'y', '2-digit': 'yy', 'undefined': 'y' },
  month: { 'numeric': 'M', '2-digit': 'MM', 'narrow': 'MMM', 'short': 'MMMMM', 'long': 'MMMM', 'undefined': 'M' },
  day: { 'numeric': 'd', '2-digit': 'dd', 'undefined': 'd' },
  weekday: { 'narrow': 'EEE', 'short': 'EEEEE', 'long': 'EEEE' },
  hour: { 'numeric': 'h', '2-digit': 'hh' },
  minute: { 'numeric': 'm', '2-digit': 'mm' },
  second: { 'numeric': 's', '2-digit': 'ss' },
  timeZoneName: { 'short': 'v', 'long': 'vvvv' },
}

class DateTimeFormat extends BaseFormat {
  constructor(locales, options) {
    super(locales, options);

    var parsedLocale = this.parseLocale(this.locales[0]);

    this.locales[0] = parsedLocale.code;
    this.calendar = parsedLocale.calendar;
    this.options = Object.assign({}, DEFAULTS, options);
    this.dateTemplate = this.generateDateTemplate(this.options);
  }

  format(date/*: Date*/) {
    var options = {calendar:this.calendar, template:this.dateTemplate};
    if ('hour12' in this.options) options.hour12 = this.options.hour12;
    return RNIntl.formatDate(+date, this.locales[0], options).then( value => value );
  }

  parseLocale(locale/*: String*/) {
    var result = {  };
    var components = locale.split(/-u\b/);

    result.code = locale = components[0];

    if (components[1]) {
      let match = components[1].match(/-cu-([a-z0-9A-Z]+)/)
      if (match) {
	result.calendar = RNIntl.availableCalendars[match[1]] || undefined;
      }

      // TODO : numbering system
    }

    return result;
  }

  generateDateTemplate(options) {
    var tpl = '';
    var components = 'era year month weekday day hour minute second timeZoneName'.split(' ');

    for (var i=0; i < components.length; i++) {
      tpl += DATE_FIELDS[components[i]][options[components[i]]] || '';
    }

    return tpl;
  }
}

module.exports = DateTimeFormat;
