/*
 * Copyright (C) 2016 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.android.server.wifi;

import static org.junit.Assert.*;
import static org.mockito.Mockito.*;

import android.content.Context;
import android.telephony.TelephonyManager;

import androidx.test.filters.SmallTest;

import com.android.wifi.resources.R;

import org.junit.Before;
import org.junit.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;

/**
 * Unit tests for {@link com.android.server.wifi.WifiCountryCode}.
 */
@SmallTest
public class WifiCountryCodeTest extends WifiBaseTest {

    private static final String TAG = "WifiCountryCodeTest";
    private String mDefaultCountryCode = "US";
    private String mTelephonyCountryCode = "JP";
    private boolean mRevertCountryCodeOnCellularLoss = true;
    @Mock Context mContext;
    MockResources mResources = new MockResources();
    @Mock TelephonyManager mTelephonyManager;
    @Mock ActiveModeWarden mActiveModeWarden;
    @Mock ClientModeManager mClientModeManager;
    private WifiCountryCode mWifiCountryCode;
    private List<ClientModeManager> mClientModeManagers;

    /**
     * Setup test.
     */
    @Before
    public void setUp() throws Exception {
        MockitoAnnotations.initMocks(this);

        mClientModeManagers = Arrays.asList(mClientModeManager, mock(ClientModeManager.class));
        when(mActiveModeWarden.getClientModeManagers()).thenReturn(mClientModeManagers);

        when(mClientModeManager.setCountryCode(anyString())).thenReturn(true);
        when(mContext.getSystemService(Context.TELEPHONY_SERVICE))
                .thenReturn(mTelephonyManager);

        createWifiCountryCode();
    }

    private void createWifiCountryCode() {
        mResources.setBoolean(R.bool.config_wifi_revert_country_code_on_cellular_loss,
                mRevertCountryCodeOnCellularLoss);
        when(mContext.getResources()).thenReturn(mResources);
        mWifiCountryCode = new WifiCountryCode(
                mContext,
                mActiveModeWarden,
                mDefaultCountryCode);
    }

    /**
     * Test if we do not receive country code from Telephony.
     * @throws Exception
     */
    @Test
    public void useDefaultCountryCode() throws Exception {
        // Supplicant started.
        mWifiCountryCode.setReadyForChange(true);
        // Wifi get L2 connected.
        mWifiCountryCode.setReadyForChange(false);
        verify(mClientModeManager).setCountryCode(anyString());
        assertEquals(mDefaultCountryCode, mWifiCountryCode.getCountryCodeSentToDriver());
    }

    /**
     * Test that we read the country code from telephony at bootup.
     * @throws Exception
     */
    @Test
    public void useTelephonyCountryCodeOnBootup() throws Exception {
        when(mTelephonyManager.getNetworkCountryIso()).thenReturn(mTelephonyCountryCode);
        // Supplicant started.
        mWifiCountryCode.setReadyForChange(true);
        // Wifi get L2 connected.
        mWifiCountryCode.setReadyForChange(false);
        verify(mClientModeManager).setCountryCode(anyString());
        assertEquals(mTelephonyCountryCode, mWifiCountryCode.getCountryCodeSentToDriver());
    }

    /**
     * Test if we receive country code from Telephony before supplicant starts.
     * @throws Exception
     */
    @Test
    public void useTelephonyCountryCodeOnChange() throws Exception {
        mWifiCountryCode.setCountryCodeAndUpdate(mTelephonyCountryCode);
        assertEquals(null, mWifiCountryCode.getCountryCodeSentToDriver());
        // Supplicant started.
        mWifiCountryCode.setReadyForChange(true);
        // Wifi get L2 connected.
        mWifiCountryCode.setReadyForChange(false);
        verify(mClientModeManager).setCountryCode(anyString());
        assertEquals(mTelephonyCountryCode, mWifiCountryCode.getCountryCodeSentToDriver());
    }

    /**
     * Test if we receive country code from Telephony after supplicant starts.
     * @throws Exception
     */
    @Test
    public void telephonyCountryCodeChangeAfterSupplicantStarts() throws Exception {
        // Supplicant starts.
        mWifiCountryCode.setReadyForChange(true);
        assertEquals(mDefaultCountryCode, mWifiCountryCode.getCountryCodeSentToDriver());
        // Telephony country code arrives.
        mWifiCountryCode.setCountryCodeAndUpdate(mTelephonyCountryCode);
        // Wifi get L2 connected.
        mWifiCountryCode.setReadyForChange(false);
        verify(mClientModeManager, times(2)).setCountryCode(anyString());
        assertEquals(mTelephonyCountryCode, mWifiCountryCode.getCountryCodeSentToDriver());
    }

