package edu.hm.cs.animation.server

import com.xenomachina.argparser.ArgParser
import edu.hm.cs.animation.server.security.AuthController
import edu.hm.cs.animation.server.security.SecurityConfigFactory
import edu.hm.cs.animation.server.util.cmdargs.CMDLineArgumentParser
import io.javalin.Javalin
import io.javalin.apibuilder.ApiBuilder.*
import org.pac4j.javalin.SecurityHandler

/**
 * Entry point for the server.
 *
 * @see CMDLineArgumentParser for available command line options
 */
fun main(args: Array<String>) {
    ArgParser(args).parseInto(::CMDLineArgumentParser).run {
        val securityConfig = SecurityConfigFactory(jwtSalt).build()

        // Create the Javalin server
        val app = Javalin.create().apply {
            port(port)

            if (debug) {
                enableCorsForAllOrigins()
            } else {
                enableCorsForOrigin(corsEnabledOrigin)
            }
        }.start()

        // Here go all routes!
        app.routes {
            // The above 2 items are used to test the authentication using JSON Web Tokens
            before("/api/hello", SecurityHandler(securityConfig, "HeaderClient"))
            get("/api/hello") { ctx -> ctx.result("Hello World") }

            before(AuthController.PATH, SecurityHandler(securityConfig, "DirectBasicAuthClient"))
            get(AuthController.PATH) { ctx -> AuthController.generateJWT(ctx, jwtSalt) }
        }
    }
}
