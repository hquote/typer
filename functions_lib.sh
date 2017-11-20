#!/bin/bash

#*********************************************************************
#           CONSOLE COLOR CODES
#*********************************************************************

# Reset
NC='\033[0m' # Text Reset NO COLOR

# Regular Colors
Black='\033[0;30m' # Black
Red='\033[0;31m' # Red
Green='\033[0;32m' # Green
Yellow='\033[0;33m' # Yellow
Blue='\033[0;34m' # Blue
Purple='\033[0;35m' # Purple
Cyan='\033[0;36m' # Cyan
White='\033[0;37m' # White

# Bold
BBlack='\033[1;30m' # Black
BRed='\033[1;31m' # Red
BGreen='\033[1;32m' # Green
BYellow='\033[1;33m' # Yellow
BBlue='\033[1;34m' # Blue
BPurple='\033[1;35m' # Purple
BCyan='\033[1;36m' # Cyan
BWhite='\033[1;37m' # White

# Underline
UBlack='\033[4;30m' # Black
URed='\033[4;31m' # Red
UGreen='\033[4;32m' # Green
UYellow='\033[4;33m' # Yellow
UBlue='\033[4;34m' # Blue
UPurple='\033[4;35m' # Purple
UCyan='\033[4;36m' # Cyan
UWhite='\033[4;37m' # White

# Background
On_Black='\033[40m' # Black
On_Red='\033[41m' # Red
On_Green='\033[42m' # Green
On_Yellow='\033[43m' # Yellow
On_Blue='\033[44m' # Blue
On_Purple='\033[45m' # Purple
On_Cyan='\033[46m' # Cyan
On_White='\033[47m' # White

# High Intensity
IBlack='\033[0;90m' # Black
IRed='\033[0;91m' # Red
IGreen='\033[0;92m' # Green
IYellow='\033[0;93m' # Yellow
IBlue='\033[0;94m' # Blue
IPurple='\033[0;95m' # Purple
ICyan='\033[0;96m' # Cyan
IWhite='\033[0;97m' # White

# Bold High Intensity
BIBlack='\033[1;90m' # Black
BIRed='\033[1;91m' # Red
BIGreen='\033[1;92m' # Green
BIYellow='\033[1;93m' # Yellow
BIBlue='\033[1;94m' # Blue
BIPurple='\033[1;95m' # Purple
BICyan='\033[1;96m' # Cyan
BIWhite='\033[1;97m' # White

# High Intensity backgrounds
On_IBlack='\033[0;100m' # Black
On_IRed='\033[0;101m' # Red
On_IGreen='\033[0;102m' # Green
On_IYellow='\033[0;103m' # Yellow
On_IBlue='\033[0;104m' # Blue
On_IPurple='\033[0;105m' # Purple
On_ICyan='\033[0;106m' # Cyan
On_IWhite='\033[0;107m' # White

#*********************************************************************
#           FUNCTIONS
#*********************************************************************

function usage() {
#Prints the version of program, its description and usage    
    cat <<- _USAGE_
###########################################
Type Trainer version ${version}
This shell script reads text lines from files and prints them randomly
to stdout in infinite loop in order you could practice typing. If no files
are provided random lines of text will be generated.
###########################################

_USAGE_
    echo -e "${Green}USAGE${NC}: ${progname} [textfiles...] \n"
}

function show_banner() {
#Prints program name and version during small delay at startup
    clear    
    echo -e "${On_Yellow}Type Trainer version ${version} ${NC}\n"
    sleep 1
}
function process_input() {
#Reads lines from stdin and stores them in raw form in global @words_array     
    while read || [[ "$REPLY" ]]; do
        if [[ ${REPLY} ]]; then
            #words_array+=( "$(trim_spaces "$REPLY" )"  ) # too slow for big files
            words_array+=( "$REPLY"   )
        fi
    done
}

