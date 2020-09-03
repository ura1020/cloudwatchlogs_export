#!/bin/sh

#===================================================================================
# Amazon CloudWatchLogsをs3に日時エクスポート
# author ura1020
#===================================================================================

if [ $# -lt 1 ]; then
  echo "Usage: $0 loggroup [exportdir] [YYYY-MM-DD]" 1>&2
  exit 1
fi

EXPORT_DATECMD=${EXPORT_DATECMD:-date}
EXPORT_DESTINATION_S3BUCKET=$EXPORT_DESTINATION_S3BUCKET

start_time=$($EXPORT_DATECMD '+%Y-%m-%d %H:%M:%S')
echo "start_time:$start_time"

log_group_name=$1

default_exportdir=$(echo ${log_group_name//\//_} | sed 's/,/t/g')
exportdir=${2:-$default_exportdir}

default_date=$($EXPORT_DATECMD --date '1 day ago' +%Y-%m-%d)
target_date=${3:-$default_date}

hours=(00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23)
for hour in ${hours[@]} ; do
  # 取得範囲(unixtime)
  log_start_time=$($EXPORT_DATECMD +%s --date="$target_date $hour:00:00")000
  log_end_time=$($EXPORT_DATECMD +%s --date="$target_date $hour:59:59")999

  # エクスポート実施
  task_id=$(aws logs create-export-task \
    --task-name "export-${log_group_name}-${target_date}-${hour}" \
    --log-group-name "${log_group_name}" \
    --from ${log_start_time} \
    --to ${log_end_time} \
    --destination "${EXPORT_DESTINATION_S3BUCKET}" \
    --destination-prefix "${exportdir}/${target_date}/${hour}" \
    --query 'taskId' \
    --output text)
  echo "task_id:$task_id"

  # タスク状況確認(完了まで監視する)

  # 待ち時間(徐々に長くする)
  wait_seconds=(1 2 4 8 16 32 64 128 256 512 1024 2048 4096)
  # 計8191秒=最長2時間強待つ
  limit=${#wait_seconds[@]}
  echo "limit:$limit"

  regex='COMPLETED'
  count=0
  while [ 1 ];
  do
    wait=${wait_seconds[count]}
    echo "sleep $wait"
    sleep $wait

    status_code=$(aws logs describe-export-tasks \
      --task-id "${task_id}" \
      --query 'exportTasks[].status[].code' \
      --output text)
    echo "status_code:$status_code"
    if [[ $status_code =~ $regex ]]; then
      break
    fi

    let count++
    echo "count:$count"
    if [[ $count -ge $limit ]]; then
      echo "timeout"
      break
    fi
  done
done

aws s3 ls ${EXPORT_DESTINATION_S3BUCKET}/${exportdir}/${target_date} \
  --recursive \
  --human \
  --sum

end_time=$($EXPORT_DATECMD '+%Y-%m-%d %H:%M:%S')
echo "end_time:$end_time"
