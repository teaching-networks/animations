package edu.hm.cs.animation.server

import com.xenomachina.argparser.ArgParser
import edu.hm.cs.animation.server.animation.AnimationController
import edu.hm.cs.animation.server.security.AuthController
import edu.hm.cs.animation.server.security.SecurityConfigFactory
import edu.hm.cs.animation.server.user.UserController
import edu.hm.cs.animation.server.util.cmdargs.CMDLineArgumentParser
import io.javalin.Javalin
import io.javalin.apibuilder.ApiBuilder.*
import io.javalin.json.JavalinJackson
import javafx.animation.Animation
import org.pac4j.javalin.SecurityHandler
import javax.persistence.Persistence

/**
 * Entry point for the server.
 *
 * @see CMDLineArgumentParser for available command line options
 */
fun main(args: Array<String>) {
    ArgParser(args).parseInto(::CMDLineArgumentParser).run {
        // Set up security configuration of pac4j
        val securityConfig = SecurityConfigFactory(jwtSalt).build()

        // Create the Javalin server
        val app = Javalin.create().apply {
            port(port)

            if (debug) {
                enableCorsForAllOrigins()
            } else if (corsEnabledOrigin.isNotEmpty()) {
                enableCorsForOrigin(corsEnabledOrigin)
            }
        }.start()

        // Here go all routes!
        app.routes {
            // Security via JWT for all paths starting with /api
            before("/api/*", SecurityHandler(securityConfig, "HeaderClient"))

            // The below item is used to test the authentication using JSON Web Tokens
            get("/api/hello") { ctx -> ctx.result("Hello World") }

            // AuthController
            before(AuthController.PATH, SecurityHandler(securityConfig, "DirectBasicAuthClient")) // Use basic authentication for fetching a JSON Web Token
            get(AuthController.PATH) { ctx -> AuthController.generateJWT(ctx, jwtSalt) }

            path("api") {

                // User controller
                path(UserController.PATH) {
                    post(UserController::create)
                    get(UserController::readAll)
                    patch(UserController::update)
                    path(":id") {
                        get(UserController::read)
                        delete(UserController::delete)
                    }
                }

                // Animation controller
                path(AnimationController.PATH) {
                    post(AnimationController::create)
                    get(AnimationController::readAll)
                    patch(AnimationController::update)
                    path(":id") {
                        get(AnimationController::read)
                        delete(AnimationController::delete)
                    }
                }

            }
        }
    }
}
