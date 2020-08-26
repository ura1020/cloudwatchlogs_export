#!/bin/sh

if [ $# -lt 1 ]; then
  echo "Usage: $0 YYYY-MM-DD" 1>&2
  exit 1
fi

export AWS_DEFAULT_PROFILE={your_aws_profile}

export EXPORT_DATECMD={date or gdate}
export EXPORT_DESTINATION_S3BUCKET={your_s3bucket}

sh export.sh "CloudWatchLogGroup" "S3BucketFolder" $1
