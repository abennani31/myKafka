# Kafka / Zookeeper Docker Image 

This is a java 8 image that contains kafka and zookeeper it has been designed to allow the simple setup and config of a multi host ensemble (cluster)

To build the image yourself run the following command # (Note the trailing dot!)

### docker build -t krisdavison/kafka-zookeeper-cluster . 

The github repo contains a sample docker-compose file showing how to spin up a three node cluster and kafka-manager for monitoring.
Below is a example of each node and a description of what the fields are for.
```
zookaf1:
  image: krisdavison/kafka-zookeeper-cluster
  hostname: zoo1					# internal docker container hostname
  extra_hosts:						# host names of the other docker containers in the cluster and the ip of the box they run on. 
    - "zoo2:192.168.5.2"
    - "zoo3:192.168.5.3"
  ports:
    - "2181:2181"					# public zookeeper port mapping to container
    - "9092:9092"					# public kafka port mapping to container
    - "2888:2888"					# port used by zookeeper to maintain the ensemble (cluster) 
    - "3888:3888"					# port used by zookeeper to maintain the ensemble (cluster) 
  environment:
    NODE_ID: 1						# ID of the node in the cluster (idealy 1 to ... however many nodes you have )
    ZOOKEEPER_NODES: 192.168.5.1:2888:3888,192.168.5.2:2888:3888,192.168.5.3:2888:3888 					# list of zookeeper nodes with internal ensemble ports
    KAFA_ADVERTISED_NODES: PLAINTEXT://192.168.5.1:9092,PLAINTEXT://192.168.5.2:9092,PLAINTEXT://192.168.5.3:9092       # list of kafka nodes with public kafka port
    KAFKA_CONNECT: 192.168.5.1:2181,192.168.5.2:2181,192.168.5.3:2181							# list of zookeeper nodes with public port (used by kafka to connect)
```
To run the docker compose file use the following command

### docker-compose -p kaf -f docker-compose-cluster.yml up -d

BUT remember you will have to create a different docker-compose file for each node in your cluster - the included one is for reference only and assumes alot about ip addresses etc. 

