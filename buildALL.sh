#############
# builds a CodeQL cpp DB per submodule in the benchmark
# which represents the JNI library for each submodule
# (18/22) databases to create - omits CodeQL irrelevant submodules
#
# to be run from the NativeFlowBench directory
# (ie move this into NativeFlowBench)
#
# usage:
#       ./buildALL.sh
#
#############


declare -a arr=( 
"native_complexdata"
"native_complexdata_stringop"
"native_dynamic_register_multiple"
"native_heap_modify"
"native_leak"
"native_leak_array"
"native_leak_dynamic_register"
"native_method_overloading"
"native_multiple_interactions"
"native_multiple_libraries"
"native_noleak"
"native_noleak_array"
"native_nosource"
"native_set_field_from_arg"
"native_set_field_from_arg_field"
"native_set_field_from_native"
"native_source"
"native_source_clean"
)

for i in "${arr[@]}"
	 do
	     echo "BUILDING $i--------"
	     ./gradlew ${i}:clean
	     codeql database create --overwrite --language=cpp ../../databases/CPP/$i --command="./gradlew ${i}:build"
	     echo "--------"
done

