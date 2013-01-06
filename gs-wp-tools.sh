#!/bin/bash
# This is a work in progress! BACK EVERYTHING UP!
# Useful to define the site ID for absolute paths
siteid=`pwd | awk -F "/" '{print $3}'`
#Build functions for later
#The WPDBCHECK function checks the connection to the WordPress database 
function WPDBCHECK {
    #set up temporary variables to work with MySQL
    echo "setting up variables"
    echo "setting up dbhost"
    dbhost="internal-db.s$siteid.gridserver.com"
    echo "Database host is $dbhost"
    echo "setting up dbuser"
    dbuser=`cat $working_wp/wp-config.php|grep DB_USER |awk -F "'" '{print $4}'`
    echo "Database user is $dbuser"
    echo "setting up dbpass"
    dbpass=`cat $working_wp/wp-config.php|grep DB_PASS |awk -F "'" '{print $4}'`
    echo "Database password is $dbpass"
    echo "setting up dbname"
    dbname=`cat $working_wp/wp-config.php|grep DB_NAME |awk -F "'" '{print $4}'`
    echo "Database name is $dbname"
    echo "setting up dbname_test"
    dbname_test=`mysql -h$dbhost -u$dbuser -p$dbpass -e "show databases;" |grep  $dbname`
    #now see if the database names match, or if it's even there
    echo "Testing the database connection"
    dbname_test=`mysql -h$dbhost -u$dbuser -p$dbpass -e "show databases;" |grep  $dbname`
    
    #now see if the database names match, or if it's even there
    echo "Testing the database connection"
    if [ "$dbname_test" = "$dbname" ]; then
        echo 'The database name in the wp-config.php is valid and connection to database was successful.'
    else
        echo 'It looks like the database name in the wp.config.php is not valid'
    fi
break
}        
# The WPVERCHECK function just checks the WordPress version                
############# Currently not setting $wp__version properly ############
function WPVERCHECK {
    #set up $wp_version to be the version number and tell it to the user
    wp_version=`grep "wp_version=" $working_wp/wp-includes/version.php |awk -F"'" '{print $2}'`
    echo "The WordPress version for the installation at $working_wp is $wp_version"
    break
}
#Home menu function
function HOME_MENU {
wpinstall_list="$(find /home/$siteid/domains/ -type f -name wp-config.php | rev | cut -d"/" -f2- |rev) Done"
# Use echo  $wpinstall_list if a sanity check is needed
#$wpinstall_list now has all WordPress installations!
PS3='Pick one: '
#sets up the select prompt for a menu
until [ "$working_wp" == "Done" ]; do
    printf "%b" "\a\n\nWhich WordPress install do you want to work on?\n"
        select working_wp in $wpinstall_list; do
        
            if [ "$working_wp" = "Done" ]; then
                echo "Goodbye"
                break
            elif [ -n "$working_wp" ]; then
            
                working_wp="`echo $working_wp`/" #set up a proper path
                
                echo "Selected install path is $working_wp"
                #Let's do something with this!
                
                SUBMENU
                break
            else
                echo  "Invalid Selection"
            fi
        done  #end the selection
    done    #end the "until" statement
}
#The SUBMENU function creates the sub menu
function SUBMENU {
    echo "You are currently working with the WordPress installation at $working_wp"
    #set up prompt and the list to chose from
    OPS3=$PS3 #save the old prompt
    PS3='Choose action: '
    
    option_list="check database connection,check WordPress version,Done"
    OIFS=$IFS #save the current IFS (Internal Field Separator)
    IFS=',' #Create a new IFS for multi-word options! 
    
    #build the list and select an action
    until [ "$action_select" == "Done" ]; do
    printf "%b" "\a\n\nWhat would you like to do with this WordPress install?\n"
    
    select action_select in $option_list; do
    
        # This "should" return you to the home menu to select another WordPress install
        if [ "$action_select" = "Done" ]; then
            echo "Returning to Main Menu"
            IFS=$OIFS
            PS3=$OPS3
            break
        elif [ "$action_select" = "check database connection" ]; then
            WPDBCHECK
        elif [ "$action_select" = "check WordPress version" ]; then
            
            WPVERCHECK
        
        else echo "Invalid Selection"
            
        fi
    done
done
}
#Right, now lets actually execute some of those functions!
HOME_MENU
