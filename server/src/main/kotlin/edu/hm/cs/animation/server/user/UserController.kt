package edu.hm.cs.animation.server.user

import edu.hm.cs.animation.server.security.util.PasswordUtil
import edu.hm.cs.animation.server.user.dao.UserDAO
import edu.hm.cs.animation.server.user.model.User
import edu.hm.cs.animation.server.util.rest.CRUDController
import io.javalin.Context

/**
 * REST Controller handling user matters.
 */
object UserController : CRUDController {

    /**
     * Path the user controller is reachable under.
     */
    const val PATH = "/api/user"

    /**
     * CRUDController to get users from.
     */
    private val userDAO = UserDAO()

    /**
     * Create a user.
     */
    override fun create(ctx: Context) {
        val user = ctx.body<User>()

        user.id = null // For safety reasons

        // Encode password
        user.passwordSalt = PasswordUtil.getSalt(PasswordUtil.DEFAULT_SALT_LENGTH)
        user.password = PasswordUtil.securePassword(user.password, user.passwordSalt!!)

        userDAO.createUser(user)
    }

    /**
     * Read a user.
     */
    override fun read(ctx: Context) {
        val id = ctx.pathParam("id").toLong()

        ctx.json(userDAO.findUser(id))
    }

    /**
     * Reads all users.
     */
    override fun readAll(ctx: Context) {
        ctx.json(userDAO.findAllUsers())
    }

    /**
     * Update a user.
     */
    override fun update(ctx: Context) {
        val user = ctx.body<User>()

        userDAO.updateUser(user)
    }

    /**
     * Delete a user.
     */
    override fun delete(ctx: Context) {
        val id = ctx.pathParam("id").toLong()

        userDAO.removeUser(id)
    }

}