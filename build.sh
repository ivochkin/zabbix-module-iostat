#!/usr/bin/env bash

src="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
stage=/tmp/zabbix-module-iostat/$(uuidgen)

# Configurable parameters
zbx_bin_prefix=/etc/zabbix/extensions/scripts
zbx_agent_confd=/etc/zabbix/zabbix_agentd.d

# Script arguments
pkgtype="$1" # rpm/deb are allowed

mkdir -p $stage/$zbx_bin_prefix
mkdir -p $stage/$zbx_agent_confd
mkdir -p $stage/etc/cron.d/

sed_script="s#@ZBX_BIN_PREFIX@#$zbx_bin_prefix#g"

binaries=(
  iostat-collect.sh
  iostat-parse.sh
)

for name in ${binaries[@]}; do
  sed "$sed_script" $src/$name.in \
    > $stage/$zbx_bin_prefix/$name
  chmod +x $stage/$zbx_bin_prefix/$name
done

sed "$sed_script" $src/iostat.conf.in \
  > $stage/$zbx_agent_confd/iostat.conf

sed "$sed_script" $src/crontab \
  > $stage/etc/cron.d/zabbix-module-iostat

chmod 600 $stage/etc/cron.d/zabbix-module-iostat

fpm \
  --input-type dir \
  --output-type $pkgtype \
  --chdir $stage \
  --name zabbix-module-iostat \
  --version $(cat $src/version) \
  --architecture all \
  --maintainer "Stanislav Ivochkin <isn@extrn.org>" \
  --vendor extrn.org \
  --depends "zabbix-agent > 3.0" \
  --depends "sysstat" \
  --config-files $zbx_agent_confd/iostat.conf \
  --url https://github.com/ivochkin/zabbix-module-iostat \
  --license MIT

rm -rf $stage
