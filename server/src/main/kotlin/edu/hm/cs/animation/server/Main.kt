package edu.hm.cs.animation.server

import com.xenomachina.argparser.ArgParser
import edu.hm.cs.animation.server.security.AuthController
import edu.hm.cs.animation.server.util.cmdargs.CMDLineArgumentParser
import io.javalin.Javalin
import io.javalin.apibuilder.ApiBuilder.*

/**
 * Folder where static files (e. g. the built web application with index.html, etc.) are).
 */
const val STATIC_FILES_FOLDER = "/public"

/**
 * Entry point for the server.
 *
 * @see CMDLineArgumentParser for available command line options
 */
fun main(args: Array<String>) {
    ArgParser(args).parseInto(::CMDLineArgumentParser).run {
        val app = Javalin.create().apply {
            port(port)
            enableStaticFiles(STATIC_FILES_FOLDER)

            if (debug) {
                enableCorsForAllOrigins()
            }
        }.start()

        app.routes {
            get("/api") { ctx -> ctx.result("Hello World") }

            post(AuthController.PATH, AuthController::authenticate)
        }
    }
}
