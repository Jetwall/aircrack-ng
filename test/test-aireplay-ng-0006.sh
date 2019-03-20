#!/bin/sh
# Aireplay-ng: deauth test with reason code

if test ! -z "${CI}"; then exit 77; fi

# Load helper functions
. "${abs_builddir}/../test/int-test-common.sh"

# Check root
check_root

# Check all required tools are installed
check_airmon_ng_deps_present
is_tool_present tcpdump

# Load mac80211_hwsim
load_module 1

# Check there are two radios
check_radios_present 1

# Get interfaces names
get_hwsim_interface_name 1
WI_IFACE=${IFACE}

# Put interface in monitor so tcpdump captures in the correct mode
set_monitor_mode ${WI_IFACE}

# Start capture in the background
TEMP_PCAP=$(mktemp)
tcpdump -i ${WI_IFACE} -w ${TEMP_PCAP} -U & 2>&1 >/dev/null
# Get tcpdump PID
TCPDUMP_PID=$!

# Next test is directed
AP_MAC="00:11:22:33:44:55"
"${abs_builddir}/../aireplay-ng${EXEEXT}" \
	-0 1 \
	-a ${AP_MAC} \
	-D \
	--deauth-rc 10 \
	${WI_IFACE} \
		2>&1 >/dev/null

# Wait a second
sleep 1

# Kill tcpdump (SIGTERM)
kill -15 ${TCPDUMP_PID}

# Wait a few seconds so it exits gracefully and writes the frames
# to the file
sleep 3

# Cleanup
cleanup

# There should be exactly 256 deauth
AMOUNT_PACKETS=$(tcpdump -r ${TEMP_PCAP} 2>/dev/null | egrep "DeAuthentication \(${AP_MAC}" | egrep 'Disassociated because the information in the Power Capability element is unacceptable' | wc -l)
rm ${TEMP_PCAP}
[ ${AMOUNT_PACKETS} -eq 256 ] && exit 0

exit 1