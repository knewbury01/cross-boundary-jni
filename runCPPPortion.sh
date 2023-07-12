########
# runs the library portion of the cross boundary setup
# ie runs a cpp query
# outputs a csv that contains the flow summary for that analysis
#
# usage:
#       ./runCPPPortion.sh <app-name>
#
###########

database=../databases/CPP/$1

codeql query run --database=$database --output=flows/${1}-flow-summary.bqrs -- cpp/src/jni.ql

if [ -f flows/${1}-flow-summary.bqrs ]; then
    echo "------------- query execution complete -------------"
    codeql bqrs decode --format=csv flows/${1}-flow-summary.bqrs --output=flows/${1}-flow-summary.csv
    rm flows/${1}-flow-summary.bqrs
else
   echo "codeql query run did not complete successfully."
fi