function generate_line() {
#Generates a line from random members of global array @letter_parts not longer than $1
    
    local length=${1:-"60"}         # параметром идет длина строки

    local count=${#letter_parts[@]} # we are sure it is > 0
    local str=${letter_parts[(( $RANDOM % $count ))]}
    while (( ${#str} < length )); do
        str="${str} ${letter_parts[(( $RANDOM % $count ))]}"     # get random element       
    done
    echo "${str} #"
}

function log_result() {
# logs $1 and $2 (number of chars and elapsed time for the session) into $logfile
    local chars=${1}
    local time=${2}
    # log only real results
    [[ ${chars} -gt 250 && ${time} -gt 120 ]] &&
    echo -e "$(date +%Y-%m-%d)\t$chars\t$time" >>"$logfile"


}

function touchpad() {
# Enables / disables touchpad $1=enable|disable

    # https://askubuntu.com/questions/65951/how-to-disable-the-touchpad
    [[ ! ${TY_DETECT_TOUCHPAD}  ]] && return    # global setting prevents any usage of touchpad

    id=$(xinput list) # list devices
    id=${id#*ouch[Pp]ad*id=} #отрезаем  слева один раз

    id=${id%%[*} # а справа по макимуму до последней оставшейся [

    [[ ${id} ]] || return #nothing found
    if [[ $1 == *enable* ]]; then
        xinput --enable ${id}
    elif [[ $1 == *disable* ]]; then
        xinput --disable ${id} #&& echo "Please note that Touchpad is being disabled"
    fi

}

function show_statistics() {
#Prints out the statistics summary for the current session    
    local total_typed_chars=${1}
    local total_elapsed=${2}
    local best_time=${3}

    local minutes=$(($total_elapsed / 60))
    ((total_elapsed > 0)) && session_speed=$(($total_typed_chars * 60 / ${total_elapsed}))
    (( best_time == 1000 )) && best_time="N/A"
    cat <<- _THIS_SESSION_STATISTICS_

#######################################
Session statistics
#######################################
You spent(min)  :   ${minutes}
You typed(chars):   ${total_typed_chars}
Resulting speed :   ${session_speed} chars per minute
Best time(sec)  :   ${best_time}

_THIS_SESSION_STATISTICS_
}

function trap_SIGINT() {
# is called as a trap for Ctrl-C and shows current session statistics
    show_statistics ${total_typed_chars} ${total_elapsed} ${best_time}
    touchpad enable # enable touchpad
    best_time=1000  #reset best time
    echo -e "type ${Blue}SET${NC} to get settings menu or press ${Green}Enter${NC} to continue..."

}

function add_letters_from() {
# adds letters from file(stdin) to @letter_parts array    

    [[ -z "${TY_ADD_ERRORS_TO_ARRAY}" ]] && return  #ignore if global var is not set

    while read; do
        [[ ${#REPLY} -gt 1 ]] && letter_parts+=( $REPLY )  #add to the end of array
       
    done;


}
function trim_error_file(){
# trim "$error_file"    
    if  [[ -f "$error_file" ]] ; then
        local temp=$(mktemp)
        cp "$error_file"     "$temp"
        sort "$temp" | uniq -c | sort -k 1n | tr -s ' ' | cut -f 3 -d " " | tail -n10 > "$error_file" 
        rm -f "$temp"
    fi

}

function read_from_cmd_line() {
 # READ lines FROM FILES IN COMMAND PROMPT into global words_array[@]
    if [[ $@ ]]; then

        ######################################
        echo "Reading from file(s)..."
        ######################################
        for file in $@; do
            process_input <"$file"
        done
        # now check if any lines were added
        local count=${#words_array[@]}

        if ((count > 0)); then
            echo -e "${Green}${count} lines read from :${NC} ${@}"

        else
            usage;
            exit 1 # params provided but nothing is read out !
        fi
    fi

}

function get_random_line() {
#gets a random line from words_array[@]
    local count=${#words_array[@]}      #number of elements in the global array
    local str=
    local index=
    if  (( count > 0 )) ; then

        for (( i=0 ; i < 20 ; i++ )) ; do
        # for sake of efficiency array may contain empty lines
        # thus we try to get a good one
             index=$(($RANDOM % $count))   #random index and array value
            str=$(trim_spaces "${words_array[$index]}" )
            [[ "$str" ]] &&   break 
         done
    fi
    echo "${str}" 
}

function trim_spaces(){
# remove leading and trailing spaces from $1  
#  alternative echo "$1" | xargs
# https://stackoverflow.com/questions/369758/how-to-trim-whitespace-from-a-bash-variable

    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

function colorify_comments(){
# Insert a color code into the line after first comment #
	local str="$*"
	local left="${str%%#*}"
	#[[ "$left" == "$str" ]] && echo "$str" && return	#str doesn't contain #
	
	echo "${left}${Yellow}${str##"${left}"}${NC}"

}

function h_format_print(){
#help foo for printing from show_daily_statistics()
# h_format_print $chTotal $secTotal $datePrev 

    local stars=$(( $1 / 1000 ))               #count in thousands
    local speed=$(( $1 * 60 / $2 ))             # chars per minute
    local str_stars=                         #number of stars
    for ((i=0 ; i<stars ; i++ )) ; do str_stars=${str_stars}* ; done

    if (( stars > 15 )) ; then
        printf  "%s %5d %s%dk\n"  $3 ${speed} "${str_stars}"  ${stars}
    else 
        printf  "%s %5d %s\n"  $3 ${speed}  "${str_stars}"  
    fi
  
    

}

function h_print_header1(){
#help foo for printing header for daily statistics 

echo -e "${Yellow}#######################################${NC}"
printf "%-10s %5s %s\n"   "Date" "Speed" "Chars in thousands"
echo -e "${Yellow}#######################################${NC}"
}

function h_print_footer1(){
#h_print_footer1 $DAYS_COUNT $CHARS $SECS    
local hours=$(($3 / 3600))
local thousands=$(($2 /1000))
local speed=$(($2 * 60 / $3 ))
echo "During $1 days on record you spent ${hours} hours and typed ${thousands} thousand chars"
echo "at average ${speed} CPM"
}


function show_daily_statistics(){
# show daily statistics from $logfile

     [[ -f "${logfile}" ]] || return            #nothing to show!
     local  date=
     local nchars=0 
     local nsec=0

    local datePrev=
     local ncharsPrev=0 
     local nsecPrev=0

     local chTotal=0                    #daily total chars
     local secTotal=0                   #daily total time spent

     local DAYS_COUNT=0
     local SECS=0
     local CHARS=0

    while   IFS=$'\t' read date nchars nsec   ; do 
        [[ ! "$date" && ! "$nchars"  ]]  &&  continue            # ignore empty lines     
        SECS=$((SECS + nsec))
        CHARS=$((CHARS + nchars))
        if [[ "${date}" == "${datePrev}" ]] ; then
        # такой же день как и предыдущий, просто суммируем данные
            chTotal=$(( chTotal + $nchars))
            secTotal=$(( secTotal + $nsec))    
           
        else        #мы попали на новый день
            # поэтому нужно распечатать все накопленные данные             
             (( $secTotal != 0)) && h_format_print $chTotal $secTotal $datePrev 
             # а теперь установим текущие данные для обработки в следующем цикле
            datePrev=$date
            chTotal=$nchars
            secTotal=$nsec    

            DAYS_COUNT=$((DAYS_COUNT +1))       
        fi
    done < "${logfile}"

   (( $secTotal != 0)) && h_format_print $chTotal $secTotal $datePrev 
   h_print_footer1 $DAYS_COUNT $CHARS $SECS
}


function h_sort_stat_file(){
# Sorts statistics $logfile  by date
    [[ -f "${logfile}" ]] || return            #nothing to sort!
    local temp=$(mktemp)
    sort -t- --key=1n --key=2n --key=3n $logfile > $temp 
    cp $temp $logfile
    rm $temp
}

function h_join_daily_stat(){
#joins multiple daily records into a single record in $logfile

     [[ -f "${logfile}" ]] || return            #nothing to do!
     h_sort_stat_file                           #sort data first!
     local  date=
     local nchars=0 
     local nsec=0

    local datePrev=
     local ncharsPrev=0 
     local nsecPrev=0

     local chTotal=0                    #daily total chars
     local secTotal=0                   #daily total time spent

    while   IFS=$'\t' read date nchars nsec   ; do 
        [[ ! "$date" && ! "$nchars"  ]]  &&  continue            # ignore empty lines     
        if [[ "${date}" == "${datePrev}" ]] ; then
        # такой же день как и предыдущий, просто суммируем данные
            chTotal=$(( chTotal + $nchars))
            secTotal=$(( secTotal + $nsec))    
           
        else        #мы попали на новый день
            # поэтому нужно распечатать все накопленные данные             
             (( $secTotal != 0)) && echo -e "${datePrev}\t${chTotal}\t${secTotal}" 
             # а теперь установим текущие данные для обработки в следующем цикле
            datePrev=$date
            chTotal=$nchars
            secTotal=$nsec         
        fi
    done < "${logfile}" 

   (( $secTotal != 0)) && echo -e "${datePrev}\t${chTotal}\t${secTotal}"   
 
}


function compact_statistics(){
#compacts daily statistics in $logfile by converting multiple intraday records into a single DAILY one
    local temp=$(mktemp)                    #temp file where we write data
    h_join_daily_stat > $temp               #joins multiple daily records into a single
    cp $temp $logfile
    rm $temp 
}

function initialize_letter_parts(){                 
# initialize  @letter_parts by Russian or English sample arrays
    unset letter_parts

    case $TY_DEFAULT_LANG in
        [Rr][Uu] ) #russian                   
                letter_parts=(  ${ru_letter_parts[@]}  )     
                ;;
         * )  # english
                letter_parts=(  ${en_letter_parts[@]}  )     
                ;;
    esac
}

function settings_dialog(){
#general settings which user can call by SET command
    local bar='*************************************************************************'
    clear
    echo -e "${Yellow}${bar}${NC}"
    echo "You can configure the following settings for THIS SESSION only:"
    echo -e "${Yellow}${bar}${NC}"

    options=(
        "CONTINUE..."
        "Clear error history" 
         "Show error history"       
        "English" 
        "Russian" 
        "ASTERISKS toggle"
        "Touchpad enable"
      )

    select opt in "${options[@]}"
        do
            case $opt in
                "Clear error history")
                    #clear_existing_file "$error_file"
                    echo "Error history trimmed!"
                    trim_error_file
                    
                    initialize_letter_parts
                     #break
                    ;;
                Touchpad* )
                    TY_DETECT_TOUCHPAD=yes
                    touchpad disable
                    ;;
                "Show error history" )
                    show_error_file_content
                    ;;
                ASTERISKS* )
                    if (( TY_ASTERISKS_MODE == 0 )) ; then
                        TY_ASTERISKS_MODE=1
                        else 
                        TY_ASTERISKS_MODE=0
                    fi
                    echo "Asterisks mode changed to $TY_ASTERISKS_MODE"
                    break
                    ;;
                Eng* )
                     TY_DEFAULT_LANG="EN"  
                     initialize_letter_parts
                     break
                    ;;
                Rus* )
                    TY_DEFAULT_LANG="RU" 
                    initialize_letter_parts
                    break
                    ;;
                CONTINUE* )
                    break
                    ;;
                  *) 
                    echo -e "${Red}Invalid option${NC} Select a number!"
                    ;;
            esac
        done
    clear
}

function clear_existing_file(){
# clears the file  $1  
    local filename="$1"
    [[ -f "$filename" ]] && echo > "$filename" 
}

function show_error_file_content(){
#Content and word count of    ${error_file} 
    if [[ -f   "${error_file}" ]] ; then
        cat "${error_file}" | sort | tr "\n" " "
        echo
        wc -w "${error_file}" 
    fi
}

function nbackspace(){
# n times backspaces
    [[ $1 ]] && n=$1 || n=1
    for (( i=0 ; i<n ; i++ )) ; do echo -n $'\b \b' ; done

}

function remove_repeating_spaces_from(){
# removes repeating spaces from $1   
    local line=$1
    echo "$line" | tr -s [:blank:]
}
function turn_on_off_randomly_asterisks_mode(){
#Automatically turns on or off ASTERISKS mode each 10th line    
if  (( number_of_typed_lines % 10 == 0 )); then
    echo -e "${On_Yellow}*****Please train in ASTERISKS mode $NC\n"
    TY_PREVIOUS_MODE=${TY_ASTERISKS_MODE}
    #force asterisks mode!
    TY_ASTERISKS_MODE=1
else
    TY_ASTERISKS_MODE=${TY_PREVIOUS_MODE}   #switch back to user's selected mode
fi
  
}
function get_user_input_text(){
# interactively reads user input from keyboad
# and substitutes it with asterisks if TY_ASTERISKS_MODE != 0
# stores data in global $user_text
    number_of_typed_lines=$((number_of_typed_lines +1)) # statistical use
    user_text=          #clear clobal var
    local char=
    while IFS= read -rs -n1 char; do  
        local code="$( echo -n "$char" | od -An -tx1 | tr -d ' \011' )" # Hex Code of the users key press stripped SPACE and TAB
        case "$code" in
                ''|0a|0d|03)    # Finish on EOF, LineFeed, or Return ^C Interrupt
                            break ;;              
                08|7f)      # Backspace or Delete
                            if [ -n "$user_text" ]; then
                                user_text="$( echo "$user_text" | sed 's/.$//' )"
                                nbackspace
                            fi
                            ;;
                15)         # ^U or kill line
                            echo -n "$user_text" | tr -c '\010' '\010'  # backspace
                            echo -n "$user_text" | tr -c ' '    ' '     # clear stars
                            echo -n "$user_text" | tr -c '\010' '\010'  # backspace
                            user_text=''
                            ;;
                [01]?) ;;   # Ignore ALL other control characters
                
                20)         #space
                            user_text="$user_text$char"         
                            echo -n " "
                            ;;
                
                *)          # Record users keystroke
                            user_text="$user_text$char"   
                          if  (( TY_ASTERISKS_MODE == 0 )) ; then
                                echo -n "$char"
                          else
                                echo -n "*"        #TY_ASTERISKS_MODE enabled
                          fi
                            
                            ;;
        esac
    done </dev/tty
    nbackspace "${#user_text}"      #clears the current line of asterisks and prints original input
    #use this global var further

}

