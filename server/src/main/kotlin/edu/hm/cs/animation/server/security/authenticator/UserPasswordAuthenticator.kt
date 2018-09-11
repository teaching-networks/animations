package edu.hm.cs.animation.server.security.authenticator

import edu.hm.cs.animation.server.security.util.PasswordUtil
import edu.hm.cs.animation.server.user.dao.UserDAO
import org.pac4j.core.context.WebContext
import org.pac4j.core.credentials.UsernamePasswordCredentials
import org.pac4j.core.credentials.authenticator.Authenticator
import org.pac4j.core.exception.CredentialsException
import org.pac4j.core.profile.CommonProfile

/**
 * Simple authenticator which works with comparing username and password to a given pair.
 */
class UserPasswordAuthenticator : Authenticator<UsernamePasswordCredentials> {

    private val userDAO = UserDAO()

    override fun validate(credentials: UsernamePasswordCredentials, context: WebContext) {
        val user = userDAO.findUserByName(credentials.username) ?: throw CredentialsException("Invalid credentials")

        if (PasswordUtil.verifyPassword(credentials.password, user.password, user.passwordSalt)) {
            val profile = CommonProfile()

            profile.id = credentials.username
            profile.addAttribute("username", credentials.username)

            credentials.userProfile = profile
        } else {
            throw CredentialsException("Invalid credentials")
        }
    }

}