    /**
     * Test if we receive country code from Telephony after we get L2 connected.
     * @throws Exception
     */
    @Test
    public void telephonyCountryCodeChangeAfterL2Connected() throws Exception {
        // Supplicant starts.
        mWifiCountryCode.setReadyForChange(true);
        // Wifi get L2 connected.
        mWifiCountryCode.setReadyForChange(false);
        // Telephony country code arrives.
        mWifiCountryCode.setCountryCodeAndUpdate(mTelephonyCountryCode);
        // Telephony coutry code won't be applied at this time.
        assertEquals(mDefaultCountryCode, mWifiCountryCode.getCountryCodeSentToDriver());
        mWifiCountryCode.setReadyForChange(true);
        // Telephony coutry is applied after supplicant is ready.
        verify(mClientModeManager, times(2)).setCountryCode(anyString());
        assertEquals(mTelephonyCountryCode, mWifiCountryCode.getCountryCodeSentToDriver());
    }

    /**
     * Test if we can reset to the default country code when phone is out of service, when
     * |config_wifi_revert_country_code_on_cellular_loss| is set to true;
     * Telephony service calls |setCountryCode| with an empty string when phone is out of service.
     * In this case we should fall back to the default country code.
     * @throws Exception
     */
    @Test
    public void resetCountryCodeWhenOutOfService() throws Exception {
        assertEquals(mDefaultCountryCode, mWifiCountryCode.getCountryCode());
        mWifiCountryCode.setCountryCodeAndUpdate(mTelephonyCountryCode);
        assertEquals(mTelephonyCountryCode, mWifiCountryCode.getCountryCode());
        // Out of service.
        mWifiCountryCode.setCountryCodeAndUpdate("");
        assertEquals(mDefaultCountryCode, mWifiCountryCode.getCountryCode());
    }

    /**
     * Test if we can keep using the last known country code when phone is out of service, when
     * |config_wifi_revert_country_code_on_cellular_loss| is set to false;
     * Telephony service calls |setCountryCode| with an empty string when phone is out of service.
     * In this case we should keep using the last known country code.
     * @throws Exception
     */
    @Test
    public void doNotResetCountryCodeWhenOutOfService() throws Exception {
        // Refresh mWifiCountryCode with |config_wifi_revert_country_code_on_cellular_loss|
        // setting to false.
        mRevertCountryCodeOnCellularLoss = false;
        createWifiCountryCode();

        assertEquals(mDefaultCountryCode, mWifiCountryCode.getCountryCode());
        mWifiCountryCode.setCountryCodeAndUpdate(mTelephonyCountryCode);
        assertEquals(mTelephonyCountryCode, mWifiCountryCode.getCountryCode());
        // Out of service.
        mWifiCountryCode.setCountryCodeAndUpdate("");
        assertEquals(mTelephonyCountryCode, mWifiCountryCode.getCountryCode());
    }

    /**
     * Tests that we always use the US locale for converting the provided country code regardless
     * of the system locale set.
     */
    @Test
    public void useUSLocaleForConversionToUpperCase() {
        String oemCountryCodeLower = "us";
        String oemCountryCodeUpper = "US";
        String telephonyCountryCodeLower = "il";
        String telephonyCountryCodeUpper = "IL";

        mDefaultCountryCode = oemCountryCodeLower;
        createWifiCountryCode();

        // Set the default locale to "tr" (Non US).
        Locale.setDefault(new Locale("tr"));

        // Trigger a country code change using the OEM country code.
        mWifiCountryCode.setReadyForChange(true);
        verify(mClientModeManager).setCountryCode(oemCountryCodeUpper);

        // Now trigger a country code change using the telephony country code.
        mWifiCountryCode.setCountryCodeAndUpdate(telephonyCountryCodeLower);
        verify(mClientModeManager).setCountryCode(telephonyCountryCodeUpper);
    }
    /**
     * Verifies that dump() does not fail
     */
    @Test
    public void dumpDoesNotFail() {
        StringWriter sw = new StringWriter();
        PrintWriter pw = new PrintWriter(sw);

        mRevertCountryCodeOnCellularLoss = false;
        createWifiCountryCode();

        mWifiCountryCode.dump(null, pw, null);
        String dumpCountryCodeStr = sw.toString();

        assertTrue(dumpCountryCodeStr.contains("mDriverCountryCode"));
        assertTrue(dumpCountryCodeStr.contains("mTelephonyCountryCode"));
        assertTrue(dumpCountryCodeStr.contains("mDefaultCountryCode"));
        assertTrue(dumpCountryCodeStr.contains("mTelephonyCountryTimestamp"));
        assertTrue(dumpCountryCodeStr.contains("mDriverCountryTimestamp"));
        assertTrue(dumpCountryCodeStr.contains("mReadyTimestamp"));
        assertTrue(dumpCountryCodeStr.contains("mReady"));
    }
}
