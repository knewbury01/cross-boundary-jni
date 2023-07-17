############
#
# usage:
#       ./crossBoundaryJNI.sh <app-name> <path-to-app-to-build>
#
############

#add build cpp db portion
#only perform if these are not already created
#echo "Building cpp database for: $1"
#./buildALL.sh

#change to app name?
echo "Running cpp analysis on: $1"
./runCPPPortion.sh $1

if [ -f flows/${1}-flow-summary.csv ]; then
    cp flows/${1}-flow-summary.csv $2

    #run cpp build portion
    echo "Building Java database for: $1"
    ./buildJavaDB.sh $1 $2

    #run cpp analyze portion
    echo "Running java analysis on: $1"
    ./runJavaPortion.sh $1

    #todo think of a better way?
    #currently to prevent collisions on this files usage
    rm ${2}/${1}-flow-summary.csv

else
    echo "---------------------------"
    echo "Could not run cpp analysis."
    echo "---------------------------"
fi
