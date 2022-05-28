#!/bin/bash

# Define variables
RUN_TIME=$(date +%d%m%y-%H%M%S)
TCPD_OUTPUT_PATH=./packet-capture
TCPD_OUTPUT_FILE=listmq-${RUN_TIME}
# Preset default values for parameters
RBT_USERNAME="admin"
RBT_PASSWORD="admin"
RBT_HOST="localhost"
RBT_PORT="15672"

# Define print help function
print_help () {
  cat << EOF
USAGE: listmq.sh [OPTION]
Options:
  -h Print help
  -u RabbitMQ username [admin]
  -p RabbitMQ password [admin]
  -H RabbitMQ hostname or IP [localhost]
  -P RabbitMQ port [15672]

Packet capture with tcpdump runs during RabbitMQ API call execution saving binary capture to ${TCPD_OUTPUT_PATH}
EOF
}

# Check if curl available
if ! curl -V > /dev/null 2>&1 ; then
  echo "Curl not installed, please install curl first... exiting!"
  exit 0
fi

# Check for flags
if [[ $# -eq 0 ]] ; then
  print_help
  exit 0
fi

# Define flags
while getopts "u:p:H:P:h" opt; do
  case ${opt} in
    u)
      RBT_USERNAME=${OPTARG}
      ;;
    p)
      RBT_PASSWORD=${OPTARG}
      ;;
    H)
      RBT_HOST=${OPTARG}
      ;;
    P)
      RBT_PORT=${OPTARG}
      ;;
    h)
      print_help
      exit
      ;;
    \?)
      echo "Invalid option: -${OPTARG}"
      print_help
      exit 1
      ;;
    :)
      echo "Option -${OPTARG} requires an argument."
      print_help
      exit 1
      ;;
  esac
done

# Run packet capture
# Params:
# -U Will cause output to be ``packet-buffered'',
#    so that the output is written to stdout at the end of each packet rather than at the end of each line;
#    this is buffered on all platforms, including Windows.
# -w Write raw packets to file.
# -n No IP/Hostname translations
tcpdump -Un host ${RBT_HOST} and port ${RBT_PORT} -w ${TCPD_OUTPUT_PATH}/${TCPD_OUTPUT_FILE} > /dev/null 2>&1 &
sleep 1

# Connect to RabbitMQ and get queues and parse them through jq creating desired objects
curl \
--silent \
--request GET \
--user ${RBT_USERNAME}:${RBT_PASSWORD} \
--url http://${RBT_HOST}:${RBT_PORT}/api/queues | jq '.[] | {name: .name, type: .type}'

# Terminate packet capture @todo: Set tcpdump parameters in VARs so it hasn't to be edited twice on init/kill
sleep 1
kill -2 $(pgrep -f "tcpdump -Un host ${RBT_HOST} and port ${RBT_PORT} -w ${TCPD_OUTPUT_PATH}/${TCPD_OUTPUT_FILE}")
