#!/usr/bin/bash
# 1.check ecch line of trainlist, the image exsist or not?
# 2. record the size = 0 image file.

# usage: bash filecheck.sh training.npy 20 32
# param:
#       $1 filenae you need to processing
#       $2 num of process to handle part files. eg, 20
#       $3 size of part fil. eg 32m(MB)/200k(kb)
# single process:
#       $1 = train.npy
#       $2 = 1
#       $3 = size, (size > size of train.npy)
# inner parrael:
#       $1 = train.npy
#       $2 = 10 (# of process)
#       $3 = size, (size > size of train.npy)

# inner parrael:
#       $1 = train.npy
#       $2 = 10 (# of process)
#       $3 = size, (size > size of train.npy)



# get param
if [[ ! -n $1 ]]; then
  echo "please set name of the file need to processing !"
  exit 1
else
  FILE=$1
fi
if [[ ! -n $2 ]]; then
  echo "please set num of processes to run !"
  exit 2
else
  NUM_PROCESS=$2
fi
if [[ ! -n $3 ]]; then
  echo "please the filesize you machine coulud handle at one time such as 32 (MB)"
  exit 3
else
  PART_FILESIZE=$3
fi

# file clean
if [[ -f clean_${FILE} ]]; then
  rm clean_${FILE}
fi
rm -rf ${FILE}_*


# split file
split -b ${PART_FILESIZE} $FILE ${FILE}_ -d -a 4
NUM_PARTFILES=`ls ${FILE}_* | wc -l | awk '{print $1}'`

START_TIME=`date +%s%N`
for (( j = 0; j < $NUM_PARTFILES; j++ )); do
  {
    START_PART=`date +%s%N`
    INDEX_OUT=`printf "%04d\n" $j`
    # split partfile
    NUM_LINES=`wc -l ${FILE}_${INDEX_OUT} | awk '{print $1}'`
    SUB_LINES=$(($NUM_LINES/$NUM_PROCESS))
    split -l $SUB_LINES ${FILE}_${INDEX_OUT} ${FILE}_${INDEX_OUT}_ -d -a 4

    for (( i = 0; i < $NUM_PROCESS; i++ )); do
    {
      INDEX_IN=`printf "%04d\n" $i`
      cat ${FILE}_${INDEX_OUT}_${INDEX_IN} | while read LINE; do
      {
        FILE_NAME=`echo $LINE | awk '{print $1}'`
        if [[ -f $FILE_NAME ]]; then
          FILE_SIZE=`du -b $FILE_NAME | awk '{print $1}'`
          if [[ $FILE_SIZE -ne 0 ]]; then
            echo $LINE >> clean_${FILE}_${INDEX_OUT}_${INDEX_IN}
          fi
        fi
      }
      done
    }&
    # inner parrael run
    done
    # wait all process finished.
    wait
    # combine sub part files
    cat clean_${FILE}_${INDEX_OUT}_* > clean_${FILE}_${INDEX_OUT}
    rm -rf clean_${FILE}_${INDEX_OUT}_*
    # rm sub prat files
    rm -rf ${FILE}_${INDEX_OUT}_*

    # disp
    END_PART=`date +%s%N`;
    PART_TIME=`echo $END_PART $START_PART | awk '{ print ($1 - $2) / 1000000000}'`
    N=`printf "%04d\n" $NUM_PARTFILES`
    echo "processing #$INDEX_OUT/$N cost $PART_TIME seconds."
  }
done
# combine part file
cat clean_${FILE}_* > clean_${FILE}
rm -rf clean_${FILE}_*
# rm part files
rm -rf ${FILE}_*
# time elapsed
END_TIME=`date +%s%N`;
USE_TIME=`echo $END_TIME $START_TIME | awk '{ print ($1 - $2) / 1000000000}'`
echo "# Total cost $USE_TIME seconds."
# wait all batch finesh
