#!/bin/bash
#
# STP
#
# ReleaseDate: 20210902
# Created by Cartor on 2019-06-13.
# Changed by Tim to include homebrew on 2024-07-10.
# Run with sudo ./path/to/script.sh -d yourcodehere -w 0 -s 0

#----------------common function start-----------------------#

function exceCMD() {
    cmd="${1}"
    echo "${cmd}" | sh
}

function plist_WriteOption() {
    FILENAME="${1}"
    KEY="${2}"
    VALUE="${3}"
    TYPE="${4}"
    
    sed "s/REPLACE_STRING/${2}/g" <<- EOF >> "${FILENAME}"
            <key>REPLACE_STRING</key>
EOF

    if [ "${TYPE}" == "bool" ]; then
        sed "s/REPLACE_STRING/${3}/g" <<- EOF >> "${FILENAME}"
             <REPLACE_STRING/>
EOF
    elif [ "${TYPE}" == "int" ]; then
        sed "s/REPLACE_STRING/${3}/g" <<- EOF >> "${FILENAME}"
             <integer>REPLACE_STRING</integer>
EOF
    elif [ "${TYPE}" == "data" ]; then
        sed "s/REPLACE_STRING/${3}/g" <<- EOF >> "${FILENAME}"
             <data>REPLACE_STRING</data>
EOF
    else
        sed "s/REPLACE_STRING/${3}/g" <<- EOF >> "${FILENAME}"
             <string>REPLACE_STRING</string>
EOF
    fi
}

