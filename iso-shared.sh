
check_root() {
	if [ "$USER" != "root" ]; then
		>&2 echo ">>> error: run script as root"
		exit 1
	fi
}

sigint_handler() {
	echo "caught ctrl-c"
	trap - SIGINT
}

create_ramdisk() {
	if [ ! -d ramdisk ]; then
		mkdir ramdisk
		sudo mount -t tmpfs -o size=8000M kvmroot ./ramdisk
		touch ./ramdisk/root.img
		truncate -s 7800M ./ramdisk/root.img
	fi
}

destroy_ramdisk() {
	read -n 1 -p 'erase ramdisk (N/y) ' && echo
	if [ "$REPLY" = 'Y' ] || [ "$REPLY" = 'y' ]; then
		sudo umount ./ramdisk
		rmdir ramdisk	
	fi
}

setup() {
	check_root
	stty -echoctl
	trap sigint_handler SIGINT
	create_ramdisk
}

teardown() {
	stty echoctl
	destroy_ramdisk
	>&2 echo "exiting kvm.sh"
}

run_kvm() {
	kvm "$@"

	pid=$!
	echo $pid > kvm.pid
	wait -p KVM_EC $pid
	exit_status=$?

	rm -f kvm.pid
}
