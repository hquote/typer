#!/bin/bash
# created by vlad Чт окт 19 11:21:24 MSK 2017
version="1.65"
progname="$(basename ${0})"

######################################
# start initialization
#####################################
declare -i total_elapsed=
declare -i total_typed_chars=0
declare -a letter_parts=()          #global array fo internal generating lines
SECONDS=0                           #special BASH vaiable to track elapsed time
configfile="${HOME}/.typerc"        # set here config values which differ from DEFAULT PARAMS
logfile="${HOME}/.statistics_type.txt" #log statistics
error_file="${HOME}/.errors_type.txt" #typed errors for possible training



declare -a words_array=( )      # array containing parsed from files lines for typing



#######################################
#   DEFAULT PARAMS used in $configfile
#######################################
TY_DETECT_TOUCHPAD=                 #if blank Touchpad will not be enabled/disabled
TY_DEFAULT_LANG="ru"                #which letter_parts to use
TY_ADD_ERRORS_TO_ARRAY=yes          #reads $error_file and adds them to @letter_parts      
TY_NUMBER_LINES_TO_ADD=0            #how many lines to pass after main line
TY_ASTERISKS_MODE=0                 # ***** instead of plain text

en_letter_parts=(
al an ar as at ax ba bl bq ca ci che cns com cp de ds dis ed en er esh est fin fo gh git gq ha he hg ic ie int io is it kin la le li 
ls man me mex my mv nd ne nes ng nt omp on or per pi pro qu ra re ri rm rq rs rt sd sh si sta ste str ta ter tio tr ts un wa yu
soft mixed -- branch checkout remote log reset clean clone commit hard merge tag status amend revert clone ls-files tree
push pull rebase origin master stash clear bash find ls-tree cat-file git join ou rt vc vb re yu uy

)

ru_letter_parts=(            
'на' 'по' 'но' 'ко' 'ка' 'ал' 'не' 'ен' 'он' 'ла' 'до' 'ни' 'ел' 'ле' 'ил' 'ло' 'ки' 'го' 'де' 'ли' 'ом' 'од' 'мо' 'ан' 'ой' 'ак' 'об' 
'ин' 'ме' 'ол' 'ми' 'ма' 'да' 'ем' 'ая' 'им' 'ам' 'ог' 'ег' 'бе' 'ок' 'ей'  'ик' 'пе' 'ад' 'ие' 'па' 'ня' 'бо' 
'она' 'ала' 'под' 'как'  'его' 'ила' 'кол' 'ого' 'ени' 'ной' 'али' 'кам' 'или' 
)

#################################################
#       Run external scripts here
. functions_lib.sh || echo 'Function import FAILED' >&2
# Overide default values
[[ -f  "${configfile}" ]] &&  . "${configfile}" 
#################################################
number_of_typed_lines=1                 #for statistical purposes only
initialize_letter_parts                 # initialize  array fo generating lines
read_from_cmd_line "$@" 				# initialize the array of lines from command line files
trap trap_SIGINT SIGINT 				#trap Ctrl-C
best_time=1000 					    	#best result for one line
show_banner

prompt=">" 						       
add_letters_from < "$error_file"		#add letters from error_file for better learning!

#############################################################################
#                   Infinite loop showing random lines
#
#############################################################################
while  true  ; 
do
    item="$( getline )"     #original text line shown to user    
    touchpad disable       #  disable in this while loop because Ctr-C enables it
    turn_on_off_randomly_asterisks_mode
    #DISPLAY INITIAL TEXT with colored comments ###
    echo -e "${Green}${prompt}$(colorify_comments "$item" )${NC}" 
    echo -n ${prompt}
    time_stamp=$SECONDS
    get_user_input_text                          # gets  $user_text

    elapsed=$(($SECONDS - $time_stamp))         # measure elapsed time

    [[ ${user_text} =~ [Qq]uit ]] &&  break 
    [[ "$user_text" =~ MENU ]] && { settings_dialog  ; continue ; }

    #compare to initial item without comments 
    lex_diff "${item%%#*} " "$user_text"
   if  (( error_counter == 0 ))  ; then
        echo GOOD!
   else
        colored_compare_strings "${item%%#*}"   "$user_text"
    fi        
    
    #TRACK statistics only when there are no errors!
    total_elapsed=$(($total_elapsed + $elapsed))
    total_typed_chars=$(($total_typed_chars + ${#user_text})) 

    print_elapsed   
  
done

#######################################################
##########          EXIT HERE       ###################
#######################################################

touchpad enable                                     # enable back!
show_statistics ${total_typed_chars} ${total_elapsed} ${best_time}  #for the session

log_result ${total_typed_chars} ${total_elapsed}    # log statistics for the session
h_print_header1
tail <<< "$( show_daily_statistics )"               #last 10 records
exit 0
