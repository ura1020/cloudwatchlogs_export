#!/bin/sh

#===================================================================================
# Amazon CloudWatchLogsをs3に日時エクスポート
# author ura1020
#===================================================================================

if [ $# -lt 1 ]; then
  echo "Usage: $0 loggroup YYYY-MM-DD" 1>&2
  exit 1
fi

EXPORT_DATECMD=${EXPORT_DATECMD:-date}
EXPORT_DESTINATION_S3BUCKET=$EXPORT_DESTINATION_S3BUCKET

start_time=$($EXPORT_DATECMD '+%Y-%m-%d %H:%M:%S')
echo "start_time:$start_time"

log_group_name=$1

# s3上で深いディレクトリ構造にならないよう/を_に置換
encode_log_group_name=$(echo ${log_group_name//\//_} | sed 's/,/t/g')

default_date=$($EXPORT_DATECMD --date '1 day ago' +%Y-%m-%d)
target_date=${2:-$default_date}

# 取得範囲(unixtime)
log_start_time=$($EXPORT_DATECMD +%s --date="$target_date 00:00:00")000
log_end_time=$($EXPORT_DATECMD +%s --date="$target_date 23:59:59")999

# エクスポート実施
task_id=$(aws logs create-export-task \
  --task-name "export-${log_group_name}-${target_date}" \
  --log-group-name "${log_group_name}" \
  --from ${log_start_time} \
  --to ${log_end_time} \
  --destination "${EXPORT_DESTINATION_S3BUCKET}" \
  --destination-prefix "${encode_log_group_name}/${target_date}" \
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

end_time=$($EXPORT_DATECMD '+%Y-%m-%d %H:%M:%S')
echo "end_time:$start_time"
