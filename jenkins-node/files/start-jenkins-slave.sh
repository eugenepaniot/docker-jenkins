#!/bin/bash

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:${PATH}

set -o verbose
set -o pipefail
set -o nounset
set -ex

JAVA_NETWORK="-Dnetworkaddress.cache.ttl=1 -Dnetworkaddress.cache.negative.ttl=0 -Djava.net.preferIPv4Stack=true"
JAVA_MEMORY="-Xmx256m"

JAVA="java ${JAVA_NETWORK} ${JAVA_MEMORY}"
CURL="curl -f -v -k"

API_USER="api"
API_PASSWD="api"

OPTIONS="-noKeyAuth -logger FINE"

NODE_NAME="$(hostname -s)"

# Remove old keystore
rm -fv jenkins-server.crt keystore

# Download curre SSL crt
openssl s_client -host ${JENKINS_SERVER} -port 443 < /dev/null \
    | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > jenkins-server.crt

# Import SSL crt to java keystore
keytool -import -noprompt -trustcacerts \
    -alias jenkins-server-${JENKINS_SERVER} -file jenkins-server.crt \
    -keystore keystore -storepass storepass


${CURL} https://${JENKINS_SERVER}/jnlpJars/jenkins-cli.jar -o jenkins-cli.jar
${CURL} https://${JENKINS_SERVER}/jnlpJars/slave.jar -o slave.jar

mkdir -pv /home/jenkins/slave

xmlstarlet ed --inplace --update "/slave/name" --value ${NODE_NAME} /root/node.xml
xmlstarlet ed --inplace --update "/slave/description" --value "${NODE_NAME} dynamic docker container" /root/node.xml
xmlstarlet ed --inplace --update "/slave/numExecutors" --value "$(grep -c  processor /proc/cpuinfo)" /root/node.xml
xmlstarlet ed --inplace --update "/slave/label" --value "dynamic docker" /root/node.xml


cat /root/node.xml | \
${JAVA} \
    -Djavax.net.ssl.trustStore=keystore -Djavax.net.ssl.trustStorePassword=storepass \
    -jar jenkins-cli.jar \
    -s https://${JENKINS_SERVER}/ \
    ${OPTIONS} \
    create-node \
    ${NODE_NAME} \
    --username ${API_USER} \
    --password ${API_PASSWD}


${JAVA} \
    -Djavax.net.ssl.trustStore=keystore -Djavax.net.ssl.trustStorePassword=storepass \
    -jar slave.jar  \
    -noReconnect \
    -jnlpCredentials ${API_USER}:${API_PASSWD} \
    -jnlpUrl https://${JENKINS_SERVER}/computer/${NODE_NAME}/slave-agent.jnlp 