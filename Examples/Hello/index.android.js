/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */

import React, { Component } from 'react';
import {
  AppRegistry,
  StyleSheet,
  Text,
  View,
  Alert
} from 'react-native';
import Intl from 'react-native-intl';

export default class Hello extends Component {
  constructor() {
    super();
    this.state = {
      _(msgid){ return msgid },
      today: '',
      number: '',
      currency: '',
    };
    this.showLanguages = this.showLanguages.bind(this);
  }

  componentDidMount() {
    this.onChangeLanguage('en-US');
  }

  async onChangeLanguage(localeIdentifier) {
    const dateFormatter = new Intl.DateTimeFormat(localeIdentifier, {year:'numeric', month:'2-digit', day:'2-digit', hour:'2-digit', minute:'2-digit', second:'2-digit', hour12:false});

    this.setState({
      today: await dateFormatter.format(new Date()),
      integer: await (new Intl.NumberFormat(localeIdentifier)).format(123456),
      number: await (new Intl.NumberFormat(localeIdentifier)).format(123456.78),
      currency: await (new Intl.NumberFormat(localeIdentifier, {style:'currency'})).format(123456.78),
      _: await (new Intl.Translation(localeIdentifier)).getTranslator()
    });
  }

  showLanguages() {
    Alert.alert(
      'Languages',
      '',
      [
        {text:'English', onPress: ()=>this.onChangeLanguage('en-US') },
        {text:'Français', onPress: ()=>this.onChangeLanguage('fr-FR') },
        {text:'한국어', onPress: ()=>this.onChangeLanguage('ko-KR') }
      ]
    );
  }

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
        <Text onPress={this.showLanguages} style={styles.button}>
          {this.state._("Click to change your language")}
        </Text>
      </View>
    );
  }
}

const styles = StyleSheet.create({
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
  date: {
    textAlign: 'center',
    color: '#333333',
    marginBottom: 5,
  },
  number: {
    textAlign: 'center',
    color: '#333333',
    marginBottom: 5,
  },
  button: {
    textAlign: 'center',
    backgroundColor: '#dddddd',
    padding: 15,
    marginTop: 20
  }
});

AppRegistry.registerComponent('Hello', () => Hello);
