#############
#
# Builds a CodeQL database in steps
# to include a csv file containing flow summaries
#
# usage:
#      ./buildcppDB.sh <app-name> <path-to-app-to-build>
#
#############

#move to app dir
cd $2
echo $pwd

database=../../databases/CPP/$1

./gradlew $1:clean

#currently the source root is set for a submodule in the specific app
codeql database init -s . --overwrite --language=cpp $database

codeql database index-files -l csv --include-extension .csv $database

#build command could be abstracted into any modular build script: ./build.sh
command='./gradlew '"$1"':build'
echo "Building with $command"
codeql database trace-command --no-db-cluster -- $database $command

codeql database finalize $database
