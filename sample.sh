#!/bin/sh

export AWS_DEFAULT_PROFILE={your_aws}

export EXPORT_TIMEZONE={JST or UTC}
export EXPORT_DATECMD={date or gdate}
export EXPORT_DESTINATION_S3BUCKET={your_s3bucket}

sh all.sh
