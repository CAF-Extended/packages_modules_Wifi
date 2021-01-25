/**
 * Copyright (c) 2008, The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package android.net.wifi;

import android.net.wifi.hotspot2.OsuProvider;
import android.net.wifi.hotspot2.PasspointConfiguration;
import android.net.wifi.hotspot2.IProvisioningCallback;

import android.net.DhcpInfo;
import android.net.Network;
import android.net.wifi.CoexUnsafeChannel;
import android.net.wifi.IActionListener;
import android.net.wifi.ICoexCallback;
import android.net.wifi.IDppCallback;
import android.net.wifi.ILocalOnlyHotspotCallback;
import android.net.wifi.INetworkRequestMatchCallback;
import android.net.wifi.IOnWifiActivityEnergyInfoListener;
import android.net.wifi.IOnWifiUsabilityStatsListener;
import android.net.wifi.IScanResultsCallback;
import android.net.wifi.ISoftApCallback;
import android.net.wifi.ISuggestionConnectionStatusListener;
import android.net.wifi.ISuggestionUserApprovalStatusListener;
import android.net.wifi.ITrafficStateCallback;
import android.net.wifi.IWifiConnectedNetworkScorer;
import android.net.wifi.ScanResult;
import android.net.wifi.SoftApConfiguration;
import android.net.wifi.WifiConfiguration;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiNetworkSuggestion;

import android.os.Messenger;
import android.os.ResultReceiver;
import android.os.WorkSource;

import com.android.modules.utils.ParceledListSlice;

/**
 * Interface that allows controlling and querying Wi-Fi connectivity.
 *
 * {@hide}
 */
interface IWifiManager
{
    long getSupportedFeatures();

    oneway void getWifiActivityEnergyInfoAsync(in IOnWifiActivityEnergyInfoListener listener);

    ParceledListSlice getConfiguredNetworks(String packageName, String featureId);

    ParceledListSlice getPrivilegedConfiguredNetworks(String packageName, String featureId);

    Map getAllMatchingFqdnsForScanResults(in List<ScanResult> scanResult);

    Map getMatchingOsuProviders(in List<ScanResult> scanResult);

    Map getMatchingPasspointConfigsForOsuProviders(in List<OsuProvider> osuProviders);

    int addOrUpdateNetwork(in WifiConfiguration config, String packageName);

    boolean addOrUpdatePasspointConfiguration(in PasspointConfiguration config, String packageName);

    boolean removePasspointConfiguration(in String fqdn, String packageName);

    List<PasspointConfiguration> getPasspointConfigurations(in String packageName);

    List<WifiConfiguration> getWifiConfigsForPasspointProfiles(in List<String> fqdnList);

    void queryPasspointIcon(long bssid, String fileName);

    int matchProviderWithCurrentNetwork(String fqdn);

    boolean removeNetwork(int netId, String packageName);

    boolean enableNetwork(int netId, boolean disableOthers, String packageName);

    boolean disableNetwork(int netId, String packageName);

    void allowAutojoinGlobal(boolean choice);

    void allowAutojoin(int netId, boolean choice);

    void allowAutojoinPasspoint(String fqdn, boolean enableAutoJoin);

    void setMacRandomizationSettingPasspointEnabled(String fqdn, boolean enable);

    void setPasspointMeteredOverride(String fqdn, int meteredOverride);

    boolean startScan(String packageName, String featureId);

    List<ScanResult> getScanResults(String callingPackage, String callingFeatureId);

    boolean disconnect(String packageName);

    boolean reconnect(String packageName);

    boolean reassociate(String packageName);

    WifiInfo getConnectionInfo(String callingPackage, String callingFeatureId);

    boolean setWifiEnabled(String packageName, boolean enable);

    int getWifiEnabledState();

    String getCountryCode();

    boolean is5GHzBandSupported();

    boolean is6GHzBandSupported();

    boolean is60GHzBandSupported();

    boolean isWifiStandardSupported(int standard);

    DhcpInfo getDhcpInfo(String packageName);

    void setScanAlwaysAvailable(boolean isAvailable, String packageName);

    boolean isScanAlwaysAvailable();

    boolean acquireWifiLock(IBinder lock, int lockType, String tag, in WorkSource ws);

    void updateWifiLockWorkSource(IBinder lock, in WorkSource ws);

    boolean releaseWifiLock(IBinder lock);

    void initializeMulticastFiltering();

    boolean isMulticastEnabled();

    void acquireMulticastLock(IBinder binder, String tag);

    void releaseMulticastLock(String tag);

    void updateInterfaceIpState(String ifaceName, int mode);

    boolean isDefaultCoexAlgorithmEnabled();

    void setCoexUnsafeChannels(in List<CoexUnsafeChannel> unsafeChannels, int mandatoryRestrictions);

    List<CoexUnsafeChannel> getCoexUnsafeChannels();

    int getCoexRestrictions();

    void registerCoexCallback(in ICoexCallback callback);

    void unregisterCoexCallback(in ICoexCallback callback);

    boolean startSoftAp(in WifiConfiguration wifiConfig, String packageName);

    boolean startTetheredHotspot(in SoftApConfiguration softApConfig, String packageName);

    boolean stopSoftAp();

    int startLocalOnlyHotspot(in ILocalOnlyHotspotCallback callback, String packageName,
                              String featureId, in SoftApConfiguration customConfig);

    void stopLocalOnlyHotspot();

    void startWatchLocalOnlyHotspot(in ILocalOnlyHotspotCallback callback);

    void stopWatchLocalOnlyHotspot();

