#########
#
# usage:
#      ./runCPPPortion.sh <app-name>
##########

database=../databases/CPP/$1

codeql database analyze --rerun --format=sarif-latest --output=results/${1}-results.sarif -- $database cpp/src/back-end.ql
