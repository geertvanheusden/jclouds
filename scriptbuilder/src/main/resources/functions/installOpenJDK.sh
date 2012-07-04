# adds JAVA_HOME and into PATH in global and user-specific profiles
function setupJavaHomeInProfile() {
  PROFILES=(/etc/bashrc $HOME/.bashrc /etc/skel/.bashrc)
  test -n "$SUDO_USER" &&
    PROFILES=(${PROFILES[*]} `getent passwd $SUDO_USER| cut -f6 -d:`/.bashrc)
  for PROFILE in ${PROFILES[*]}; do
    cat >> $PROFILE <<-'END_OF_JCLOUDS_FILE'
	export JAVA_HOME=/usr/local/jdk
	export PATH=$JAVA_HOME/bin:$PATH
END_OF_JCLOUDS_FILE
  done
}

# resets JAVA_HOME to what an openjdk installer created
function findOpenJDK() {
  local oldJavaHome=$JAVA_HOME
  unset JAVA_HOME
  for CANDIDATE in $oldJavaHome `ls -d /usr/lib/jvm/java-1.6.0-openjdk-* /usr/lib/jvm/java-6-openjdk-* /usr/lib/jvm/java-6-openjdk 2>&-`; do
    if [ -n "$CANDIDATE" -a -x "$CANDIDATE/bin/java" ]; then
      export JAVA_HOME=$CANDIDATE
      break
    fi
  done
}

# assures JDK installed and JAVA_HOME to a link at /usr/local/jdk
function installOpenJDK() {
  if [ "$JAVA_HOME" == "/usr/local/jdk" ]; then
    echo skipping as JAVA_HOME is already set to /usr/local/jdk
    return 0
  fi
  if [ -n "$JAVA_HOME" -a -x "$JAVA_HOME/bin/java" ]; then
    echo reusing JAVA_HOME $JAVA_HOME
  else
    if hash apt-get 2>/dev/null; then
      apt-get-update && apt-get-install openjdk-6-jdk
    elif hash yum 2>/dev/null; then
      yum-install java-1.6.0-openjdk-devel
    else
      abort "we only support apt-get and yum right now... please contribute"
    fi
    findOpenJDK
    if [ -n "$JAVA_HOME" ]; then
      echo installed JAVA_HOME $JAVA_HOME
    else
      abort "JDK installation failed"
    fi
  fi
  rm -rf /usr/local/jdk
  ln -Fs $JAVA_HOME /usr/local/jdk
  /usr/local/jdk/bin/java -version || abort "cannot run java"
  setupJavaHomeInProfile
}