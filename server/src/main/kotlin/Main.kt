import io.javalin.Javalin

fun main(args: Array<String>) {

    val port: Int = args[0].toInt();
    val isDebug: Boolean = args[1].toBoolean();

    val app: Javalin = Javalin.create().apply {
        port(port)
        enableStaticFiles("/public")

        if (isDebug) {
            enableCorsForAllOrigins()
        }
    }.start()

    app.get("/api") { ctx -> ctx.result("Hello World") }

}
