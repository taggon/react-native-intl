package kim.taegon.rnintl;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.common.MapBuilder;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;

import java.io.IOException;
import java.io.InputStream;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.Arrays;
import java.util.ArrayList;
import java.util.Locale;
import java.util.Date;
import java.util.Set;
import java.util.HashSet;
import java.util.Currency;
import java.text.NumberFormat;
import java.text.SimpleDateFormat;
import java.util.StringTokenizer;
import java.util.TimeZone;

import javax.annotation.Nullable;

import android.content.Context;
import android.text.format.DateFormat;

public class ReactNativeIntl extends ReactContextBaseJavaModule {
	public ReactNativeIntl(ReactApplicationContext reactContext) {
		super(reactContext);
	}

	@Override
	public String getName() {
		return "RNIntl";
	}

	@Override
	public Map<String, Object> getConstants() {
		MapBuilder.Builder<String, Object> builder = MapBuilder.builder();

		builder.put("systemLocale", getSystemLocale());
		builder.put("languages", getAvailableLocales());
		builder.put("availableLocales", getAvailableLocales());
		builder.put("availableCalendars", "");

		return builder.build();
	}

    @ReactMethod
    public void formatNumber(double number, String localeIdenfitier, @Nullable ReadableMap options, Promise promise) {
        Locale locale;

        try {
            locale = Locale.forLanguageTag(localeIdenfitier);
        } catch(Exception e) {
            // fallback
            locale = Locale.forLanguageTag(getSystemLocale().replace('-', '_'));
        }

        try {
            NumberFormat nf = NumberFormat.getInstance(locale);

            if (options != null) {
                String style = options.hasKey("style") ? options.getString("style") : "decimal";
                if (style.equals("currency")) {
                    nf = NumberFormat.getCurrencyInstance(locale);

                    // currency
                    if (options.hasKey("currency")) {
                        nf.setCurrency(Currency.getInstance(options.getString("currency")));
                    }

                    // TODO: currencyDisplay
                } else if (style.equals("percent")) {
                    nf = NumberFormat.getPercentInstance(locale);
                }

                // useGrouping
                nf.setGroupingUsed(!options.hasKey("useGrouping") || options.getBoolean("useGrouping"));

                // minimumIntegerDigits
                if (options.hasKey("minimumIntegerDigits")) {
                    int minimumIntegerDigits = options.getInt("minimumIntegerDigits");
                    if (0 < minimumIntegerDigits && minimumIntegerDigits < 22) {
                        nf.setMinimumIntegerDigits(minimumIntegerDigits);
                    }
                }

                // minimumFractionDigits
                if (options.hasKey("minimumFractionDigits")) {
                    int minimumFractionDigits = options.getInt("minimumFractionDigits");
                    if (-1 < minimumFractionDigits && minimumFractionDigits < 21) {
                        nf.setMinimumFractionDigits(minimumFractionDigits);
                    }
                }

                // maximumFractionDigits
                if (options.hasKey("maximumFractionDigits")) {
                    int maximumFractionDigits = options.getInt("maximumFractionDigits");
                    if (-1 < maximumFractionDigits && maximumFractionDigits < 21) {
                        nf.setMaximumFractionDigits(maximumFractionDigits);
                    }
                }

                // minimumSignificantDigits - not supported
                // maximumSignificantDigits - not supported
            }

            promise.resolve(nf.format(number));
        } catch(Exception e) {
            promise.reject(e.getMessage());
        }
    }

    @ReactMethod
    public void formatDate(double dateTime, String localeIdentifier, @Nullable ReadableMap options, Promise promise) {
        Locale locale;

        try {
            locale = Locale.forLanguageTag(localeIdentifier);
        } catch (Exception e) {
            // fallback
            locale = Locale.forLanguageTag(getSystemLocale().replace('-', '_'));
        }

        try {
            Date date = new Date(Double.valueOf((dateTime)).longValue());
            SimpleDateFormat df = new SimpleDateFormat();

            if (options != null) {
                // TODO: calendar - I can't find how android support various calendars yet

                // timezone
                if (options.hasKey("timeZone")) {
                    // TODO: should I check validation of the option?
                    TimeZone tz = TimeZone.getTimeZone(options.getString("timeZone"));
                    df.setTimeZone(tz);
                }

		String pattern = DateFormat.getBestDateTimePattern(locale, options.getString("template"));

                // hour12
                if (options.hasKey("hour12")) {
		  if (options.getBoolean("hour12")) {
		    pattern = pattern.replace('H', 'h');
		  } else {
		    pattern = pattern.replace('h', 'H');
		  }
                }

		df.applyLocalizedPattern(pattern);
            }

            promise.resolve(df.format(date));
        } catch (Exception e) {
            promise.reject(e.getMessage());
        }
    }

    @ReactMethod
    public void loadCatalog(String localeIdentifier, Promise promise) {
         try {
             Locale locale = Locale.forLanguageTag(localeIdentifier);
             Context context = getReactApplicationContext().getApplicationContext();
             InputStream stream = null;
	     String assetDir = "i18n/";
	     String assetName = localeIdentifier.replace('-', '_');

             try {
                 stream = context.getAssets().open(assetDir+assetName+".mo");
             } catch(IOException e) {
                 // fallback - using language only
                 stream = context.getAssets().open(assetDir+locale.getLanguage()+".mo");
             }

             GettextParser parser = new GettextParser(stream);
             Map<String, Object> rawCatalog = parser.getCatalog();

             WritableMap catalog = Arguments.createMap();
             WritableMap headers = Arguments.createMap();
             WritableMap translations = Arguments.createMap();

             // headers
             if (rawCatalog.containsKey("headers")) {
                 for (Map.Entry<String, String> entry : ((Map<String, String>)rawCatalog.get("headers")).entrySet()) {
                     headers.putString(entry.getKey(), entry.getValue());
                 }
             }

             // translations
             if (rawCatalog.containsKey("translations")) {
                 for (Map.Entry<String, String[]> entry: ((Map<String, String[]>)rawCatalog.get("translations")).entrySet()) {
                     WritableArray messages = Arguments.createArray();
                     for (String msg: entry.getValue()) {
                         messages.pushString(msg);
                     }
                     translations.putArray(entry.getKey(), messages);
                 }
             }

             catalog.putMap("headers", headers);
             catalog.putMap("translations", translations);

             promise.resolve(catalog);
         } catch(Exception e) {
             promise.reject(e.getMessage());
         }
    }

    protected String getSystemLocale() {
        String localeIdentifier = getReactApplicationContext().getResources().getConfiguration().locale.toString();
        return localeIdentifier.replace('_', '-');
    }

	protected List<String> getAvailableLocales() {
		Locale[] locales = Locale.getAvailableLocales();
        List<String> langs = new ArrayList<>(locales.length);

		for (Locale locale: locales) langs.add(locale.toString().replace('_', '-'));

		return langs;
	}
}
