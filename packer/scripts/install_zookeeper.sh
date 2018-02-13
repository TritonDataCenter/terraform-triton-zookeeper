#!/bin/bash
#
# Installs and configures Apache Zookeeper.
#
# Note: Generally follows guidelines at https://web.archive.org/web/20170701145736/https://google.github.io/styleguide/shell.xml.
#

set -e

# check_prerequisites - exits if distro is not supported.
#
# Parameters:
#     None.
function check_prerequisites() {
  local distro
  if [[ -f "/etc/lsb-release" ]]; then
    distro="Ubuntu"
  fi

  if [[ -z "${distro}" ]]; then
    log "Unsupported platform. Exiting..."
    exit 1
  fi
}

# install_dependencies - installs dependencies
#
# Parameters:
#     -
function install_dependencies() {
  log "Updating package index..."
  apt-get -qq update
  log "Upgrading existing packages"
  apt-get -qq upgrade
  log "Installing prerequisites..."
  apt-get -qq --no-install-recommends install \
    wget openjdk-8-jdk
}

# check_arguments - exits if arguments are NOT satisfied
#
# Parameters:
#     $1: the version of zookeeper
#     $2: the machine name prefix - used for identifying instances with CNS
#     $3: the number of Zookeeper servers to provision
#     $4: the current Zookeeper server being provisioned
#     $5: the fully qualified domain name base for the CNS address
function check_arguments() {
  local -r zookeeper_version=${1}
  local -r zookeeper_name_prefix=${2}
  local -r zookeeper_machine_count=${3}
  local -r zookeeper_machine_index=${4}
  local -r cns_fqdn_base=${5}

  if [[ -z "${zookeeper_version}" ]]; then
    log "Zookeeper version NOT provided. Exiting..."
    exit 1
  fi

  if [[ -z "${zookeeper_name_prefix}" ]]; then
    log "Machine Name Prefix NOT provided. Exiting..."
    exit 1
  fi

  if [[ -z "${zookeeper_machine_count}" ]]; then
    log "Zookeeper server count NOT provided. Exiting..."
    exit 1
  fi

  if [[ -z "${zookeeper_machine_index}" ]]; then
    log "Zookeeper server index NOT provided. Exiting..."
    exit 1
  fi

  if [[ -z "${cns_fqdn_base}" ]]; then
    log "Domain name base for CNS addresses NOT provided. Exiting..."
    exit 1
  fi
}

