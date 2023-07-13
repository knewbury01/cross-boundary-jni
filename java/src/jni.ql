/**
 * @name JNI Java client
 * @description Analysis of a 
 * @kind problem
 * @problem.severity warning
 * @id java/cross-boundary-jni-lib-centric
 */

 import java
 import semmle.code.java.dataflow.TaintTracking
 import external.ExternalArtifact

/**
 * The data class representing a flow summary
 * with the following layout:
 * 
 * `libname, source, source_connected, sink, sink_connected, source_identifier, source_index`
 */
class FlowSummary extends ExternalData {
    FlowSummary() { this.getDataPath().matches("%-flow-summary.csv") }

    string getLibName() { result = this.getField(0) }
    string getSource() { result = this.getField(1) }

    int getSourceConnected() { result = this.getFieldAsInt(2) }

    string getSink() { result = this.getField(3) }

    int getSinkConnected() { result = this.getFieldAsInt(4) }

    string getSourceIdentifier() { result = this.getField(5) }

    //replace the index with the info + 2 for the position
    //cpp jni signatures: function(JNIEnv *env, jobject obj, arg1...)
    int getSourceIndex() { result = this.getFieldAsInt(6)-2 }

    string getSinkIdentifier() { result = this.getField(7) }

    int getSinkIndex() { result = this.getFieldAsInt(8)-2 }
    
}

class JavaLogSink extends  MethodAccess {
    JavaLogSink(){
        this.getMethod().hasQualifiedName("android.util", "Log", ["d", "e", "i", "v", "w", "wtf"])
    }
}

class JNISourceMethod extends Method {
    FlowSummary f;
    JNISourceMethod(){
        this.hasModifier("native")
        and 
        exists(string package, string type, string name | 
            this.hasQualifiedName(package, type, name)
            //match mangled
            and 
            if exists(Method overload |
                //if overloaded mangling includes type signature
                this.getName() = overload.getName()
                and this.getDeclaringType() = overload.getDeclaringType()
                and not this = overload
            ) 
            then
            f.getSinkIdentifier() = "Java_"+package.replaceAll("_", "_1").replaceAll(";", "_2").replaceAll("[", "_3").replaceAll(".", "_")+"_"+type+"_"+name+"__"+this.getMethodDescriptor().replaceAll("_", "_1").replaceAll(";", "_2").replaceAll("[", "_3").replaceAll("/", "_").regexpReplaceAll(".*\\(", "").regexpReplaceAll("\\).*", "")
            else 
            f.getSinkIdentifier() = "Java_"+package.replaceAll("_", "_1").replaceAll(";", "_2").replaceAll("[", "_3").replaceAll(".", "_")+"_"+type+"_"+name
        )
    }
    FlowSummary getFlowSummary(){
        result = f
    }

}

 class JNISinkMethod extends Method {
    FlowSummary f;
    JNISinkMethod(){
        this.hasModifier("native")
        and 
        exists(string package, string type, string name | 
            this.hasQualifiedName(package, type, name)
            //match mangled
            and 
            if exists(Method overload |
                //if overloaded mangling includes type signature
                this.getName() = overload.getName()
                and this.getDeclaringType() = overload.getDeclaringType()
                and not this = overload
            ) 
            then
            f.getSourceIdentifier() = "Java_"+package.replaceAll("_", "_1").replaceAll(";", "_2").replaceAll("[", "_3").replaceAll(".", "_")+"_"+type+"_"+name+"__"+this.getMethodDescriptor().replaceAll("_", "_1").replaceAll(";", "_2").replaceAll("[", "_3").replaceAll("/", "_").regexpReplaceAll(".*\\(", "").regexpReplaceAll("\\).*", "")
            else 
            f.getSourceIdentifier() = "Java_"+package.replaceAll("_", "_1").replaceAll(";", "_2").replaceAll("[", "_3").replaceAll(".", "_")+"_"+type+"_"+name
        )
    }
    FlowSummary getFlowSummary(){
        result = f
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
        //Java source
        exists(Source s | s = node.asExpr())
        //todo add sink_connected handling
        or
        exists(MethodAccess a, JNISourceMethod m | 
            a.getMethod() = m 
            //sinkConnected = 1 : return value, sinkConnected = 2 : arg value from a heap set
            and 
            ((m.getFlowSummary().getSinkConnected() = 1 
            and a = node.asExpr())
            or
            (m.getFlowSummary().getSinkConnected() = 2
            and a.getArgument(m.getFlowSummary().getSinkIndex()) = node.asExpr()))
            //check that this sink occurs in a method of a class that has loaded the same lib that we are matching a summary against
            and exists(MethodAccess load |
                load.getMethod().hasQualifiedName("java.lang", "System", "loadLibrary")
                and load.getEnclosingCallable().getDeclaringType() = node.getEnclosingCallable().getDeclaringType()
                and load.getArgument(0).toString().replaceAll("\"", "") = m.getFlowSummary().getLibName() )
             )
    }
    
    override predicate isSink(DataFlow::Node node) {
        //sink in lib, source in Java (ie source_connected)
        exists(MethodAccess a, JNISinkMethod m | 
            a.getMethod() = m 
            and m.getFlowSummary().getSourceConnected() = 1 
            and a.getArgument(m.getFlowSummary().getSourceIndex()) = node.asExpr()
            //check that this sink occurs in a method of a class that has loaded the same lib that we are matching a summary against
            and exists(MethodAccess load |
                load.getMethod().hasQualifiedName("java.lang", "System", "loadLibrary")
                and load.getEnclosingCallable().getDeclaringType() = node.getEnclosingCallable().getDeclaringType()
                and load.getArgument(0).toString().replaceAll("\"", "") = m.getFlowSummary().getLibName() )
             )
        or 
        //currently not scoped to when the flow summary says match to a specific flow from cpp
        //ie will match java to java currently
        exists(JavaLogSink javalog | 
            //first level field access on an arg
            javalog.getArgument(1).(FieldAccess).getQualifier() = node.asExpr()
            or
            javalog.getArgument(1) = node.asExpr()
        )

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

from FrontEndConfig f, DataFlow::Node source, DataFlow::Node sink
where f.hasFlow(source, sink)
select sink, "Flow"