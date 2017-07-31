#!/bin/bash

# logging functions
function INFO {
  LOGOUT "INFO $1"
}
function WARN {
 LOGOUT "WARN $1"
}
function ERROR {
 LOGOUT "ERROR $1"
}
function LOGOUT {
  CURDATE=`date +"%Y-%m-%d %H:%M:%S,%3N"`
  echo "[$CURDATE] $1 (startup.sh)"
}

# get local internal docker ip
MY_IP=`awk 'NR==1 {print $1}' /etc/hosts` 
INFO "Starting .... Docker IP is $MY_IP"

# convert csv strings into arrays
IFS=',' read -r -a ZOO_ARRAY <<< "$ZOOKEEPER_NODES"
IFS=',' read -r -a KAF_ARRAY <<< "$KAFA_ADVERTISED_NODES"

# count elements in each array
NUM_KAF="${#KAF_ARRAY[@]}"
NUM_ZOO="${#ZOO_ARRAY[@]}"

# check to make sure there are the same number of elements in each array
if [ "$NUM_ZOO" -ne "$NUM_KAF" ]; then
  ERROR "Variables ZOOKEEPER_NODES and KAFKA_NODES are different lengths."
  exit 1
fi

############ Node ID Specific ZOOKEEPER and KAFKA Setup ##########
NODE_COUNT=0

for ((COUNT=1; COUNT<=$NUM_KAF; COUNT++ ))
do
  # get values from arrays before counter is incremented (as node 1 is array element 0 )
  ZNODE="${ZOO_ARRAY[$NODE_COUNT]}"
  KNODE="${KAF_ARRAY[$NODE_COUNT]}"

  # incremenet node counter (as array element 0 is node 1)
  ((NODE_COUNT++))

  # add configuration based on Node ID
  if [ "$NODE_ID" == "$NODE_COUNT" ]; then
    echo "server.$NODE_COUNT=$MY_IP:2888:3888" >> $KAFKA_HOME/config/zookeeper.properties
    echo "advertised.listeners=$KNODE" >> $KAFKA_HOME/config/server.properties
  else
    echo "server.$NODE_COUNT=$ZNODE" >> $KAFKA_HOME/config/zookeeper.properties
  fi  

done


################# Other ZOOKEEPER setup ########################
# check if initlimit or sync limit have been set and use defaults if not.
if [ -z "$KAFKA_INIT_LIMIT" ]; then
  echo "initLimit=20" >> $KAFKA_HOME/config/zookeeper.properties
else
  echo "initLimit=$KAFKA_INIT_LIMIT" >> $KAFKA_HOME/config/zookeeper.properties
fi

if [ -z "$KAFKA_SYNC_LIMIT" ]; then
  echo "syncLimit=30" >> $KAFKA_HOME/config/zookeeper.properties
else
  echo "syncLimit=$KAFKA_SYNC_LIMIT" >> $KAFKA_HOME/config/zookeeper.properties
fi

# create zookeeper dir
mkdir -p /tmp/zookeeper
# create zookeeper node id file
echo "$NODE_ID" > /tmp/zookeeper/myid

# start zookeeper in background thread
$KAFKA_HOME/bin/zookeeper-server-start.sh $KAFKA_HOME/config/zookeeper.properties &
INFO "pausing while we wait for zookeeper to start..."
sleep 5


################# Other KAFKA setup ########################
sed -i "s/broker.id=0/broker.id=$NODE_ID/" $KAFKA_HOME/config/server.properties
sed -i "s/zookeeper.connect=192.168.99.100:2181/zookeeper.connect=$KAFKA_CONNECT/" $KAFKA_HOME/config/server.properties
echo "default.replication.factor=2" >> $KAFKA_HOME/config/server.properties
echo "auto.create.topics.enable=true" >> $KAFKA_HOME/config/server.properties
echo "zookeeper.connection.timeout.ms=60000" >> $KAFKA_HOME/config/server.properties

$KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties 
