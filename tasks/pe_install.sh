#!/bin/bash

# This stanza configures PuppetDB to quickly fail on start. This is desirable
# in situations where PuppetDB WILL fail, such as when PostgreSQL is not yet
# configured, and we don't want to let PuppetDB wait five minutes before
# giving up on it.
if [ "$PT_shortcircuit_puppetdb" = "true" ]; then
	mkdir /etc/systemd/system/pe-puppetdb.service.d
	cat > /etc/systemd/system/pe-puppetdb.service.d/10-shortcircuit.conf <<-EOF
		[Service]
		TimeoutStartSec=1
		TimeoutStopSec=1
		Restart=no
	EOF
	systemctl daemon-reload
fi

tgzdir=$(dirname "$PT_tarball")
pedir=$(tar -tf "$PT_tarball" | head -n 1 | xargs dirname)

tar -C "$tgzdir" -xzf "$PT_tarball"

if [ ! -z "$PT_peconf" ]; then
	/bin/bash "${tgzdir}/${pedir}/puppet-enterprise-installer" -y -c "$PT_peconf"
else
	/bin/bash "${tgzdir}/${pedir}/puppet-enterprise-installer" -y
fi

# The exit code of the installer script will be the exit code of the task
exit_code=$?

if [ "$PT_shortcircuit_puppetdb" = "true" ]; then
	systemctl stop pe-puppetdb.service
	rm /etc/systemd/system/pe-puppetdb.service.d/10-shortcircuit.conf
	systemctl daemon-reload
fi

if [ "$PT_puppet_service_ensure" = "stopped" ]; then
	systemctl stop puppet.service
fi

# Exit with the installer script's exit code
exit $exit_code
