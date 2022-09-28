#!/bin/bash
profile="default"
olddate="2021-01-01"
smallbucketsize=10

emptybucketlist=()
oldbucketlist=()
smallbucketlist=()

#for bucketlist in  $(aws s3api list-buckets  --profile $profile  | jq --raw-output '.Buckets[6,7,8,9].Name'); # test this script on just a few buckets
for bucketlist in  $(aws s3api list-buckets  --profile $profile  | jq --raw-output '.Buckets[].Name');
do
  echo "* $bucketlist"
  if [[ ! "$bucketlist" == *"shmr-logs" ]]; then
    listobjects=$(\
      aws s3api list-objects --bucket $bucketlist \
      --query 'Contents[*].Key' \
      --profile $profile)
#echo "==$listobjects=="
    if [[ "$listobjects" == "null" ]]; then
          echo "$bucketlist is empty"
          emptybucketlist+=("$bucketlist")
    else
      # get size
      aws s3 ls --summarize  --human-readable --recursive --profile $profile s3://$bucketlist | tail -n1

      # get number of files
      filecount=$(echo $listobjects | jq length )
      echo "contains $filecount files"
      if [[ $filecount -lt $smallbucketsize ]]; then
          smallbucketlist+=("$bucketlist")
      fi

      # get number of files older than $olddate
      listoldobjects=$(\
        aws s3api list-objects --bucket $bucketlist \
        --query "Contents[?LastModified<=\`$olddate\`]" \
        --profile $profile)
      oldfilecount=$(echo $listoldobjects | jq length )
      echo "contains $oldfilecount old files"

      # check if all files are old
      if [[ $filecount -eq $oldfilecount ]]; then
        echo "all the files are old"
        oldbucketlist+=("$bucketlist")

      fi
    fi
  fi
done
echo -e "\n\n"

echo "check the contents of these buckets which only contain old files"
for oldbuckets in ${oldbucketlist[@]};
do
  echo "$oldbuckets"
done
echo -e "\n\n"

echo "check the contents of these buckets which don't have many files"
for smallbuckets in ${smallbucketlist[@]};
do
  echo "aws s3api list-objects --bucket $smallbuckets --query 'Contents[*].Key' --profile $profile"
done
echo -e "\n\n"

echo "consider deleting these empty buckets"
for emptybuckets in "${emptybucketlist[@]}";
do
  echo "aws s3api delete-bucket --profile $profile --bucket $emptybuckets"
done