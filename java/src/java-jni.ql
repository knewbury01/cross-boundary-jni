/**
 * @name Custom sources to any JNI
 * @description Data transmitted across the JNI is tracked
 * @ kind path-problem
 * @problem.severity warning
 * @id java/cross-boundary-jni
 */

import java
import semmle.code.java.dataflow.TaintTracking

class JNIMethod extends Method {
    JNIMethod(){
        this.hasModifier("native")
    }
}

class JNISink extends MethodAccess {
    JNISink(){
        this.getMethod() instanceof JNIMethod
    }
}

class Source extends MethodAccess {
    Source(){
    this.getMethod().hasQualifiedName("android.telephony", "TelephonyManager", "getDeviceId")
    }
}

class FrontEndConfig extends TaintTracking::Configuration {
    FrontEndConfig() { this = "FrontEndConfig" }
    
    override predicate isSource(DataFlow::Node node) {
        exists(Source s | s = node.asExpr())
    }
    
    override predicate isSink(DataFlow::Node node) {
        exists(JNISink a | a.getAnArgument() = node.asExpr())
    }

  //allows for fields to taint full object
  //required for flow in native_complexdata
  override predicate allowImplicitRead(DataFlow::Node n, DataFlow::ContentSet c) {
    super.allowImplicitRead(n, c)
    or
    c instanceof DataFlow::FieldContent and
    this.isSink(n)
  }
}

from FrontEndConfig f, DataFlow::Node source, DataFlow::Node sink, string sinkMethodName, string libname, int index, string classname, string packagename
where f.hasFlow(source, sink)
and
//get the name of the loaded jni lib 
//possibly move this into a predicate
exists(MethodAccess a|
    a.getMethod().hasQualifiedName("java.lang", "System", "loadLibrary")
    and a.getEnclosingCallable().getDeclaringType() = sink.getEnclosingCallable().getDeclaringType()
    and a.getArgument(0).toString().replaceAll("\"", "") = libname )
and 
exists(JNISink sinkMethod | sink.asExpr() = sinkMethod.getArgument(index) and sinkMethodName = sinkMethod.getMethod().getName().toString()
and classname = sinkMethod.getMethod().getDeclaringType().toString()
and packagename = sinkMethod.getMethod().getDeclaringType().getPackage().toString())
//source, sink, sinkMethodName, library name, packagename, index of arg
//todo add the package name (and or the mangled cpp lib resulting name)
select source, sink, sinkMethodName , libname, index, classname, packagename
