#!/bin/sh

EXPORT_TIMEZONE=${EXPORT_TIMEZONE:-JST}
EXPORT_DATECMD=${EXPORT_DATECMD:-date}
EXPORT_DESTINATION_S3BUCKET=$EXPORT_DESTINATION_S3BUCKET

loggroups=$(aws logs describe-log-groups \
  --query logGroups[].logGroupName \
  --output text)

for loggroup in $loggroups;
do
  echo $loggroup
  sh export.sh $loggroup
done

# サイズ確認
aws s3 ls ${EXPORT_DESTINATION_S3BUCKET} \
  --recursive \
  --human \
  --sum
