#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:${PATH}

set -o verbose
set -o pipefail
set -o nounset
set -ex

CNT_MEMORY_LIMIT=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)

CNT_MEMORY_LIMIT_M="$(($CNT_MEMORY_LIMIT/1024/1024))"
JAVA_MAX_MEM_LIMIT="256"
JAVA_MEM_LIMIT="$((${CNT_MEMORY_LIMIT_M}>${JAVA_MAX_MEM_LIMIT}?${JAVA_MAX_MEM_LIMIT}:${CNT_MEMORY_LIMIT_M}))"

JAVA_MEMORY="-Xmx$((${JAVA_MEM_LIMIT}/2))m"
JAVA_JMX="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=12345 -Dcom.sun.management.jmxremote.rmi.port=12346 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false"
JAVA_NETWORK="-Dnetworkaddress.cache.ttl=1 -Dnetworkaddress.cache.negative.ttl=0 -Djava.net.preferIPv4Stack=true"
JAVA_GC="-XX:-UseGCOverheadLimit -XX:+UseConcMarkSweepGC -XX:+ScavengeBeforeFullGC -XX:MaxGCPauseMillis=100"
JAVA_JENKINS_OPTS="-Djava.awt.headless=true -DJENKINS_HOME=/var/lib/jenkins -Djenkins.slaves.DefaultJnlpSlaveReceiver.disableStrictVerification=true"

KEYSTORE="/root/jenkins-server-certs"
KEYSTORE_PASSWD="password"
LOCALIP=$(hostname -I | tr -d "\n")

# Remove existing keystore
rm -vf ${KEYSTORE}

# Remove existing nodes (nodes should re-register in next launch)
rm -Rf /var/lib/jenkins/nodes/*

# And generate new
keytool -genkey -noprompt -trustcacerts -keysize 2048 -validity 999 \
        -keyalg RSA \
        -keypass password \
        -dname "CN=jenkins-server" \
        -ext san="ip:127.0.0.1,ip:::1,ip:${LOCALIP},dns:jenkins-server" \
        -alias jenkins-server \
        -keystore ${KEYSTORE} \
        -storepass ${KEYSTORE_PASSWD} \

if [ -f "/var/lib/jenkins/config.xml" ] ; then
    # Allow AnonymousReadAccess to download cli client
    xmlstarlet ed --inplace --update "/hudson/authorizationStrategy/denyAnonymousReadAccess" --value "false" /var/lib/jenkins/config.xml
    xmlstarlet ed --inplace --update "/hudson/slaveAgentPort" --value "99" /var/lib/jenkins/config.xml
fi

# Create API user
mkdir -pv /var/lib/jenkins/users/api
cp -v root/api-config.xml /var/lib/jenkins/users/api/config.xml

# Plugins
mkdir -pv /var/lib/jenkins/plugins/
cp -v /root/metrics.hpi /var/lib/jenkins/plugins/
cp -v /root/metrics-graphite.hpi /var/lib/jenkins/plugins/

# Launch Jenkins server
java \
        ${JAVA_JMX} ${JAVA_NETWORK} ${JAVA_GC} \
        ${JAVA_JENKINS_OPTS} \
        -jar /usr/lib/jenkins/jenkins.war \
        --webroot=/var/cache/jenkins/war \
        --httpPort=80 \
        --httpsPort=443 \
        --httpsKeyStore=${KEYSTORE} --httpsKeyStorePassword=${KEYSTORE_PASSWD} \
        --debug=5 \
        --handlerCountMax=100 \
        --handlerCountMaxIdle=20
