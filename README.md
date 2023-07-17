# Cross Boundary 

This work presents a systematic methodology to combine CodeQL analysis results for a Java/Android application that uses JNI.

The purpose of the tool is to create an interlanguage analysis that depicts the full dataflow from the cpp and Java components of the JNI application.

The mechanism that this work uses to achieve that is post analysis combination of results via flow summaries. A flow summary (in `csv` format) describes the sources and sinks of the cpp/library component of the application. 

## Flow summary

A flow summary is a description of the dataflow location detected in one analysis that is intended to be consumed in another analysis to create a big picture dataflow view.

The flow summary format that this work uses is csv with the following properties:

`("libname","col1","source_connected","sink","sink_connected","source_identifier","source_index","sink_identifier","sink_index")`

* libname - the name of the library (ie the name of the `cpp` file)
* source_type - the type of the source from the library (currently one of ("JNIFunctionParameterSource", "InterfacePointerSource"))
* source_connected - values (0,1) - denotes that the data flows into the `cpp` library
* sink - the dataflow node by which data flows out of the `cpp` library
* sink_connected - values (0,1, 2)
* source_identifier - denotes function of which data flows into the `cpp` library
* source_index - denotes argument index of which data flows into the `cpp` library
* sink_identifier - denotes function of which data flows out of the `cpp` library
* sink_index - denotes argument index of which data flows out of the `cpp` library

### Flow summary additional details

The mangling of the flow summary information into a cpp method name follows the mangling schema defined in the [JNI spec](https://docs.oracle.com/javase/8/docs/technotes/guides/jni/spec/design.html)

The `crossBoundary.sh` script relies on the naming of the flow summary file to be `*-flow-summary.csv`. This is an arbitrary implementation detail.

## Experimental evaluation

[Benchmark](https://github.com/knewbury01/NativeFlowBench) - consisting of 18 relevant submodules.

Results in `benchmark-evaluation`:
  * `flows` contains the flow summaries for each submodule
  * `results` contains the `sarif` files that have been generated from the Java analysis phase

### Replication

Can be run via:
`./runall.sh` <path-to-benchmark-directory>

Assumes the following overall directory structure present and that CodeQL CLI 2.13.3 is on `$PATH`.

```
~/crossBoundaryRoot/
├───databases
│   └─JAVA/
│   └─CPP/
├───repos
│   └─NativeFlowBench
│     └───buildALL.sh
├───crossBoundary
│   ├───flows/
│   └───results/
│   └───runall.sh
```

#### Misc trouble shooting

The `crossBoundary.sh` script **does not** check for the presence of a CodeQL DB lock `db-cpp/default/cache/.lock` that gets generated when running queries in the VSCode editor. If the process fails for a certain submodule, check if this lock prevented subsequent steps in the process from executing.

## Expansion notes

The implementation currently does not consider the following:
  * the version of a particular cpp library, as there is no standard specification in JNI for separately versioning the Java and cpp components

The implementation currently generates an alert that only contains the final sink of the dataflow path in the Java component of the application.

## Tooling

This project was developed against CodeQL version 2.13.3.