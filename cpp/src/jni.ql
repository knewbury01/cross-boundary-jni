/**
 * @name Flow summary cpp library
 * @description A summary of the library is generated
 * @ kind path-problem
 * @problem.severity warning
 * @id cpp/cross-boundary-jni-lib-centric
 */


import cpp
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

abstract class Sink extends DataFlow::Node {
}


abstract class Source extends DataFlow::Node {
}

/**
 * a `Parameter` of any `JNIFunction`
 */
class JNIFunctionParameterSource extends Source {
    JNIFunctionParameterSource(){
        exists(JNIFunction f| f.getParameter(_) = this.asParameter())
    }
}

/**
 * the return value of the Java `Method` 
 * `android.telephony.TelephonyManager.CallObjectMethod()`
 * accessed through the interface pointer
 */
class InterfacePointerSource extends Source {
    InterfacePointerSource(){
        //does not check if the qualifier type is JNIEnv, heurisitic could be improved if required
        exists(FunctionCall findClass, FunctionCall getMethod, FunctionCall sourceCall | 
            findClass.getTarget().hasName("FindClass")
        and findClass.getArgument(0).toString() = "android/telephony/TelephonyManager"
        and getMethod.getTarget().hasName("GetMethodID")
        and getMethod.getArgument(1).toString() = "getDeviceId"
        and sourceCall.getTarget().hasName("CallObjectMethod")
        and DataFlow::localFlow(DataFlow::exprNode(findClass), DataFlow::exprNode(getMethod.getArgument(0)))
        and DataFlow::localFlow(DataFlow::exprNode(getMethod), DataFlow::exprNode(sourceCall.getArgument(1)))
        and this.asExpr() = sourceCall
        )
    }
}

/**
 * the return value of any `JNIFunction`
 */
class JNIFunctionReturnSink extends Sink {
    JNIFunctionReturnSink(){
        exists(JNIFunction f, ReturnStmt r | r.getEnclosingFunction() = f
        and this.asExpr() = r.getExpr().getAChild*())
    }
}

/**
 * an `Argument` to a `FunctionCall` to a logging function in the cpp library
 */
class CppSpecificSink extends Sink {
    CppSpecificSink(){
        exists(FunctionCall c | c.getTarget().getName() = "__android_log_print"
        and c.getAnArgument() = this.asExpr())
    }
}

class ObjectHeapSink extends Sink {
    ObjectHeapSink(){
        exists(FunctionCall setField |
            setField.getTarget().hasName("SetObjectField")
            and this.asExpr() = setField.getArgument(0)
            )
    }
}

class BackEndConfig extends TaintTracking::Configuration {
    BackEndConfig() { this = "BackEndConfig" }
    
    override predicate isSource(DataFlow::Node node) {
        node instanceof Source
    }
    
    override predicate isSink(DataFlow::Node node) {
        node instanceof Sink
    }

    override predicate isAdditionalTaintStep(DataFlow::Node node1, DataFlow::Node node2) { 
        //const char* GetStringUTFChars(jstring string, jboolean* isCopy)
        exists(FunctionCall f | f.getTarget().hasName("GetStringUTFChars") and
        node1.asExpr() = f.getArgument(0)
        and node2.asExpr() = f)
        or
        //field insensitive - fields of objects set with the interface pointer taint the full object
        exists(FunctionCall setField |
            setField.getTarget().hasName("SetObjectField")
            and node1.asExpr() = setField.getArgument(2)
            and node2.asExpr() = setField.getArgument(0)
            )
        or
        //field getter
        exists(FunctionCall setField |
            setField.getTarget().hasName("GetObjectField")
            and node1.asExpr() = setField.getArgument(2)
            and node2.asExpr() = setField.getArgument(0)
            )
    }
}

from BackEndConfig c , DataFlow::Node source, DataFlow::Node sink, 
string libname, int source_connected, int sink_connected, 
string source_identifier, int source_index,
string sink_identifier
where c.hasFlow(source, sink)
and 
libname = sink.asExpr().getFile().getBaseName().replaceAll("."+sink.asExpr().getFile().getExtension(), "")
and
if source instanceof JNIFunctionParameterSource then 
(source_connected = 1 
    and source_identifier =  source.(JNIFunctionParameterSource).getFunction().getName() 
    and source_index = source.(JNIFunctionParameterSource).asParameter().getIndex())
//todo add the cpp typed source
else 
(source_connected = 0 and source_identifier = "" and source_index = -1)
and 
if sink instanceof JNIFunctionReturnSink then 
(sink_connected = 1 and sink_identifier = sink.(JNIFunctionReturnSink).getFunction().getName())
else (sink_connected = 0 and sink_identifier = "")
//libname, source, source_connected, sink, sink_connected, source_identifier, source_index
select libname, source, source_connected, sink, sink_connected, source_identifier, source_index, sink_identifier