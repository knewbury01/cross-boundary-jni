############
#
# usage:
#       ./crossBoundaryJNI.sh <app-name> <path-to-app-to-build>
#
############

#add build Java db portion
#echo "Building Java database for: $1"
#./buildALL.sh

#change to app name?
echo "Running Java analysis on: $1"
./runJavaPortion.sh $1

cp flows/${1}-flow-summary.csv $2

#run cpp build portion
echo "Building cpp database for: $1"
./buildcppDB.sh $1

#run cpp analyze portion
echo "Running cpp analysis on: $1"
./runCPPPortion.sh $1

#todo think of a better way?
#currently to prevent collisions on this files usage
rm ${2}/${1}-flow-summary.csv

#todo find out if these should be combined for a nice overall source (java) to sink (cpp) view?
