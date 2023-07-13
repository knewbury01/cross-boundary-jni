# Cross Boundary 

## Flow summary

A flow summary is a description of the dataflow location detected in one analysis that is intended to be consumed in another analysis to create a large dataflow view.

The flow summary format that this work uses is csv with the following properties:

()

The mangling of the flow summary information into a cpp method name follows the mangling schema defined in the [JNI spec](https://docs.oracle.com/javase/8/docs/technotes/guides/jni/spec/design.html)

The crossBoundary.sh script relies on the naming of the flow summary file to be `*-flow-summary.csv`. This is an arbitrary implementation detail.

## Expansion notes

The implementation currently does not consider the following:
  * overloaded native methods. to do so, an addition, of full method signature, to the flow summary would be required.
  * the version of a particular cpp library, as there is no standard specification in JNI for separately versioning the Java and cpp components

## Tooling

This project was developed against CodeQL version 2.13.3.