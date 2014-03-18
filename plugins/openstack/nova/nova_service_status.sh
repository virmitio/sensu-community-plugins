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
    echo " -Z <Zone>           Availability Zone to check.  If not present, will check all zones."
}

while getopts 'A:T:U:P:S:Z:h' OPTION
do
    case $OPTION in
        A)  export OS_AUTH_URL=$OPTARG;;
        T)  export OS_TENANT_NAME=$OPTARG;;
        U)  export OS_USERNAME=$OPTARG;;
        P)  export OS_PASSWORD=$OPTARG;;
        S)  source $OPTARG;;
        Z)  export NOVA_ZONE=$OPTARG;;
        h|?)  use_help
            exit 0;;
        *)  use_help
            exit 1;;
    esac
done

if [[ $NOVA_ZONE ]]
then
    export ZONE_CMD="awk \$6==\"$NOVA_ZONE\"{print}"
else 
    export ZONE_CMD="cat"
fi

nova service-list | $ZONE_CMD | awk -v RET_OK=0 -v RET_WARNING=1 -v RET_CRITICAL=2 -v RET_UNKNOWN=3 '
    BEGIN{enabled_count=0;retval=RET_OK}
    $8=="enabled"{enabled_count++;if ($10=="down") {print $6, $4, "...", $2, "\"" $10 "\""; retval=RET_CRITICAL}}
    END{if (enabled_count<=0) {retval=RET_WARNING}; exit retval}'
