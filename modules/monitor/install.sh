#!/bin/bash
set -e

ERROR="[ERROR]"
REQUIRED_PROGRAMS=(
    awk
    bash
    cat
    curl
    getconf
    grep
    hostnamectl
    sed
    systemctl
    tr
    uname
    unzip
    wget
    xargs
)

CONFIG_PATH="${1:-/opt/monitor/configs}"
DOMAIN_NAME="${2}"

function checkOS {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        echo "${ERROR} Sorry, there is no release for your OS for now."
        exit 1
    fi
}

function getArchitecture {
    local bits
    local arch
    local return
    
    bits="$(getconf LONG_BIT)"
    arch="$(uname -m)"
    return=""
    
    if [[ "$arch" == *"arm"* && "$bits" = "32" ]]; then
        return="arm"
    fi
    
    if [[ "$arch" == *"arm"* && "$bits" = "64" ]]; then
        return="arm64"
    fi
    
    if [[ "$arch" != *"arm"* && "$bits" = "32" ]]; then
        return="386"
    fi
    
    if [[ "$arch" != *"arm"* && "$bits" = "64" ]]; then
        return="amd64"
    fi
    
    echo "$return"
}

function getVersion {
    wget -q -O- \
    https://api.github.com/repos/takattila/monitor/releases/latest \
    | grep "tag_name" \
    | awk '{print $2}' \
    | tr -d '"' \
    | tr -d ','
}

function getLatestReleaseURL {
    local version="$1"
    local architecture="$2"
    echo "https://github.com/takattila/monitor/releases/download/${version}/monitor-${version}-linux-${architecture}.zip"
}

function getWebConfigType {
    os="$(hostnamectl | grep Operating | awk -F: '{print $2}' | xargs | awk '{print tolower($0)}')"
    if [[ "$os" = "raspbian" ]]; then
        echo "raspbian"
    else
        echo "linux"
    fi
}

function getIP {
    echo "$(hostname)"
}

function getPort {
    local monitorPath="$1"
    grep "^  port:" "${monitorPath}/configs/web.$(getWebConfigType).yaml" | awk '{print $2}'
}

function getRoute {
    local monitorPath="$1"
    grep "^    index:" "${monitorPath}/configs/web.$(getWebConfigType).yaml" | awk '{print $2}'
}

function checkProgramIsInstalled {
    local program=$1
    sudo which ${program} &> /dev/null
    echo $?
}

function checkAllProgramsInstalled {
    local shouldBeInstalled
    local check
    
    declare -A shouldBeInstalled
    
    echo "- Checking necessary programs:"
    
    for p in ${REQUIRED_PROGRAMS[@]} ; do
        echo -n "  - ${p}..."
        check=$(checkProgramIsInstalled "${p}")
        if [[ "$check" != "0" ]]; then
            shouldBeInstalled["${p}"]="$check"
            echo "[FAIL]"
        else
            echo "[PASS]"
        fi
    done
    
    if [[ "${#shouldBeInstalled[@]}" -gt 0 ]]; then
        echo
        echo "${ERROR} For a successful installation, the following programs must be installed:"
        for program in ${!shouldBeInstalled[@]}; do
            echo "  - $program"
        done
        exit 1
    fi
}

