# react-native-intl

Native [Intl](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl) implementation and Translation extension. The extension loads translation catalog from [gettext `.mo` files](https://www.gnu.org/software/gettext/manual/html_node/MO-Files.html). Note that PO files are **not supported.**

## Features

* [*Collator*](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Collator)  
**Not yet supported**
* [*DateTimeFormat*](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/DateTimeFormat)  
Constructor for objects that format dates and times to match a specified locale.
* [*NumberFormat*](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/NumberFormat)  
  Constructor for objects that format numbers to match a specified locale.
* *Translation* (not a part of ECMAScript)  
  Constructor for objects that translate messages into another languages using `.mo` files.

## Installation

```
$ npm install react-native-intl --save
$ react-native link
```

## Translations

Once you've installed the module, you need to refer a folder, which contains translated `.mo` files, to the project.

1. Create `i18n` folder in your React Native project's root.
2. Put `.mo` translation files into the folder.
3. The files should be named with locale code. For instance, `fr_FR.mo` will be used for French locale.

Then, you need to...

- drag the folder to your project in Xcode and create a folder reference for iOS project.
- create `PROJECT_ROOT/android/app/src/main/assets` (unless it exists) and copy/link the `i18n` folder into the `assets` folder for Android project.

## API

* **DateTimeFormat** objects are similar to JavaScript  [Intl.DateTimeFormat](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/DateTimeFormat) except `format` method returns a Promise.
* **NumberFormat** objects are similar to JavaScript [Intl.NumberFormat](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/NumberFormat) except `format` method returns a Promise.
* **Translation** objects load translation catalog from local file system and translates the passed message into another language. It also supports plural forms.
  * Constructor can take a locale identifier as an argument.

    ```
    new Intl.Translation([locale])
    ```

  * `getTranslator` returns a Promise that passes the message translator function which takes two arguments, message id and optional plural counter. If the function can't find any proper string, it returns the message id.

    ```
    new Intl.Translation().getTranslator().then( _ => {
      console.log( _("Hello, world") );
    });

    // or you can use await syntax

    const _ = await new Intl.Translation().getTranslator();
    console.log( _("Hello, world") );
    ```

## How to format dates/numbers

Load `react-native-intl` module in your JavaScript code.

```
const Intl = require('react-native-intl');
```

Like [the JavaScript objects](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl), create an instance with/without a locale identifier and call its `format` method. Unlike  JavaScript, the method returns a Promise because React Native's JS-Native bridge should work asynchronous.

```
var date = new Date(Date.UTC(2012, 11, 20, 3, 0, 0));

new Intl.DateTimeFormat('en-US').format(date).then(
  str => console.log(str)
);
```

If you omit the locale identifier, system locale will be used by default.

## How to translate messages

Load `react-native-intl` module in your JavaScript code and create a translation instance with your locale. Get a translator function through the promise `getTranslator()` returned and call it to get translated messages. The translator function works like ngettext, you can pass a plural counter to it.

```javascript
const Intl = require('react-native-intl');
const french = new Intl.Translation('fr-FR');

french.getTranslator().then( _ => {
  console.log(_("Hello")); // "Allô"
  console.log(_("Not translated message")); // "Not translated message" returns the original message
  console.log(_("one product")); // "un produit"
  console.log(_("one product", "%d product", 1)); // "un produit"
  console.log(_("one product", "%d products", 2)); // it returns "%d produits" as the translator works like ngettext.
});
```

## Why gettext `.mo` files?

Although I prefer to use `json` format in most cases, `mo` format is better as it supports plural form and context. I don't want to embed `po` files in my app due to its bigger footprint.

## Notes

Because of the difference of platforms, some features can be limited based on platform.
The following table shows what features supported on each platform.

`o` = fully, `△` =  partially, `x` = not supported

|            Feature           | iOS | Android |
|------------------------------|-----|---------|
| Collator                     |  x  |    x    |
| DateTimeFormat               |  △  |    △    |
|  - numbering system          |  x  |    x    |
|  - calendar                  |  o  |    x    |
|  - resolveOptions()          |  x  |    x    |
|  - options                   |  △  |    △    |
|  -- locale matcher           |  x  |    x    |
|  -- format matcher           |  x  |    x    |
|  -- hour12                   |  x  |    x    |
|  -- all other options        |  o  |    o    |
| NumberFormat                 |  △  |    △    |
|  - numbering system          |  x  |    x    |
|  - resolveOptions()          |  x  |    x    |
|  - options                   |  △  |    △    |
|  -- locale matcher           |  x  |    x    |
|  -- currencyDisplay          |  x  |    x    |
|  -- minimumSignificantDigits |  o  |    x    |
|  -- maximumSignificantDigits |  o  |    x    |
|  -- all other options        |  o  |    o    |
| Translation                  |  o  |    o    |

## Feedback

This project is in early stage and I'm very new in both native platforms and even the programming languages.
In fact, I've created this module learning them from basic syntax. So, the code may not be fine, unsafe or insecure.

I will welcome any contributions from you including pull requests, bug reports, suggestions and even documentation.
Don't hesitate to leave your feedback.
