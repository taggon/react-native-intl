/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 */
'use strict';

const React = require('react-native');
const { AppRegistry, StyleSheet, Text, View, ActionSheetIOS } = React;
const Intl = require('react-native-intl');

var Hello = React.createClass({
  getInitialState() {
    return {
      _(msgid){ return msgid },
      today: '',
      number: '',
      currency: ''
    }
  },

  componentDidMount() {
    this.onChangeLanguage('en-US');
  },

  showActionSheet() {
    ActionSheetIOS.showActionSheetWithOptions(
      {
	options: ['English', 'Français', '한국어']
      },
      (buttonIndex) => {
	this.onChangeLanguage(['en-US', 'fr-FR', 'ko-KR'][buttonIndex]);
      }
    );
  },

  async onChangeLanguage(localeIdentifier) {
    const dateFormatter = new Intl.DateTimeFormat(localeIdentifier, {year:'numeric', month:'2-digit', day:'2-digit', hour:'2-digit', minute:'2-digit', second:'2-digit', hour12:false});

    this.setState({
      today: await dateFormatter.format(new Date()),
      integer: await (new Intl.NumberFormat(localeIdentifier)).format(123456),
      number: await (new Intl.NumberFormat(localeIdentifier)).format(123456.78),
      currency: await (new Intl.NumberFormat(localeIdentifier, {style:'currency'})).format(123456.78),
      _: await (new Intl.Translation(localeIdentifier)).getTranslator()
    });
  },

  render() {
    return (
      <View style={styles.container}>
        <Text style={styles.hello}>
	  {this.state._("Hello, it's me")}
        </Text>
        <Text style={styles.date}>
	  {this.state.today}
        </Text>
        <Text style={styles.number}>
	  {this.state.integer}
        </Text>
        <Text style={styles.number}>
	  {this.state.number}
        </Text>
        <Text style={styles.number}>
	  {this.state.currency}
        </Text>
	<Text onPress={this.showActionSheet} style={styles.button}>
	  {this.state._("Click to change your language")}
	</Text>
      </View>
    );
  }
});

var styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  hello: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
  },
  number: {
    textAlign: 'center',
    color: '#333333',
    marginBottom: 5,
  },
});

AppRegistry.registerComponent('Hello', () => Hello);
