#!/bin/sh

for day in `seq -w 02 06`
do
  for hour in `seq -w 00 23`
  do
    printf "2013-06-%s %s:01:01\n" $day $hour >> test_data
  done
done
