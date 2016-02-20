function hide_output {
	# This function hides the output of a command unless the command fails
	# and returns a non-zero exit code.

	# Get a temporary file.
	OUTPUT=$(tempfile)

	# Execute command, redirecting stderr/stdout to the temporary file.
	$@ &> $OUTPUT

	# If the command failed, show the output that was captured in the temporary file.
	E=$?
	if [ $E != 0 ]; then
		# Something failed.
		echo
		echo FAILED: $@
		echo -----------------------------------------
		cat $OUTPUT
		echo -----------------------------------------
		exit $E
	fi

	# Remove temporary file.
	rm -f $OUTPUT
}

function apt_get_quiet {
	# Run apt-get in a totally non-interactive mode.
	#
	# Somehow all of these options are needed to get it to not ask the user
	# questions about a) whether to proceed (-y), b) package options (noninteractive),
	# and c) what to do about files changed locally (we don't cause that to happen but
	# some VM providers muck with their images; -o).
	#
	# Although we could pass -qq to apt-get to make output quieter, many packages write to stdout
	# and stderr things that aren't really important. Use our hide_output function to capture
	# all of that and only show it if there is a problem (i.e. if apt_get returns a failure exit status).
	if [ $(whoami) != "root" ]; then
	    APT_PREFIX="sudo "
	fi
	DEBIAN_FRONTEND=noninteractive hide_output ${APT_PREFIX} apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" "$@"
}

function apt_install {
	# Install a bunch of packages. We used to report which packages were already
	# installed and which needed installing, before just running an 'apt-get
	# install' for all of the packages.  Calling `dpkg` on each package is slow,
	# and doesn't affect what we actually do, except in the messages, so let's
	# not do that anymore.
	PACKAGES=$@
	apt_get_quiet install $PACKAGES
}

function get_default_hostname {
	# Guess the machine's hostname. It should be a fully qualified
	# domain name suitable for DNS. None of these calls may provide
	# the right value, but it's the best guess we can make.
	set -- $(hostname --fqdn      2>/dev/null ||
                 hostname --all-fqdns 2>/dev/null ||
                 hostname             2>/dev/null)
	printf '%s\n' "$1" # return this value
}

function get_publicip_from_web_service {
        # This seems to be the most reliable way to determine the
        # machine's public IP address: asking a very nice web API
        # for how they see us. Thanks go out to icanhazip.com.
        # See: https://major.io/icanhazip-com-faq/
        #
        # Pass '4' or '6' as an argument to this function to specify
        # what type of address to get (IPv4, IPv6).
        curl -$1 --fail --silent --max-time 15 icanhazip.com 2>/dev/null
}

function ufw_allow {
	if [ -z "$DISABLE_FIREWALL" ]; then
		# ufw has completely unhelpful output
		ufw allow $1 > /dev/null;
	fi
}

function restart_service {
	hide_output service $1 restart
}

function wget_verify {
	# Downloads a file from the web and checks that it matches
	# a provided hash. If the comparison fails, exit immediately.
	URL=$1
	HASH=$2
	DEST=$3
	CHECKSUM="$HASH  $DEST"
	rm -f $DEST
	wget -q -O $DEST $URL || exit 1
	if ! echo "$CHECKSUM" | sha1sum --check --strict > /dev/null; then
		echo "------------------------------------------------------------"
		echo "Download of $URL did not match expected checksum."
		echo "Found:"
		sha1sum $DEST
		echo
		echo "Expected:"
		echo "$CHECKSUM"
		rm -f $DEST
		exit 1
	fi
}

function git_clone {
	# Clones a git repository, checks out a particular commit or tag,
	# and moves the repository (or a subdirectory in it) to some path.
	# We use separate clone and checkout because -b only supports tags
	# and branches, but we sometimes want to reference a commit hash
	# directly when the repo doesn't provide a tag.
	REPO=$1
	TREEISH=$2
	SUBDIR=$3
	TARGETPATH=$4
	TMPPATH=/tmp/git-clone-$$
	rm -rf $TMPPATH $TARGETPATH
	git clone -q $REPO $TMPPATH || exit 1
	(cd $TMPPATH; git checkout -q $TREEISH;) || exit 1
	mv $TMPPATH/$SUBDIR $TARGETPATH
	rm -rf $TMPPATH
}

function sql_as_root {
	hide_output mysql -uroot -p${MYSQL_ROOT_PASSWORD} $@
}

function sql_as_user {
	hide_output mysql -u${MYSQL_USER_NAME} -p${MYSQL_USER_PASSWORD} ${MYSQL_USER_NAME} $@
}
