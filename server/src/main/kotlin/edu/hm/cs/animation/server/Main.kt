package edu.hm.cs.animation.server

import com.xenomachina.argparser.ArgParser
import edu.hm.cs.animation.server.security.AuthController
import edu.hm.cs.animation.server.security.SecurityConfigFactory
import edu.hm.cs.animation.server.util.cmdargs.CMDLineArgumentParser
import io.javalin.Javalin
import io.javalin.apibuilder.ApiBuilder.*
import org.pac4j.javalin.SecurityHandler

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
        val securityConfig = SecurityConfigFactory(jwtSalt).build()

        val app = Javalin.create().apply {
            port(port)
            enableStaticFiles(STATIC_FILES_FOLDER)

            if (debug) {
                enableCorsForAllOrigins()
            }
        }.start()

        app.routes {
            before("/api/hello", SecurityHandler(securityConfig, "HeaderClient"))
            get("/api/hello") { ctx -> ctx.result("Hello World") }

            before(AuthController.PATH, SecurityHandler(securityConfig, "DirectBasicAuthClient"))
            get(AuthController.PATH) { ctx -> AuthController.generateJWT(ctx, jwtSalt) }
        }
    }
}
