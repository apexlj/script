#!/bin/sh

#--------------------------------
# auto cvs operation
#--------------------------------
# auto_cvs.sh -a add_file_list -r remove_file_list
# auto_cvs.sh -a add_file_list
# auto_cvs.sh -r remove_file_list

# define
CVS_DIR="/home/apex/script_git/shell/release_script/cvs_dir/"
WORD_DIR="/home/apex/script_git/shell/release_script/work_dir/"

# usage
usage() {
  echo "Wrong usage!"
  echo "auto_cvs.sh -a add_file_list -r remove_file_list"
  echo "auto_cvs.sh -r remove_file_list -a add_file_list"
  echo "auto_cvs.sh -r remove_file_list"
  echo "auto_cvs.sh -a add_file_list"
  exit 1
}

# get option
if [ $# -eq 4 ]; then
  case $1 in
    "-a")
      ADD_FILE_LIST=$2
      if [ "$3" != "-r" ]; then
	usage
      else
	REMOVE_FILE_LIST=$4
      fi ;;
    "-r")
      REMOVE_FILE_LIST=$2
      if [ "$3" != "-a" ]; then
	usage
      else
	ADD_FILE_LIST=$4
      fi ;;
    *)
      usage ;;
  esac
elif [ $# -eq 2 ]; then
  case $1 in
    "-a")
      ADD_FILE_LIST=$2;;
    "-r")
      REMOVE_FILE_LIST=$2;;
    *)
      usage;;
  esac
else
  usage
fi

main() {
  if [ ! -z $ADD_FILE_LIST ]; then
    add
  fi
  if [ ! -z $REMOVE_FILE_LIST ]; then
    remove
  fi
}
# function : add_file
exe_cmd() {

  cmd=$1
  type=$2
  file_list=$3

  while read path; do
    if [ -z $path ]; then
      continue
    fi
    dir_name=`dirname $path`
    file_name=`basename $path`
    file=${dir_name}/${file_name}
    if [ "$cmd" == "add" ]; then

      if [ -f ${WORD_DIR}${file} ]; then

	if [ "$type" == "info" ]; then
          echo "${WORD_DIR}${file}"
        elif [ "$type" == "exe" ]; then
          if [ -f ${CVS_DIR}${file} ]; then
	    echo "cp ${WORD_DIR}${file} ${CVS_DIR}${file}"
          else
	    echo "cp ${WORD_DIR}${file} ${CVS_DIR}${file}"
	    echo "cvs add ${CVS_DIR}${file}"
          fi
        fi

      else

	if [ "$type" == "info" ]; then
	  MSG="${MSG}${WORD_DIR}${file}\n" 
	elif [ "$type" == "exe" ]; then
	  continue
        fi

      fi

    elif [ "$cmd" == "remove" ]; then

      if [ -f ${CVS_DIR}${file} ]; then
	if [ "$type" == "info" ]; then
	  echo "${CVS_DIR}${file}"
        elif [ "$type" == "exe" ]; then
	  if [ -f ${CVS_DIR}${file} ]; then
	    echo "cvs remove -f ${CVS_DIR}${file}"
          fi
        fi

      else

	if [ "$type" == "info" ]; then
	  MSG="${MSG}${CVS_DIR}${file}\n"
        elif [ "$type" == "exe" ]; then
	  continue
        fi

      fi

    fi
  done < $file_list

  if [ "$type" == "info" -a ! -z "$MSG" ]; then
    echo "Not found:"
    printf $MSG
  fi

}

# function: add
add() {

  echo "-------------------------------------"
  printf "work_dir:%s\n" $WORD_DIR
  printf "cvs_dir:%s\n" $CVS_DIR
  printf "files to be added:\n"
  exe_cmd add info $ADD_FILE_LIST
  echo "-------------------------------------"
  read -p "Do u want to add these files to cvs[Y|N]?"
  case $REPLY in
    y|Y)
      exe_cmd add exe $ADD_FILE_LIST ;;
    n|N)
      exit ;;
    *)
      echo "please input Y|N."
      exit ;;
  esac
}

# function: remove
remove() {

  echo "-------------------------------------"
  printf "cvs_dir:%s\n" $CVS_DIR
  printf "files to be removed:\n"
  exe_cmd remove info $REMOVE_FILE_LIST
  echo "-------------------------------------"
  read -p "Do u want to remove these files from cvs[Y|N]?"
  case $REPLY in
    y|Y)
      exe_cmd remove exe $REMOVE_FILE_LIST ;;
    n|N)
      exit ;;
    *)
      echo "please input Y|N."
      exit ;;
  esac
}

main