# install - downloads and installs the specified tool and version
#
# Parameters:
#     $1: the version of zookeeper
#     $2: the machine name prefix - used for identifying instances with CNS
#     $3: the number of Zookeeper servers to provision
#     $4: the current Zookeeper server being provisioned
#     $5: the fully qualified domain name base for the CNS address
function install_zookeeper() {
  local -r zookeeper_version=${1}
  local -r zookeeper_name_prefix=${2}
  local -r zookeeper_machine_count=${3}
  local -r zookeeper_machine_index=${4}
  local -r cns_fqdn_base=${5}

  local -r user_zookeeper='zookeeper'

  local -r path_file="apache-zookeeper-${zookeeper_version}.tar.gz"
  local -r path_install="/usr/local/zookeeper-${zookeeper_version}"

  log "Downloading zookeeper ${zookeeper_version}..."
  wget -O ${path_file} "http://mirrors.sonic.net/apache/zookeeper/zookeeper-${zookeeper_version}/zookeeper-${zookeeper_version}.tar.gz"

  log "Installing zookeeper ${zookeeper_version}..."

  useradd ${user_zookeeper} || log "User [${user_zookeeper}] already exists. Continuing..."

  install -d -o ${user_zookeeper} -g ${user_zookeeper} ${path_install}
  tar -xzf ${path_file} -C /usr/local/

  log "Configuring Zookeeper service..."

  install -d -o ${user_zookeeper} -g ${user_zookeeper} /etc/zookeeper/conf
  install -d -o ${user_zookeeper} -g ${user_zookeeper} /var/lib/zookeeper
  install -d -o ${user_zookeeper} -g ${user_zookeeper} /var/log/zookeeper

  local -r pid_dir="/var/run/zookeeper"
  local -r pid_file="${pid_dir}/zookeeper.pid"

  /usr/bin/printf "
tickTime=2000
initLimit=5
syncLimit=2
dataDir=/var/lib/zookeeper/
clientPort=2181
" > /etc/zookeeper/conf/zoo.cfg

  # Append server config to zoo.cfg.
  i=0
  while [ "${i}" -lt "$((zookeeper_machine_count))" ]; do
    local instance_name="${zookeeper_name_prefix}-${i}"
    local current_server=$(get_cns_instance_name ${instance_name} ${cns_fqdn_base})
    /usr/bin/printf "
server.${i}=${current_server}:2888:3888
" >> /etc/zookeeper/conf/zoo.cfg  # note we're appending to the file here

    let i=$((i+1))
  done

  /usr/bin/printf "${zookeeper_machine_index}" \
  > /var/lib/zookeeper/myid

  /usr/bin/printf "
[Unit]
Description=Zookeeper
Documentation=https://zookeeper.apache.org/doc/r${zookeeper_version}/zookeeperAdmin.html
After=network-online.target

[Service]
User=zookeeper
Type=forking
RuntimeDirectory=zookeeper
Environment=JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre/
Environment=ZOOPIDFILE=${pid_file}
Environment=ZOO_LOG_DIR=/var/log/zookeeper/
ExecStart=${path_install}/bin/zkServer.sh start /etc/zookeeper/conf/zoo.cfg
ExecStop=${path_install}/bin/zkServer.sh stop /etc/zookeeper/conf/zoo.cfg

[Install]
WantedBy=default.target
" > /etc/systemd/system/zookeeper.service

  log "Starting Zookeeper..."
  systemctl daemon-reload

  systemctl enable zookeeper.service
  systemctl start zookeeper.service

}

function get_cns_instance_name() {
  # cns format:
  # <instance name>.inst.<account uuid>.<data center name>.cns.joyent.com
  # <service name>.svc.<account uuid>.<data center name>.cns.joyent.com

  local -r instance=${1}
  local -r cns_fqdn_base=${2}

  local -r triton_account_uuid=$(mdata-get 'sdc:owner_uuid') # see https://eng.joyent.com/mdata/datadict.html
  local -r triton_region=$(mdata-get 'sdc:datacenter_name') # see https://eng.joyent.com/mdata/datadict.html

  echo "${instance}.inst.${triton_account_uuid}.${triton_region}.${cns_fqdn_base}"
}

# log - prints an informational message
#
# Parameters:
#     $1: the message
function log() {
  local -r message=${1}
  local -r script_name=$(basename ${0})
  echo -e "==> ${script_name}: ${message}"
}

# main
function main() {
  check_prerequisites

  local -r arg_zookeeper_version=$(mdata-get 'zookeeper_version')
  local -r arg_zookeeper_name_prefix=$(mdata-get 'zookeeper_name_prefix')
  local -r arg_zookeeper_machine_count=$(mdata-get 'zookeeper_machine_count')
  local -r arg_zookeeper_machine_index=$(mdata-get 'zookeeper_machine_index')
  local -r arg_cns_fqdn_base=$(mdata-get 'cns_fqdn_base')
  check_arguments \
    ${arg_zookeeper_version} ${arg_zookeeper_name_prefix} ${arg_zookeeper_machine_count} ${arg_zookeeper_machine_index} \
    ${arg_cns_fqdn_base}

  install_dependencies
  install_zookeeper \
    ${arg_zookeeper_version} ${arg_zookeeper_name_prefix} ${arg_zookeeper_machine_count} ${arg_zookeeper_machine_index} \
    ${arg_cns_fqdn_base}

  log "Done."
}

main
