########
# runs the first portion of the cross boundary setup
# ie runs a java query
# outputs a csv that contains the flow summary for that analysis
#
# usage:
#       ./runJavaPortion.sh <app-name>
#
###########

database=../databases/JAVA/$1

codeql query run --database=$database --output=flows/${1}-flow-summary.bqrs -- java/src/java-jni.ql

if [ -f flows/${1}-flow-summary.bqrs ]; then
    echo "------------- query execution complete -------------"
    codeql bqrs decode --format=csv flows/${1}-flow-summary.bqrs --output=flows/${1}-flow-summary.csv
    rm flows/${1}-flow-summary.bqrs
else
   echo "codeql query run did not complete successfully."
fi
