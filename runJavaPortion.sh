#########
#
# usage:
#      ./runJavaPortion.sh <app-name>
##########

database=../databases/JAVA/$1

codeql database analyze --rerun --format=sarif-latest --output=results/${1}-results.sarif -- $database java/src/jni.ql
