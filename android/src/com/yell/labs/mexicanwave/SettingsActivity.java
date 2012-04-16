package com.yell.labs.mexicanwave;

import android.graphics.Color;
import android.os.Bundle;
import android.preference.ListPreference;
import android.preference.Preference;
import android.preference.Preference.OnPreferenceChangeListener;
import android.preference.PreferenceActivity;
import android.provider.Settings;


public class SettingsActivity extends PreferenceActivity  implements OnPreferenceChangeListener {

	private static final String PREF_GROUP_SIZE = "pref_group_size";
	private static final String PREF_COLOR = "pref_color";

	ListPreference pref_color;
	
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		
			
	}
	
	
	@Override
	public boolean onPreferenceChange(Preference preference, Object newValue) {
		if (preference == pref_color) {

            int colorValue = Color.parseColor(String.valueOf(newValue)) ;
            Settings.System.putInt(getContentResolver(), "", colorValue);
    

            return true;

		}

		
		return false;
	}
	
	
}