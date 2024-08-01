/*
       Licensed to the Apache Software Foundation (ASF) under one
       or more contributor license agreements.  See the NOTICE file
       distributed with this work for additional information
       regarding copyright ownership.  The ASF licenses this file
       to you under the Apache License, Version 2.0 (the
       "License"); you may not use this file except in compliance
       with the License.  You may obtain a copy of the License at
         http://www.apache.org/licenses/LICENSE-2.0
       Unless required by applicable law or agreed to in writing,
       software distributed under the License is distributed on an
       "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
       KIND, either express or implied.  See the License for the
       specific language governing permissions and limitations
       under the License.
 */
package ai.riskzero.zg.manager;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import org.apache.cordova.*;
import android.content.Intent;
import by.chemerisuk.cordova.firebase.FirebaseMessagingPluginService;
import android.util.Log;
public class MainActivity extends CordovaActivity
{
    private static final String TAG = "MainActivity";
    private String pendingNavigationUrl = "http://localhost/#";
    private boolean restart = false;
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        Log.d(TAG, "onCreate called");
        // enable Cordova apps to be started in the background
        Bundle extras = getIntent().getExtras();
        if (extras != null && extras.getBoolean("cdvStartInBackground", false)) {
            moveTaskToBack(true);
        }
        // Set by <content src="index.html" /> in config.xml
//        loadUrl(launchUrl);
        handleIntent(getIntent());
    }
    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        Log.d(TAG, "onNewIntent called");
//        setIntent(intent);
        handleIntent(intent);
    }
    private void handleIntent(Intent intent) {
        if (intent.getExtras() != null) {
            for (String key : intent.getExtras().keySet()) {
                Object value = intent.getExtras().get(key);
                Log.d("data ", "Key: " + key + " Value: " + value);
            }
        }
        if (intent.hasExtra(FirebaseMessagingPluginService.EXTRA_NAVIGATE_TO)) {
            String url = intent.getExtras().get(FirebaseMessagingPluginService.EXTRA_NAVIGATE_TO).toString();
            Log.d("MainActivity.url: ", url);
            if (url != null && !url.isEmpty()) {
                /// loadUrl( "javascript:window.location.href='#" +url+"'");
             loadUrl("javascript:setTimeout(function() { window.location.hash = '"+url+"'; }, 100);");
            }
        } else if (intent.getExtras() != null) {
            String url = intent.getExtras().get("navigateTo").toString();
            Log.d("MainActivity.url: ", url);
            if (url != null && !url.isEmpty()) {
                 if(restart){
                    loadUrl("javascript:setTimeout(function() { window.location.hash = '"+url+"'; }, 100);");
                 } else {
                    loadUrl("http://localhost/#" + url);
                 }
            }
        } else {
            loadUrl(launchUrl);
        }
    }
     @Override
    protected void onResume() {
        super.onResume();
        Log.d(TAG, "onResume called");
//        setIntent(intent);
        restart = true;
    }
}