function installServices {
    local url="$1"
    local basePath="/opt/"
    local programDir="monitor"
    local monitorPath="${basePath}${programDir}"
    local cfgBackupPath="${monitorPath}-cfg-backup"
    local totalSteps="12"
    local backupCfg="y"  # DEFAULT: mindig backup készül unattended módban
    
    echo "- [1./${totalSteps}.] Downloading..."
    sudo mkdir -p "${basePath}" >/dev/null 2>&1 || true
    cd "${basePath}"
    echo "  - ${url}"
    echo "  - to: ${basePath}..."
    sudo rm -f monitor-v*.zip 2>&1 || true
    sudo wget -q --show-progress "$url"
    
    if [[ -e "${monitorPath}" ]]; then
        echo "- [2./${totalSteps}.] Backup existing configuration..."
        if [[ "$backupCfg" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            echo "  - Creating backup..."
            sudo mkdir -p ${cfgBackupPath} >/dev/null 2>&1 || true
            sudo chown ${USER}:${USER} ${cfgBackupPath}
            sudo chown -R ${USER}:${USER} ${cfgBackupPath}
            sudo cp -f ${monitorPath}/configs/*.yaml ${cfgBackupPath} >/dev/null 2>&1 || true
            sudo cp -f ${monitorPath}/configs/*.db ${cfgBackupPath} >/dev/null 2>&1 || true
            sudo rm -rf ${monitorPath} >/dev/null 2>&1 || true
        else
            echo "  - Backup skipped..."
        fi
    else
        echo "- [2./${totalSteps}.] There is no existing configuration, backup skipped..."
    fi
    
    echo "- [3./${totalSteps}.] Unzip monitor-v*.zip to ${basePath}..."
    sudo unzip -q -o monitor-v*.zip -d monitor
    sudo cp ${cfgBackupPath}/*.yaml ${monitorPath}/configs >/dev/null 2>&1 || true
    sudo cp ${cfgBackupPath}/*.db ${monitorPath}/configs >/dev/null 2>&1 || true
    sudo rm -rf ${cfgBackupPath} >/dev/null 2>&1 || true
    sudo rm -f monitor-v*.zip 2>&1 || true
    
    echo "- [4./${totalSteps}.] Change ownership of the ${monitorPath} directory to $USER..."
    sudo chown ${USER}:${USER} ${monitorPath}
    sudo chown -R ${USER}:${USER} ${monitorPath}
    
    echo "- [5./${totalSteps}.] Change directory to: ${monitorPath}"
    cd "${monitorPath}"
    
    echo "- [6./${totalSteps}.] Save your credentials"
    echo "  - Using backup..."
    sudo echo "dXNlcjpwYXNz" > ${monitorPath}/configs/auth.db
    sudo chown root:root ${monitorPath}/configs/*.db >/dev/null 2>&1 || true
    
    echo "- [7./${totalSteps}.] Copy ${programDir}/tools/*.service to /etc/systemd/system..."
    sudo cp tools/*.service /etc/systemd/system
    
    echo "- [8./${totalSteps}.] Reload daemon..."
    sudo systemctl daemon-reload
    
    echo "- [9./${totalSteps}.] Enabling services..."
    sudo systemctl enable monitor-api.service monitor-web.service
    echo "  - monitor-api: $(sudo systemctl is-enabled monitor-api.service)"
    echo "  - monitor-web: $(sudo systemctl is-enabled monitor-web.service)"
    
    echo "- [10./${totalSteps}.] Modifying configuration..."
    cp /tmp/web.linux.yaml "${CONFIG_PATH}" >/dev/null 2>&1 || true
    cp /tmp/api.linux.yaml "${CONFIG_PATH}" >/dev/null 2>&1 || true
    
    echo "- [11./${totalSteps}.] Starting services..."
    sudo systemctl stop monitor-api.service monitor-web.service || true
    sudo systemctl start monitor-api.service monitor-web.service
    echo "  - monitor-api: $(sudo systemctl is-active monitor-api.service)"
    echo "  - monitor-web: $(sudo systemctl is-active monitor-web.service)"
    
    echo "- [12./${totalSteps}.] Finished!"
    echo "  - $(cat /opt/monitor/VERSION.md | sed ':a;N;$!ba;s/\n/ /g')"
    echo "  - Web interface: http://${DOMAIN_NAME}$(getRoute "${monitorPath}")"
    
    echo "Configuration completed, the service is now running on port $(getPort)."
}

function clearScreen {
    clear
}

function main {
    local architecture
    local version
    local url
    
    clearScreen
    checkOS
    checkAllProgramsInstalled
    
    architecture="$(getArchitecture)"
    if [[ "$architecture" = "" ]]; then
        echo "${ERROR} Sorry, there is no release for your architecture for now."
        exit 1
    fi
    
    version="$(getVersion)"
    if [[ "$version" = "" ]]; then
        echo "${ERROR} Sorry, the latest release number cannot be fetched."
        exit 1
    fi
    
    if [[ "$CONFIG_PATH" = "" ]]; then
        echo "${ERROR} Sorry, CONFIG_PATH is not set."
        exit 1
    fi
    
    if [[ "$DOMAIN_NAME" = "" ]]; then
        echo "${ERROR} Sorry, DOMAIN_NAME is not set."
        exit 1
    fi
    
    url="$(getLatestReleaseURL "$version" "$architecture")"
    installServices "$url"
}

main "$@"