    @UnsupportedAppUsage
    int getWifiApEnabledState();

    @UnsupportedAppUsage
    WifiConfiguration getWifiApConfiguration();

    SoftApConfiguration getSoftApConfiguration();

    boolean setWifiApConfiguration(in WifiConfiguration wifiConfig, String packageName);

    boolean setSoftApConfiguration(in SoftApConfiguration softApConfig, String packageName);

    void notifyUserOfApBandConversion(String packageName);

    void enableTdls(String remoteIPAddress, boolean enable);

    void enableTdlsWithMacAddress(String remoteMacAddress, boolean enable);

    String getCurrentNetworkWpsNfcConfigurationToken();

    void enableVerboseLogging(int verbose);

    int getVerboseLoggingLevel();

    void disableEphemeralNetwork(String SSID, String packageName);

    void factoryReset(String packageName);

    @UnsupportedAppUsage(maxTargetSdk = 30, trackingBug = 170729553)
    Network getCurrentNetwork();

    byte[] retrieveBackupData();

    void restoreBackupData(in byte[] data);

    byte[] retrieveSoftApBackupData();

    SoftApConfiguration restoreSoftApBackupData(in byte[] data);

    void restoreSupplicantBackupData(in byte[] supplicantData, in byte[] ipConfigData);

    void startSubscriptionProvisioning(in OsuProvider provider, in IProvisioningCallback callback);

    void registerSoftApCallback(in IBinder binder, in ISoftApCallback callback, int callbackIdentifier);

    void unregisterSoftApCallback(int callbackIdentifier);

    void addOnWifiUsabilityStatsListener(in IBinder binder, in IOnWifiUsabilityStatsListener listener, int listenerIdentifier);

    void removeOnWifiUsabilityStatsListener(int listenerIdentifier);

    void registerTrafficStateCallback(in IBinder binder, in ITrafficStateCallback callback, int callbackIdentifier);

    void unregisterTrafficStateCallback(int callbackIdentifier);

    String getCapabilities(String capaType);

    void registerNetworkRequestMatchCallback(in IBinder binder, in INetworkRequestMatchCallback callback, int callbackIdentifier);

    void unregisterNetworkRequestMatchCallback(int callbackIdentifier);

    int addNetworkSuggestions(in List<WifiNetworkSuggestion> networkSuggestions, in String packageName,
        in String featureId);

    int removeNetworkSuggestions(in List<WifiNetworkSuggestion> networkSuggestions, in String packageName);

    List<WifiNetworkSuggestion> getNetworkSuggestions(in String packageName);

    String[] getFactoryMacAddresses();

    void setDeviceMobilityState(int state);

    void startDppAsConfiguratorInitiator(in IBinder binder, in String enrolleeUri,
        int selectedNetworkId, int netRole, in IDppCallback callback);

    void startDppAsEnrolleeInitiator(in IBinder binder, in String configuratorUri,
        in IDppCallback callback);

    void startDppAsEnrolleeResponder(in IBinder binder, in String deviceInfo, int curve,
        in IDppCallback callback);

    void stopDppSession();

    void updateWifiUsabilityScore(int seqNum, int score, int predictionHorizonSec);

    oneway void connect(in WifiConfiguration config, int netId, in IActionListener listener);

    oneway void save(in WifiConfiguration config, in IActionListener listener);

    oneway void forget(int netId, in IActionListener listener);

    void registerScanResultsCallback(in IScanResultsCallback callback);

    void unregisterScanResultsCallback(in IScanResultsCallback callback);

    void registerSuggestionConnectionStatusListener(in IBinder binder, in ISuggestionConnectionStatusListener listener, int listenerIdentifier, String packageName, String featureId);

    void unregisterSuggestionConnectionStatusListener(int listenerIdentifier, String packageName);

    int calculateSignalLevel(int rssi);

    List<WifiConfiguration> getWifiConfigForMatchedNetworkSuggestionsSharedWithUser(in List<ScanResult> scanResults);

    boolean setWifiConnectedNetworkScorer(in IBinder binder, in IWifiConnectedNetworkScorer scorer);

    void clearWifiConnectedNetworkScorer();

    /**
     * Return the Map of {@link WifiNetworkSuggestion} and the list of <ScanResult>
     */
    Map getMatchingScanResults(in List<WifiNetworkSuggestion> networkSuggestions, in List<ScanResult> scanResults, String callingPackage, String callingFeatureId);

    void setScanThrottleEnabled(boolean enable);

    boolean isScanThrottleEnabled();

    Map getAllMatchingPasspointProfilesForScanResults(in List<ScanResult> scanResult);

    void setAutoWakeupEnabled(boolean enable);

    boolean isAutoWakeupEnabled();

    int getNetworkSuggestionUserApprovalStatus(String packageName);

    void startTemporarilyDisablingAllNonCarrierMergedWifi(int subId);

    void stopTemporarilyDisablingAllNonCarrierMergedWifi();

    void setCarrierNetworkOffloadEnabled(int subscriptionId, boolean merged, boolean enabled);

    boolean isCarrierNetworkOffloadEnabled(int subscriptionId, boolean merged);

    void restartWifiSubsystem(String reason);

    boolean addSuggestionUserApprovalStatusListener(in IBinder binder, in ISuggestionUserApprovalStatusListener listener, int listenerIdentifier, String packageName, String featureId);

    void removeSuggestionUserApprovalStatusListener(int listenerIdentifier, String packageName);

    int getSoftApWifiStandard();

    boolean isVht8ssCapableDevice();
}