#!/usr/bin/env bash

#docker env
#PRODUCT_NAME="codis-dingxin"
#COORDINATOR_NAME=zookeeper
#COORDINATOR_ADDR=zoo1:2181

CODIS_ADMIN="${BASH_SOURCE-$0}"
CODIS_ADMIN="$(dirname "${CODIS_ADMIN}")"
CODIS_ADMIN_DIR="$(cd "${CODIS_ADMIN}"; pwd)"

CODIS_BIN_DIR=$CODIS_ADMIN_DIR/../bin
CODIS_LOG_DIR=$CODIS_ADMIN_DIR/../log
CODIS_CONF_DIR=$CODIS_ADMIN_DIR/../config

CODIS_DASHBOARD_BIN=$CODIS_BIN_DIR/codis-dashboard
CODIS_ADMIN_TOOL_BIN=$CODIS_BIN_DIR/codis-admin
CODIS_DASHBOARD_PID_FILE=$CODIS_BIN_DIR/codis-dashboard.pid

CODIS_DASHBOARD_LOG_FILE=$CODIS_LOG_DIR/codis-dashboard.log
CODIS_DASHBOARD_DAEMON_FILE=$CODIS_LOG_DIR/codis-dashboard.out

CODIS_DASHBOARD_CONF_FILE=$CODIS_CONF_DIR/dashboard.toml

ADMIN_ADDR="$PODIP:18080"

echo $CODIS_DASHBOARD_CONF_FILE

if [ "${PRODUCT_NAME}x" = "x" ]; then
    PRODUCT_NAME="codis-dingxin"
fi
sed -i "/^product_name/d" $CODIS_DASHBOARD_CONF_FILE
sed -i "/^coordinator_name/d" $CODIS_DASHBOARD_CONF_FILE
sed -i "/^coordinator_addr/d" $CODIS_DASHBOARD_CONF_FILE
sed -i "/^admin_addr/d" $CODIS_DASHBOARD_CONF_FILE
echo "product_name = \"$PRODUCT_NAME\"">>$CODIS_DASHBOARD_CONF_FILE
echo "coordinator_name = \"$COORDINATOR_NAME\"">>$CODIS_DASHBOARD_CONF_FILE
echo "coordinator_addr = \"$COORDINATOR_ADDR\"">>$CODIS_DASHBOARD_CONF_FILE
echo "admin_addr = \"$ADMIN_ADDR\"">>$CODIS_DASHBOARD_CONF_FILE


if [ ! -d $CODIS_LOG_DIR ]; then
    mkdir -p $CODIS_LOG_DIR
fi


case $1 in
start)
    echo  "starting codis-dashboard ... "
    if [ -f "$CODIS_DASHBOARD_PID_FILE" ]; then
      if kill -0 `cat "$CODIS_DASHBOARD_PID_FILE"` > /dev/null 2>&1; then
         echo $command already running as process `cat "$CODIS_DASHBOARD_PID_FILE"`.
         exit 0
      fi
    fi
    nohup "$CODIS_DASHBOARD_BIN" "--config=${CODIS_DASHBOARD_CONF_FILE}" \
    "--log=$CODIS_DASHBOARD_LOG_FILE" "--log-level=INFO" "--pidfile=$CODIS_DASHBOARD_PID_FILE" > "$CODIS_DASHBOARD_DAEMON_FILE" 2>&1 < /dev/null &
    ;;
start-foreground)
    $CODIS_DASHBOARD_BIN "--config=${CODIS_DASHBOARD_CONF_FILE}" \
    "--log-level=DEBUG" "--pidfile=$CODIS_DASHBOARD_PID_FILE"
    ;;
stop)
    echo "stopping codis-dashboard ... "
    if [ ! -f "$CODIS_DASHBOARD_PID_FILE" ]
    then
      echo "no codis-dashboard to stop (could not find file $CODIS_DASHBOARD_PID_FILE)"
    else
      kill -2 $(cat "$CODIS_DASHBOARD_PID_FILE")
      echo STOPPED
    fi
    exit 0
    ;;
stop-forced)
    echo "stopping codis-dashboard ... "
    if [ ! -f "$CODIS_DASHBOARD_PID_FILE" ]
    then
      echo "no codis-dashboard to stop (could not find file $CODIS_DASHBOARD_PID_FILE)"
    else
      kill -9 $(cat "$CODIS_DASHBOARD_PID_FILE")
      rm "$CODIS_DASHBOARD_PID_FILE"
      echo STOPPED
    fi
    exit 0
    ;;
restart)
    shift
    "$0" stop
    sleep 1
    "$0" start
    ;;
remove-lock)
    $CODIS_ADMIN_TOOL_BIN -v --remove-lock --product="${PRODUCT_NAME}" --${coordinator_name}="${COORDINATOR_ADDR}"
    ;;
*)
    echo "Usage: $0 {start|start-foreground|stop|stop-forced|restart|remove-lock}" >&2

esac
