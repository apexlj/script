#!/bin/sh

#------------------------------------
# 開始/終わり時間
#------------------------------------
START="2013-06-13 10"
END="2013-06-13 11"

YEAR_MONTH=`echo $START | awk '{print $1}' | awk -F'-' '{print $1"-"$2"-"}'`
START_DAY=`echo $START | awk -F'-' '{print $3}' | awk '{print $1}'`
END_DAY=`echo $END | awk -F'-' '{print $3}' | awk '{print $1}'`
CURRENT_DAY=`date +'%e'`
START_TIME=`echo $START | awk '{print $2}'`
END_TIME=`echo $END | awk '{print $2}'`

#------------------------------------
# ディレクトリ
#------------------------------------
CTRL_LOG_DIR="/usr/local/rms/evt/rmail/log"
RESULT_DIR="/a/nmail01/vol/vol1/rms/evt/rmail/work/operation/20130603/data/result"

CURRENT_LOG_DIR="/usr/local/var/rmail"
FINISHED_LOG_DIR="$CURRENT_LOG_DIR/finished"

#------------------------------------
# tempフィアル
#------------------------------------
TARGET_LOG_RECORD="$RESULT_DIR/_target_log"
RMAIL_ID_LIST="$RESULT_DIR/_rmail_id_list"

#------------------------------------
# 結果フィアル
#------------------------------------
EXP_BOUNCED_LIST="$RESULT_DIR/exp_bounced_list.txt"
NOR_BOUNCED_LIST="$RESULT_DIR/nor_bounced_list.txt"

#------------------------------------
# iniフィアル
#------------------------------------
GET_BOUNCED_LIST_INI="get_bounced_list.ini"

#------------------------------------
# 配信ctrlサーバ
#------------------------------------
EXP_SERVER="bmctr10[1-8]c"
NOR_SERVER="bmctr1(09|1[1-2])c"

#------------------------------------
# function: チェック 
#------------------------------------
check() {
  echo "start to check..."

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
  echo "start to get tartget record..."

# 事前処理
  if [ -f $TARGET_LOG_RECORD ]; then
    rm $TARGET_LOG_RECORD
  fi

# 時間帯のログを抽出
  if [ "$START_DAY" == "$END_DAY" ]; then
    for time in `seq -f '%02g' $START_TIME $END_TIME`
    do
      for host in `seq -w 01 12`
      do
	if [ -f $CTRL_LOG_DIR/rmail_ctrl.bmctr1${host}c.log ]; then
	  egrep "$YEAR_MONTH$START_DAY $time" $CTRL_LOG_DIR/rmail_ctrl.bmctr1${host}c.log | egrep "Argument" >> $TARGET_LOG_RECORD
        fi
      done
    done
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
	  if [ -f $CTRL_LOG_DIR/rmail_ctrl.bmctr1${host}c.log ]; then 
	    egrep "$YEAR_MONTH$day $time" $CTRL_LOG_DIR/rmail_ctrl.bmctr1${host}c.log | egrep "Argument" >> $TARGET_LOG_RECORD
          fi
        done
      done
    done
  fi
}

#------------------------------------
# function: 抽出したctrl_logを整形
#------------------------------------
format() {
  echo "start to format..."
  if [ ! -f $TARGET_LOG_RECORD ]; then
    echo "$TARGET_LOG_RECORD is not existed!"
    exit 1
  fi  

  sed -i "/-mobile\|-decomail/d" $TARGET_LOG_RECORD
  sed -i "s/-multi //g" $TARGET_LOG_RECORD
  awk '{print $1" "$2" "$3" "$6" "$7}' $TARGET_LOG_RECORD | sed 's/\[\|\]//g' > $RMAIL_ID_LIST 
  sed -i "s/rmail_sendプロセスを起動しました。Argument://g" $RMAIL_ID_LIST
}
#------------------------------------
# function: remove tmp files 
#------------------------------------
remove_tmp_files() {
  if [ -f $TARGET_LOG_RECORD ]; then
    rm $TARGET_LOG_RECORD
  fi

  if [ -f $RMAIL_ID_LIST ]; then
    rm $RMAIL_ID_LIST
  fi  
}

#------------------------------------
# function: get bounced list 
#------------------------------------
get_bounced_list() {
  if [ ! -f $RMAIL_ID_LIST ]; then
    echo "The $RMAIL_ID_LIST is not existed!"
    exit 1
  fi

  domain_pattern=`awk '{printf "%s |",$3}' $GET_BOUNCED_LIST_INI | sed 's/ |$//g' | sed 's/\./\\\./g'`

  while read date time host rmail_id shop_id
  do
    send_day=`echo $date | cut -d'-' -f3`
    if [ $send_day -eq $CURRENT_DAY ]; then
      #当日
      list_R="$CURRENT_LOG_DIR/${rmail_id}.*/list_R" 
    else
      #当日より前
      formated_date=`echo $date | sed "s/-//g"`
      list_R="$FINISHED_LOG_DIR/${formated_date}/${shop_id}/${rmail_id}/*/list_R" 
    fi  

    bounced_num=`ssh -n $host "egrep '${domain_pattern}' ${list_R} | wc -l"`
    sent_num=`ssh -n $host "cat ${list_R} | wc -l"`
    
    echo "$host" | egrep $EXP_SERVER

    if [ $? -eq 0 ]; then
      printf "%s\t%s\t%s\t%s\n" ${shop_id} ${rmail_id} ${sent_num} ${bounced_num} >> $EXP_BOUNCED_LIST
    else
      printf "%s\t%s\t%s\t%s\n" ${shop_id} ${rmail_id} ${sent_num} ${bounced_num} >> $NOR_BOUNCED_LIST
    fi

  done < $RMAIL_ID_LIST

}

#------------------------------------
# function: main 
#------------------------------------
main() {
  get_target_record
  format
  get_bounced_list
  remove_tmp_files
}

main
