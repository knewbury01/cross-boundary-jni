/**
 * @name JNI receives data
 * @description Data transmitted across the JNI is tracked
 * @kind problem
 * @problem.severity warning
 * @id cpp/cross-boundary-jni
 */


import cpp
import external.ExternalArtifact
import semmle.code.cpp.dataflow.new.TaintTracking


class JNIFunction extends Function {
    JNIFunction(){
        this.getAnAttribute() instanceof JNIExportAttribute
    }
}

/**
 * a `Macro` JNIEXPORT expands to this `Attribute`
 */
class JNIExportAttribute extends Attribute {
    JNIExportAttribute(){
        exists( Macro m|
            m.getName().matches("%JNIEXPORT%")
            and this.getLocation() = m.getAnInvocation().getLocation())
    }
}

/**
 * The data class representing a flow summary
 */
class FlowSummary extends ExternalData {
    FlowSummary() { this.getDataPath().matches("%-flow-summary.csv") }
    string getSource() { result = this.getField(0) }

    string getSink() { result = this.getField(1) }
    string getSinkMethodName() { result = this.getField(2) }
    string getLibName() { result = this.getField(3) }

    //JNI spec - first two parameters: JNIEnv *env, jobject obj
    int getSinkIndex() { result = this.getFieldAsInt(4)+2 }

    string getClassName() { result = this.getField(5) }

    string getPackageName() { result = this.getField(6) }

    string getFunctionNameMangled() { result = "Java_"+getPackageName().replaceAll("_", "_1").replaceAll(";", "_2").replaceAll("[", "_3").replaceAll(".", "_")+"_"+getClassName()+"_"+getSinkMethodName() }
  }

class BackEndConfig extends TaintTracking::Configuration {
    BackEndConfig() { this = "BackEndConfig" }
    
    override predicate isSource(DataFlow::Node node) {
        //replace the index with the info + 2 for the position
        //cpp jni signatures: function(JNIEnv *env, jobject obj, arg1...)
        exists(JNIFunction f, FlowSummary summary | f.getParameter( summary.getSinkIndex()) = node.asParameter()
        and f.getName() = summary.getFunctionNameMangled()
        and f.getFile().getBaseName() = summary.getLibName()+".cpp"
        )
    }
    
    override predicate isSink(DataFlow::Node node) {
        exists(FunctionCall c | c.getTarget().getName() = "__android_log_print"
        and c.getAnArgument() = node.asExpr())
    }

    override predicate isAdditionalTaintStep(DataFlow::Node node1, DataFlow::Node node2) { 
        //const char* GetStringUTFChars(jstring string, jboolean* isCopy)
        exists(FunctionCall f | f.getTarget().hasName("GetStringUTFChars") and
        node1.asExpr() = f.getArgument(0)
        and node2.asExpr() = f)
    }
}

////from BackEndConfig c , DataFlow::PathNode source, DataFlow::PathNode sink
from BackEndConfig c , DataFlow::Node source, DataFlow::Node sink
where c.hasFlow(source, sink)
select sink, "Flow detected."//, sink, "Leak"
