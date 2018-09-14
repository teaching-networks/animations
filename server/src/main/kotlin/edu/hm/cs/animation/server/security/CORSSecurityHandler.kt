package edu.hm.cs.animation.server.security

import io.javalin.Context
import io.javalin.Handler
import org.eclipse.jetty.http.HttpMethod
import org.pac4j.core.config.Config
import org.pac4j.core.context.HttpConstants
import org.pac4j.javalin.SecurityHandler

/**
 * Security handler which does not check OPTIONS HTTP Requests because they do not need to
 * be checked.
 */
class CORSSecurityHandler(private val securityHandler: SecurityHandler) : Handler {

    override fun handle(ctx: Context) {
        // Add response header (Allow credentials)
        ctx.header(HttpConstants.ACCESS_CONTROL_ALLOW_CREDENTIALS_HEADER, "true")

        if (!HttpConstants.HTTP_METHOD.OPTIONS.name.equals(ctx.method(), ignoreCase = true)) {
            securityHandler.handle(ctx);
        }
    }

}