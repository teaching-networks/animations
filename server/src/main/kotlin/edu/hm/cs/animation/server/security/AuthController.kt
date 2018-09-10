package edu.hm.cs.animation.server.security

import io.javalin.Context
import org.pac4j.core.profile.CommonProfile
import org.pac4j.core.profile.ProfileManager
import org.pac4j.javalin.Pac4jContext
import org.pac4j.jwt.config.signature.SecretSignatureConfiguration
import org.pac4j.jwt.profile.JwtGenerator
import java.util.*

object AuthController {

    const val PATH = "/api/auth"

    fun generateJWT(ctx: Context, jwtSalt: String) {
        val context: Pac4jContext = Pac4jContext(ctx)
        val profileManager = ProfileManager<CommonProfile>(context)
        val profile: Optional<CommonProfile> = profileManager.get(true)

        var token = ""
        if (profile.isPresent) {
            val generator = JwtGenerator<CommonProfile>(SecretSignatureConfiguration(jwtSalt))
            token = generator.generate(profile.get())
        }

        ctx.result(token)
    }

}