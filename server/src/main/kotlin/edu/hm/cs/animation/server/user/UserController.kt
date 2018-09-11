package edu.hm.cs.animation.server.user

import edu.hm.cs.animation.server.security.util.PasswordUtil
import edu.hm.cs.animation.server.user.dao.UserDAO
import edu.hm.cs.animation.server.user.model.User
import io.javalin.Context

/**
 * REST Controller handling user matters.
 */
object UserController {

    /**
     * Path the user controller is reachable under.
     */
    const val PATH = "/api/user"

    /**
     * DAO to get users from.
     */
    val userDAO = UserDAO()

    /**
     * Create a user.
     */
    fun create(ctx: Context) {
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
    fun read(ctx: Context) {
        val id = ctx.pathParam("id").toLong()

        ctx.json(userDAO.findUser(id)!!)
    }

    /**
     * Reads all users.
     */
    fun readAll(ctx: Context) {
        ctx.json(userDAO.findAllUsers())
    }

    /**
     * Update a user.
     */
    fun update(ctx: Context) {
        val user = ctx.body<User>()

        userDAO.updateUser(user)
    }

    /**
     * Delete a user.
     */
    fun delete(ctx: Context) {
        val id = ctx.pathParam("id").toLong()

        userDAO.removeUser(id)
    }

}