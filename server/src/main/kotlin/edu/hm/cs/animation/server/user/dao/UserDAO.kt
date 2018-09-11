package edu.hm.cs.animation.server.user.dao

import edu.hm.cs.animation.server.user.model.ApiUser
import edu.hm.cs.animation.server.util.PersistenceUtil

/**
 * Data access object dealing with users.
 */
class UserDAO {

    fun findAllUsers(): List<ApiUser> {
        val em = PersistenceUtil.createEntityManager();
        val transaction = em.transaction;
        transaction.begin()

        val users: List<ApiUser> = em.createQuery("SELECT e FROM ApiUser e").resultList as List<ApiUser>

        transaction.commit()

        return users
    }

    fun findUser(id: Long): ApiUser? {
        val em = PersistenceUtil.createEntityManager()
        val transaction = em.transaction
        transaction.begin()

        val user: ApiUser? = em.find(ApiUser::class.java, id)

        transaction.commit()

        return user
    }

    fun findUserByName(name: String): ApiUser? {
        val em = PersistenceUtil.createEntityManager()
        val transaction = em.transaction
        transaction.begin()

        val user: ApiUser? = em.createQuery("SELECT u from ApiUser u WHERE u.name = :name", ApiUser::class.java).setParameter("name", name).singleResult

        transaction.commit()

        return user
    }

    fun createUser(user: ApiUser) {
        val em = PersistenceUtil.createEntityManager();
        val transaction = em.transaction;
        transaction.begin()

        try {
            em.persist(user)
            transaction.commit()
        } catch (e: Exception) {
            transaction.rollback()

            throw e // Rethrow exception
        }
    }

    fun updateUser(user: ApiUser) {
        val dbUser = findUser(user.id) ?: throw Exception("User to update could not be found in the database")

        dbUser.name = user.name
        dbUser.password = user.password

        val em = PersistenceUtil.createEntityManager();
        val transaction = em.transaction;
        transaction.begin()

        try {
            em.merge(dbUser)
            transaction.commit()
        } catch (e: Exception) {
            transaction.rollback()

            throw e // Rethrow exception
        }
    }

    fun removeUser(id: Long) {
        val dbUser = findUser(id) ?: throw Exception("User to remove could not be found in the database")

        val em = PersistenceUtil.createEntityManager();
        val transaction = em.transaction;
        transaction.begin()

        em.remove(dbUser)

        transaction.commit()
    }

}