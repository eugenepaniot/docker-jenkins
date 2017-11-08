FROM	centos:7

RUN	yum install -y curl iproute \
		http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-11.noarch.rpm

RUN     curl -f -v http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo -o /etc/yum.repos.d/jenkins-stable.repo && \
        rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key && \
        yum install -y jenkins java-1.8.0-openjdk openssl xmlstarlet \
		https://github.com/krallin/tini/releases/download/v0.16.1/tini_0.16.1.rpm


ADD	files/start-jenkins-server.sh 	/root/
ADD	files/api-config.xml 		/root/

ADD	https://updates.jenkins-ci.org/download/plugins/metrics/3.0.0/metrics.hpi			/root/
ADD	https://updates.jenkins-ci.org/download/plugins/metrics-graphite/3.0.0/metrics-graphite.hpi 	/root/


CMD	/root/start-jenkins-server.sh

ENTRYPOINT ["/usr/bin/tini", "-vv", "--"]

EXPOSE	12345/tcp 443/tcp 99/tcp 
