#!/bin/sh

#------------------------------------
# 開始/終わり時間
#------------------------------------
START="2013-06-03 01"
END="2013-06-07 03"

YEAR_MONTH=`echo $START | awk '{print $1}' | awk -F'-' '{print $1"-"$2"-"}'`
START_DAY=`echo $START | awk -F'-' '{print $3}' | awk '{print $1}'`
END_DAY=`echo $END | awk -F'-' '{print $3}' | awk '{print $1}'`
CURRENT_DAY=`date +'%e'`
START_TIME=`echo $START | awk '{print $2}'`
END_TIME=`echo $END | awk '{print $2}'`
#------------------------------------
# ディレクトリ定義
#------------------------------------
CTRL_LOG_DIR="/home/apex/script_git/shell/bounced_list/log"
RESULT_DIR="/home/apex/script_git/shell/bounced_list/result"

CURRENT_LOG_DIR="/usr/local/var/rmail"
FINISHED_LOG_DIR="$CURRENT_LOG_DIR/finished"

#------------------------------------
# function: チェック 
#------------------------------------
check() {
# 開始日/終わりの日 チェック
  if [ $(( $CURRENT_DAY - $START_DAY )) -ge 5 ]; then
    echo "The start day should be within 5 days!"
    exit 1
  fi

  if [ $START_DAY -gt $END_DAY ]; then
    echo "The start day should be smaller than end day!"
    exit 1
  fi

  if [ $END_DAY -gt $CURRENT_DAY ]; then
    echo "The end day should be smaller than current day!"
    exit 1
  fi

# 開始時間/終わりの時間 チェック
  if [ "$START_DAY" == "$END_DAY" ]; then
    if [ $START_TIME -gt $END_TIME ]; then
      echo "The start time should be smaller than end time!"
      exit 1
    fi
  fi
}

#------------------------------------
# function: 時間帯のログを抽出
#------------------------------------
get_target_record() {

  check

# 事前処理
  if [ -f $RESULT_DIR/target_record ]; then
    rm $RESULT_DIR/target_record
  fi

# 時間帯のログを抽出
  if [ "$START_DAY" == "$END_DAY" ]; then
    for time in `seq -w $START_TIME $END_TIME`
    do
      for host in `seq -w 01 12`
      do
	if [ -f $CTRL_LOG_DIR/bmctr1${host}c.rmail.log ]; then
	  egrep "$YEAR_MONTH$START_DAY $time" $CTRL_LOG_DIR/bmctr1${host}c.rmail.log | egrep "Argument" >> $RESULT_DIR/target_record
        fi
      done
    done
    exit 0
  else
    for day in `seq -w $START_DAY $END_DAY`
    do

      start="00"
      end="23"

      if [ "$day" == "$START_DAY" ]; then
	start=$START_TIME
      elif [ "$day" == "$END_DAY" ]; then
	end=$END_TIME
      fi

      for time in `seq -w $start $end`
      do
	for host in `seq -w 01 12`
	do
	  if [ -f $CTRL_LOG_DIR/bmctr1${host}c.rmail.log ]; then 
	    egrep "$YEAR_MONTH$day $time" $CTRL_LOG_DIR/bmctr1${host}c.rmail.log | egrep "Argument" >> $RESULT_DIR/target_record
          fi
        done
      done
    done
  fi
}

#------------------------------------
# function: 抽出した結果を整形
#------------------------------------
format() {
  if [ ! -f $RESULT_DIR/target_record ]; then
    echo "$RESULT_DIR/target_record is not existed!"
    exit 1
  fi  

  sed -i "/-mobile\|-decomail/d" $RESULT_DIR/target_record
  sed -i "s/-multi //g" $RESULT_DIR/target_record
  awk '{print $1" "$2" "$3" "$6" "$7}' $RESULT_DIR/target_record | sed 's/\[\|\]//g' > $RESULT_DIR/server_shop_rmail_id_list 
  sed -i "s/rmail_sendプロセスを起動しました。Argument://g" $RESULT_DIR/server_shop_rmail_id_list
}

#------------------------------------
# function: express 
#------------------------------------
get_bounced_list() {
  if [ ! -f $RESULT_DIR/server_shop_rmail_id_list ]; then
    echo "The $RESULT_DIR/server_shop_rmail_id_list is not existed!"
    exit 1
  fi

  while read date time host rmail_id shop_id
  do
    send_day=`echo $date | cut -d'-' -f3`
    if [ $send_day -eq $CURRENT_DAY ]; then
      echo ""
    fi
  done < $RESULT_DIR/server_shop_rmail_id_list

}
get_target_record
format
