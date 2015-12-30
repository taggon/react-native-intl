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
```

### iOS Setup

Once you've installed the module, you need to integrate it into the Xcode project of your React Native app. To do this, do the following steps.

1. Open your app's Xcode project
2. Find `RNIntl.xcodeproj` file within the `node_modules/react-native-intl` directory, and drag it into `Libraries` category in Xcode.
3. Go to the "Build Phases" tab in your project configuration.
4. Drag `libRNIntl.a` from `Libraries/RNIntl.xcodeproj` into the "Link Binary With Libraries" section of your project's "Build Phases" configuration.
5. To translate messages, create `i18n` folder and put `.mo` files into it. Drag the folder to just below the project in Xcode. Choose *Create folder references*.

### Android Setup

In order to use this module in your Android project, take the following steps.

1. In your `android/settings.gradle` file, add the following code:

  ```
  include ':rnintl'
  project(':rnintl').projectDir = new File(rootProject.projectDir, '../node_modules/react-native-intl/android')
  ```

2. In your `android/app/build.gradle` file, add `:react-native-intl` project as a dependency (note that **app** folder):

  ```
  ...
  dependencies {
    ...
    compile project(':rnintl')
  }
  ```

3. Update your `MainActivity.java` file to look like this (without preceding the `+` signs).

  ```diff
  package com.myapp;

  + import kim.taegon.rnintl.ReactNativeIntlPackage;

  ....

  public class MainActivity extends Activity implements DefaultHardwareBackBtnHandler {

    private ReactInstanceManager mReactInstanceManager;
    private ReactRootView mReactRootView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
      super.onCreate(savedInstanceState);
      mReactRootView = new ReactRootView(this);

      mReactInstanceManager = ReactInstanceManager.builder()
        .setApplication(getApplication())
        .setBundleAssetName("index.android.bundle")
        .setJSMainModuleName("index.android")
        .addPackage(new MainReactPackage())
+     .addPackage(new ReactNativeIntlPackage())
          .setUseDeveloperSupport(BuildConfig.DEBUG)
          .setInitialLifecycleState(LifecycleState.RESUMED)
          .build();

        mReactRootView.startReactApplication(mReactInstanceManager, "MyApp", null);

        setContentView(mReactRootView);
      }
      ...
    }
  ```

4. To translate messages, create `i18n` folder and put `.mo` files into it. Then, copy/link the folder into `android/app/src/main/assets`. You may need to create the `assets` folder.

## API

* **DateTimeFormat** objects are similar to JavaScript  [Intl.DateTimeFormat](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/DateTimeFormat) except `format` method returns a Promise.
* **NumberFormat** objects are similar to JavaScript [Intl.NumberFormat](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/NumberFormat) except `format` method returns a Promise.
* **Translation** objects load translation catalog from local file system and translates the passed message into another language. It also supports plural forms.
  * Constructor can take a locale identifier as an argument.

    ```
    new Intl.Translation([locale])
    ```

  * `getTranslator` returns a Promise that contains message translator function which takes two arguments, message id and optional plural counter. If the function can't find a proper string, it returns the message id.

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

Load `react-native-intl` module in your JavaScript code and create an translation instance with a your locale. Then, call `translate` method that takes message id and optional plural counter. Note that it returns a Promise.

```
const Intl = require('react-native-intl');
const french = new Intl.Translation('fr-FR');

french.getTranslator().then( _ => {
  console.log(_("Hello")); // "Allô"
  console.log(_("Not translated message")); // "Not translated message" returns the original message
  console.log(_("one product")); // "un produit"
  console.log(_("%d products", 2)); // "%d produits"

  /*
   Actually singular/plural messages share message id.
   You can get plural messages with singular id and vice versa.
  */
  consoel.log(_("one product", 2)); // "%d produits"
  consoel.log(_("%d product", 1)); // "un produit"
});
```

## Why gettext `.mo` files?

Although I prefer to use `json` format in most cases, `mo` format is better as it supports plural form and context. I don't want to embed `po` files in my app due to its bigger footprint.

## Notes

Because of the difference of platforms, some features can be limited based on platform.
The following table shows what features supported on each platform.

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

If you find anything, don't hesitate to leave your feedback.
I will welcome any contributions from you including pull requests, bug reports, suggestions and even English correction (because it is not my native tongue).
