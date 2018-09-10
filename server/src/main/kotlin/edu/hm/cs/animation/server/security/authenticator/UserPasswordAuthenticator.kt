package edu.hm.cs.animation.server.security.authenticator

import org.pac4j.core.context.WebContext
import org.pac4j.core.credentials.UsernamePasswordCredentials
import org.pac4j.core.credentials.authenticator.Authenticator
import org.pac4j.core.exception.CredentialsException
import org.pac4j.core.profile.CommonProfile

/**
 * Simple authenticator which works with comparing username and password to a given pair.
 */
class UserPasswordAuthenticator(private val username: String, private val password: String) : Authenticator<UsernamePasswordCredentials> {

    override fun validate(credentials: UsernamePasswordCredentials, context: WebContext) {
        if (credentials.username == username && credentials.password == password) {
            val profile = CommonProfile()

            profile.id = credentials.username
            profile.addAttribute("username", credentials.username)

            credentials.userProfile = profile
        } else {
            throw CredentialsException("Invalid credentials")
        }
    }

}