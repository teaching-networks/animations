import io.javalin.Javalin

fun main(args: Array<String>) {
    val app = Javalin.create().start(4242)
    app.get("/") { ctx -> ctx.result("Hello World") }
}