function setDeployCode() {
    FILENAME="${1}"
    DCode="${2}"

    keys=("DeployCode" "DeployTeamNameCache" "DeployTeamOwnerCache" "LastDeployCode" "TeamCode" "TeamCodeInUse")
    values=("${DCode}" "" "" "" "" "")
    types=("string" "string" "string" "string" "string" "string")

    n=${#keys[@]}
    for (( i=0; i<n; i++ ))
    do
        key=${keys[i]}
        value=${values[i]}
        type=${types[i]}

        plist_WriteOption "${FILENAME}" "${key}" "${value}" "${type}"
    done
}

function setShowDeployLoginWarning() {
    FILENAME="${1}"

    ShowDeployLoginWarning="true"
    if [ "${2// }" == "0" ]; then
        ShowDeployLoginWarning="false"
    fi
    plist_WriteOption "${FILENAME}" "ShowDeployLoginWarning" "${ShowDeployLoginWarning}" "bool"
}

function setComputerName() {
    FILENAME="${1}"
    plist_WriteOption "${FILENAME}" "HostName" "${2}" "string"
}

function setPermissionProtectionOption() {
    FILENAME="${1}"
    REQUEST_PERMISSION="${2}"
    EnablePermissionProtection=""

    if [ -z "${REQUEST_PERMISSION// }" ]; then
        return
    fi

    EnablePermissionProtection="${REQUEST_PERMISSION// }"
    if [ ! -z "${EnablePermissionProtection// }" ]; then
        plist_WriteOption "${FILENAME}" "EnablePermissionProtection" "${EnablePermissionProtection}" "int"
    fi    
}

function setSecurityOption() {
    FILENAME="${1}"
    SECURITY_OPTION="${2}"

    EnableSecurityCodeProtection=""
    EnableOSCredential=""

    if [ "$SECURITY_OPTION" == "0" ]; then
        EnableSecurityCodeProtection="false"
        EnableOSCredential="false"
    fi

    if [ "$SECURITY_OPTION" == "1" ]; then
        EnableSecurityCodeProtection="true"
        EnableOSCredential="false"
    fi

    if [ "$SECURITY_OPTION" == "2" ]; then
        EnableSecurityCodeProtection="false"
        EnableOSCredential="true"
    fi
    
    if [ ! -z "${EnableSecurityCodeProtection// }" ]; then
        plist_WriteOption "${FILENAME}" "EnableSecurityCodeProtection" "${EnableSecurityCodeProtection}" "bool"
    fi

    if [ ! -z "${EnableOSCredential// }" ]; then
        plist_WriteOption "${FILENAME}" "EnableOSCredential" "${EnableOSCredential}" "bool"
    fi    
}

function setInitSecurityCode() {
    FILENAME="${1}"
    plist_WriteOption "${FILENAME}" "init_security_code" "${2}" "string"
}

function setLegacyConnectionLoopbackOnly() {
    FILENAME="${1}"
    plist_WriteOption "${FILENAME}" "LegacyConnectionLoopbackOnly" "true" "bool"
}

function setHideTrayIcon() {
    FILENAME="${1}"
    plist_WriteOption "${FILENAME}" "HideTrayIcon" "true" "bool"
}

function setDefaultClientDeviceName() {
    FILENAME="${1}"
    plist_WriteOption "${FILENAME}" "DefaultClientDeviceName" "${2}" "string"
}

function setShowStreamerUI() {
    FILENAME="${1}"

    keys=("FirstTimeClose" "FirstTimeLogin" "PermissionAlert")
    values=("false" "false" "false")
    types=("bool" "bool" "bool")

    n=${#keys[@]}
    for (( i=0; i<n; i++ ))
    do
        key=${keys[i]}
        value=${values[i]}
        type=${types[i]}

        plist_WriteOption "${FILENAME}" "${key}" "${value}" "${type}"
    done
}

function setEnableLanConnection() {
    FILENAME="${1}"

    plist_WriteOption "${FILENAME}" "EnableLanConnection" "false" "bool"
}

function setCommonDict() {
    FILENAME="${1}"
    STREAMER_TYPE="${2}"
    STREAMER="${3}"

    if [ "$STREAMER_TYPE" == "0" ]; then
        cat <<- EOF >> "${FILENAME}"
    <key>Common</key>
    <dict>
        <key>HidePreferenceDomainSelection</key>
        <true/>
        <key>EulaAccepted</key>
        <true/>
    </dict>
EOF
    else
        sed "s/REPLACE_STRING/${STREAMER_TYPE}/g" <<- EOF >> "${FILENAME}"
    <key>Common</key>
    <dict>
        <key>HidePreferenceDomainSelection</key>
        <true/>
        <key>EulaAccepted</key>
        <true/>
        <key>StreamerType</key>
        <integer>REPLACE_STRING</integer>
    </dict>
EOF
    fi
}

function setStreamerTypeDict() {
    FILENAME="${1}"
    STREAMER_TYPE="${2}"
    STREAMER="${3}"

    keys=()
    values=()
    types=()

    sed "s/REPLACE_STRING/${STREAMER}/g" <<- EOF >> "${FILENAME}"
    <key>REPLACE_STRING</key>
    <dict>
EOF

    if [ "$STREAMER_TYPE" == "0" ]; then
        keys+=("ShowDeployMode" "SplashtopAccount")
        values+=("true" "")
        types+=("bool" "string")
    fi

    if [ "$STREAMER_TYPE" == "1" ]; then
        keys+=("ShowDeployMode" "SplashtopAccount")
        values+=("true" "")
        types+=("bool" "string")
    fi

    if [ "$STREAMER_TYPE" == "2" ]; then
        keys+=("FirstTimeLogin" "BackendConnected" "ClientCertificateData" "CustomizeTeamCode" "FirstTimeLogin" "IsNewUUIDScheme" "RelayConnected")
        values+=("false" "true" "" "" "" "" "true")
        types+=("bool" "bool" "data" "string" "string" "string" "bool")
    fi

    n=${#keys[@]}
    for (( i=0; i<n; i++ ))
    do
        key=${keys[i]}
        value=${values[i]}
        type=${types[i]}

        plist_WriteOption "${FILENAME}" "${key}" "${value}" "${type}"
    done
}

function setPlistByStreamerType() {
    FILENAME="${1}"
    STREAMER_TYPE="${2}"
    STREAMER=""

    if [ "$STREAMER_TYPE" == "0" ]; then
        STREAMER="STP"
    fi

    if [ "$STREAMER_TYPE" == "1" ]; then
        STREAMER="STB"
    fi

    if [ "$STREAMER_TYPE" == "2" ]; then
        STREAMER="STE"
    fi

    cat <<- EOF > "${FILENAME}"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>UniversalSetting</key>
    <true/>
EOF

    setCommonDict "${FILENAME}" "${STREAMER_TYPE// }" "${STREAMER// }"
    setStreamerTypeDict "${FILENAME}" "${STREAMER_TYPE// }" "${STREAMER// }"
}

function restartApp() {
    APPNAME="${1}"
    ps axc -Ouser | grep -i "${APPNAME}" | awk '{print $1}' | xargs kill
    sleep 2
    open -b `osascript -e "id of app \"${APPNAME}\""`
}

function setSplashtopConfig() {
    PRE_INSTALL_PATH="/Users/Shared/SplashtopStreamer"
    TEMP_DIR="$(mktemp -d)"
    trap "rm -rf $TEMP_DIR" EXIT
    PRE_INSTALL="${PRE_INSTALL_PATH}/.PreInstall"
    FILENAME="${TEMP_DIR}/.PreInstall.$$"
    echo "Writing file ${PRE_INSTALL}"
    
    # Set plist header and common dict
    setPlistByStreamerType "${FILENAME}" "0"
    
    # Apply various settings
    [ ! -z "${DEPLOY_CODE// }" ] && setDeployCode "${FILENAME}" "${DEPLOY_CODE// }"
    setShowDeployLoginWarning "${FILENAME}" "${SHOW_DEPLOY_WARNING// }"
    [ ! -z "${COMPUTER_NAME// }" ] && setComputerName "${FILENAME}" "${COMPUTER_NAME// }"
    [ ! -z "${REQUEST_PERMISSION// }" ] && setPermissionProtectionOption "${FILENAME}" "${REQUEST_PERMISSION// }"
    [ ! -z "${SECURITY_OPTION// }" ] && setSecurityOption "${FILENAME}" "${SECURITY_OPTION// }"
    [ ! -z "${INIT_SECURITY_CODE// }" ] && setInitSecurityCode "${FILENAME}" "${INIT_SECURITY_CODE// }"
    [ "$LOOPBACK_ONLY" == "1" ] && setLegacyConnectionLoopbackOnly "${FILENAME}"
    [ "$HIDE_TRAY_ICON" == "1" ] && setHideTrayIcon "${FILENAME}"
    [ ! -z "${DEFAULT_CLIENT_NAME// }" ] && setDefaultClientDeviceName "${FILENAME}" "${DEFAULT_CLIENT_NAME// }"
    [ "$SHOW_STREAMER_UI" == "0" ] && setShowStreamerUI "${FILENAME}"
    [ "$ENABLE_LAN_SERVER" == "0" ] && setEnableLanConnection "${FILENAME}"
    [ ! -z "${InfraGenForce// }" ] && setInfraGenForce "${FILENAME}" "${InfraGenForce}"
    [ ! -z "${ForceUUID32// }" ] && setForceUUID32 "${FILENAME}" "${ForceUUID32}"
    
    cat <<- EOF >> "${FILENAME}"
    </dict>
</dict>
</plist>
EOF
    
    sudo cp -r "${FILENAME}" "${PRE_INSTALL}"
    rm -rf "${FILENAME}"
    sudo chmod -R 755 "${PRE_INSTALL}"
}

# Main script logic

CHECK_NEED_DEPLOY_CODE="0"
DEPLOY_CODE=""
COMPUTER_NAME=""
REQUEST_PERMISSION=""
INIT_SECURITY_CODE=""
SECURITY_OPTION=""
LOOPBACK_ONLY="0"
HIDE_TRAY_ICON="0"
DEFAULT_CLIENT_NAME=""
SHOW_DEPLOY_WARNING=""
SHOW_STREAMER_UI=""
ENABLE_LAN_SERVER=""
InfraGenForce=""
ForceUUID32=""

# Check options
OPTIND=1
while getopts d:w:n:s:c:e:r:l:h:b:p:f:x:t o
do  case "$o" in
    d)
        DEPLOY_CODE="$OPTARG"
        CHECK_NEED_DEPLOY_CODE="1"
        ;;
    w)
        SHOW_DEPLOY_WARNING="$OPTARG"
        ;;
    n)
        COMPUTER_NAME="$OPTARG"
        ;;
    s)
        SHOW_STREAMER_UI="$OPTARG"
        ;;
    c)
        INIT_SECURITY_CODE="$OPTARG"
        ;;
    e)
        SECURITY_OPTION="$OPTARG"
        ;;
    r)
        REQUEST_PERMISSION="$OPTARG"
        ;;
    l)
        LOOPBACK_ONLY="$OPTARG"
        ;;
    h)
        HIDE_TRAY_ICON="$OPTARG"
        ;;
    b)
        DEFAULT_CLIENT_NAME="$OPTARG"
        ;;
    p)
        ENABLE_LAN_SERVER="$OPTARG"
        ;;
    f)
        InfraGenForce="${OPTARG// }"
        ;;
    x)
        if ((10#${OPTARG} > 0)); then
            ForceUUID32="true"
        else
            ForceUUID32="false"
        fi
        ;;
    t)
        SkippedInstall="1"
        ;;
    [?])
        echo "invalid option: $1" 1>&2;
        usage "$0"
        exit 1;;
    esac
done
shift $((OPTIND-1)) # Shift off the options and optional --.

if [ "$CHECK_NEED_DEPLOY_CODE" == "0" ]; then
    echo "No deploy code!"
    usage "$0"
    exit 1
fi

setSplashtopConfig

if [ "$SkippedInstall" == "0" ]; then
    if [ ! -d "/Applications/Splashtop Streamer.app" ]; then
        echo "Error: Splashtop Streamer is not installed."
        exit 1
    fi
    echo "Skipped install pkg or dmg, to re-config setting."
    restartApp "Splashtop Streamer"
else
    echo "Reconfiguring settings without reinstalling."
    restartApp "Splashtop Streamer"
fi

echo "Done!"

exit 0