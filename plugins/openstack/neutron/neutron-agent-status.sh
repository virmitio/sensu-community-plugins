#!/bin/bash

use_help ()
{
    echo "Usage: $0 [OPTIONS]"
    echo " -h                  Display this help"
    echo " -A <Auth URL>       OpenStack Auth URL"
    echo " -T <Tenant Name>    OpenStack Tenant to operate on/in"
    echo " -U <username>"
    echo " -P <password>"
    echo " -S <shell script>   Shell script to roun/source which will provide auth details"
    echo " -Z <Agent Type>           Availability Zone to check.  If not present, will check all zones."
}

while getopts 'A:T:U:P:S:Z:h' OPTION
do
    case $OPTION in
        A)  export OS_AUTH_URL=$OPTARG;;
        T)  export OS_TENANT_NAME=$OPTARG;;
        U)  export OS_USERNAME=$OPTARG;;
        P)  export OS_PASSWORD=$OPTARG;;
        S)  source $OPTARG;;
        Z)  export NEUTRON_AGENT=$OPTARG;;
        h|?)  use_help
            exit 0;;
        *)  use_help
            exit 1;;
    esac
done

if [[ $NEUTRON_AGENT ]]
then
    export AGENT_CMD="awk -F ' *\\| *' \$3==\"$NEUTRON_AGENT\"{print}"
else 
    export AGENT_CMD="cat"
fi

neutron agent-list | $AGENT_CMD | awk -F ' *\\| *' -v RET_OK=0 -v RET_WARNING=1 -v RET_CRITICAL=2 -v RET_UNKNOWN=3 '
    BEGIN{enabled_count=0;retval=RET_OK}
    $6=="True"{enabled_count++;if ($5!=":-)") {print $4, "...", $3, "\"" $5 "\""; retval=RET_CRITICAL}}
    END{if (enabled_count<=0) {retval=RET_WARNING}; exit retval}'
