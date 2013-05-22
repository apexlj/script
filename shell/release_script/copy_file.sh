#!/bin/bash

#TO="/usr/local/rms/evt/rmail/php-P5/lib/"
#FROM="/home/lijiang01/rmail4/php-P5/lib/"

TO="/home/lijiang01/rmail4/php-P5/"
FROM="/usr/local/rms/evt/rmail/php-P5/"

file_list=$1

if [ "$file_list" == "" ]; then
    echo "Please input file name."
    exit 1
elif [ ! -f "$file_list" ]; then
    echo "File does not exist!"
    exit 1
fi

echo "-------------------------------"
echo "From: ${FROM}"
printf "To: ${TO}\n\n"
echo "File List:"

while read path; do
    if [ -z $path ]; then
        continue
    fi
    dir="`dirname $path`/"
    file=`basename $path`
    from_dir="${FROM}${dir}"
    if [ ! -f "${from_dir}${file}" ]; then
        echo "${from_dir}${file} does not exist!"
        continue
    fi
    echo "${from_dir}${file}"
done < $file_list 

echo "-------------------------------"
echo "Do u want to copy all files?(y/n) "
read flag

if [ "$flag" == "y" ]; then

    while read path; do
        if [ -z $path ]; then
            continue
        fi
        dir="`dirname $path`/"
        file=`basename $path`
        to_dir="${TO}${dir}/"
        if [ ! -d "$to_dir" ]; then
            mkdir -p $to_dir
        fi
        cp ${FROM}${dir}${file} ${to_dir}
        if [ $? -eq 0 ]; then
            echo "${file} was copied."
        fi
    done < $file_list 

elif [ "$flag" == "n" ]; then
    exit 0
fi

exit 0
