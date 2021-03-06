#!/bin/bash
set -e

usage() {
  echo -e "
  usage: $0 options

  Configures and starts Kafka inside a docker container.

  OPTIONS:
    -h Show this message
    -z list of zookeeper nodes
    -i kafka broker id
    -H hostname to advertise
    -p port to advertise
    "
}

HOST=
PORT=
ZKS=
BROKER_ID=
KAFKA_VERSION="$SCALA_VERSION"-"$KAFKA_VERSION"
TOPIC_DELETE=false

while getopts "hz:i:H:p:t:" OPTION
do
  case $OPTION in
    h)
      usage
      exit 1
      ;;
    z)
      ZKS=$OPTARG
      ;;
    i)
      BROKER_ID=$OPTARG
      ;;
    H)
      HOST=$OPTARG
      ;;
    p)
      PORT=$OPTARG
      ;;
    t)
      TOPIC_DELETE=$OPTARG
      ;;
    ?)
      usage
      exit 1
      ;;
  esac
done

if [[ -z $ZKS ]];
then
  ZKS=$ZK_PORT_2181_TCP_ADDR
fi

if [[ -z $ZKS ]] || [[ -z $BROKER_ID ]] || [[ -z $HOST ]] || [[ -z $PORT ]];
then
  usage
  exit 1
fi

if [[ $HOST == "__aws_local_hostname" ]]
then
    HOST=$(hostname)
fi

cat << EOF > "/opt/kafka_$KAFKA_VERSION/config/server.properties"
broker.id=$BROKER_ID
port=9092
advertised.host.name=$HOST
advertised.port=$PORT
num.network.threads=2
num.io.threads=2
socket.send.buffer.bytes=1048576
socket.receive.buffer.bytes=1048576
socket.request.max.bytes=104857600
num.partitions=2
delete.topic.enable=$TOPIC_DELETE
log.dirs=/opt/kafka/log
log.flush.interval.messages=10000
log.flush.interval.ms=1000
log.retention.hours=168
log.segment.bytes=536870912
log.cleanup.interval.mins=1
zookeeper.connect=$ZKS
EOF

mkdir -p /opt/kafka/log

./opt/kafka_$KAFKA_VERSION/bin/kafka-server-start.sh /opt/kafka_$KAFKA_VERSION/config/server.properties
