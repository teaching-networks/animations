import io.javalin.Javalin
import io.javalin.apibuilder.ApiBuilder.*

fun main(args: Array<String>) {

    val port: Int = args[0].toInt();
    val isDebug: Boolean = args[1].toBoolean();

    val app = Javalin.create().apply {
        port(port)
        enableStaticFiles("/public")

        if (isDebug) {
            enableCorsForAllOrigins()
        }
    }.start()
    
    app.routes {
        get("/api") { ctx -> ctx.result("Hello World") }
    }

}
