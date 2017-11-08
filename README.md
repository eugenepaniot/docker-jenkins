h1. How it works. Design

See arch.png

h1. Prepare jenkins server

1. Change directory to jenkins-server
 cd jenkins-server

2. Build docker image
 docker build --pull=true  -t jenkins-server .

3. Create docker volume to store server settings, etc.
 docker volume create jenkins

4. Execute container
 docker run -m 256M -v jenkins:/var/lib/jenkins --name jenkins-server  -ti jenkins-server:latest

5. Save jenkins password and login to jenkins
    5.1 Find IP
    Execute:
     docker inspect jenkins-server --format '{{ .NetworkSettings.IPAddress }}'

    5.2 Login
    Open browser and go to URI: https://{ IP from #5.1 } and login with login: "admin", and generated password in console from #4

    5.3 Make first installation
        5.3.1 "Install suggested plugins"
        Wait while installation completed.

    5.4 Adjust jenkins settings
        5.4.1 Go to: /configureSecurity
        Set Agents, TCP port for JNLP agents to 99. And save. (It will be automatically adjusted on next jenkins server container start)

        5.4.2 Go to /configure
        Metrics, Access keys, Add new key then generate and save key. (Example: A7PSMBeeRkKbrrMTuD4R9ST0mBZy2a1oSdWy0w4qF3zFY2J38KoSNN_JE10GhZLB)
        Save settings.

h1. Prepare jenkins collector

1. Change directory to jenkins-collector
 cd ../jenkins-collector

2. Build docker image
 docker build --pull=true  -t jenkins-collector .

3. Create docker volume to store metrics
 docker volume create jenkins-collector

4. Execute container. Set env JENKINS_API_KEY var with key from #5.4.2
 Execute:
     docker run \
        --link jenkins-server \
        --name jenkins-collector \
        -e JENKINS_SERVER=jenkins-server
        -e JENKINS_API_KEY="{key from #5.4.2}" \
        -m 256M \
        -ti jenkins-collector:latest

 Example: docker run --link jenkins-server --name jenkins-collector \
            -e JENKINS_SERVER=jenkins-server \
            -e JENKINS_API_KEY="A7PSMBeeRkKbrrMTuD4R9ST0mBZy2a1oSdWy0w4qF3zFY2J38KoSNN_JE10GhZLB" \
            -m 256M \
            -ti jenkins-collector:latest


5. Get metrics

This is API is fully graphite-api compatible. See http://graphite-api.readthedocs.io/en/latest/
It easy to get metrics on grafana dashboard. Export VMware-task-grafana-dash.json to grafana.

 Execute:
    docker run \
        --link=jenkins-collector \
        -d \
        --name=grafana \
        -p 3000:3000 \
        grafana/grafana

Exported data: https://snapshot.raintank.io/dashboard/snapshot/KdggN6Z5lsxO6fLYxXAAJPPlVaKfapIn

================================================================================================================

h1. Additional

In additional docker file to build jenkins slave with dynamic nodes registrations exists.

1. Change directory to jenkins-node
 ../jenkins-node/

2. Build docker image
 docker build --pull=true  -t jenkins-node .

3. Execute container
 docker run \
    --link jenkins-server \
    -e JENKINS_SERVER=jenkins-server \
    -m 256M \
    -ti jenkins-node:latest
