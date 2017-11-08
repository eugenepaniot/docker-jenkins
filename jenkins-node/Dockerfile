FROM	centos:7

RUN	yum install -y curl \
		http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-11.noarch.rpm 

RUN 	yum install -y java-1.8.0-openjdk openssl xmlstarlet \
		https://github.com/krallin/tini/releases/download/v0.16.1/tini_0.16.1.rpm

ADD	files/start-jenkins-slave.sh 	/root/
ADD	files/node.xml 			/root/

CMD	/root/start-jenkins-slave.sh

ENTRYPOINT ["/usr/bin/tini", "-vv", "--"]