function colored_compare_words(){
#echoes a word marked by color the differencies in two words    
    local original="$1"
    local typed="$2"    
    colored=
    
        for (( i=0; i < ${#typed}; i++ )) ; do
        if [[ "${original:i:1}" != "${typed:i:1}" ]] ; 
        then       
                colored+="$Red${typed:i:1}$NC"
                echo "${original:i:1}${typed:i:1}" | grep -iE '[[:alpha:]]{2,}' >> "$error_file" 
                # grep to filter out bad errors
        else
                colored+="${typed:i:1}"
        fi
    done;

    echo  "$colored"
}

function get_diff_count_words(){
# returns number of errors (differencies between two words)    
    local original="$1"
    local typed="$2"    
    local errors=
    
    for (( i=0; i < ${#typed}; i++ )) ; do
         [[ "${original:i:1}" != "${typed:i:1}" ]] && errors=$(( errors +1))

    done;
    # now let's check the lengths of strings
    local l1=${#original}
    local l2=${#typed}
    local len_diff=$(( l1 - l2    ))
    (( len_diff < 0)) && len_diff=$(( -1 * len_diff  )) # assure it's positive
    errors=$((errors + len_diff ))
    echo  "$errors"
}
function colored_compare_strings(){
#echoes a colored line and sets global $error_counter       
       declare -a original=( $1  )   
       declare -a typed=( $2  )  #this one will be colored compared to original
        error_counter=0         #global var contains n of diffs

        local len1=${#original[@]}
        local len2=${#typed[@]}
        local min=$len1
       (( min > len2 )) && min=$len2
       
       local colored_result=
       
       for ((i=0 ; i < min ; i++)) ; do
            local str=$( colored_compare_words ${original[i]} ${typed[i]} )
            local n=$( get_diff_count_words ${original[i]} ${typed[i]} )
            error_counter=$((error_counter + n ))
            colored_result+="${str} "
       done;
      
        (( len1 > len2 )) && error_counter=$((error_counter +  len1 - len2 ))
        #(( len1 < len2 )) && error_counter=$((error_counter +  len2 - len1 ))

       echo -e "${colored_result}"
}

function getline(){
# get the line either from global array of lines from files or generate one on fly    
    local item=$(get_random_line)
    [[ ${item} ]] || item=$(generate_line 60 )
    echo "$item"
}

function print_elapsed(){
#Print $elapsed seconds for the last line user has just input
#   echo $error_counter
    if (( error_counter == 0    )) ; then  
        clear
        if  ((${elapsed} < ${best_time})) ; then # BEST TIME is achieved
            best_time=${elapsed}
            echo -e "${Yellow}*******************************${NC}"
            echo "$elapsed seconds!!!"
            echo -e "${Yellow}*******************************${NC}"

        else    
            echo "${elapsed} seconds..."            
        fi    
        echo
    else 
        echo -en "$Red"
        for (( i=0 ; i<error_counter ; i++ )) ; do echo -n "!" ; done
         echo -e "$NC \n" 
    fi 
}

function lex_diff(){
#returns the number of lexigraphical differencies between two lines
#empty line if equivalent
    error_counter="0"     #global var
    local line1="$1"
    local line2="$2"

    line1=$(echo "$line1" | tr -d '[:blank:]' )
    line2=$(echo "$line2" | tr -d '[:blank:]' )

    local max=${#line1}
    (( max < ${#line2}   )) && max=${#line2}

    for (( i=0 ; i < max ; i++ )) ; do
          [[ "${line1:i:1}" != "${line2:i:1}" ]] && error_counter=$(( error_counter + 1 ))
    done

    echo $error_counter
}
