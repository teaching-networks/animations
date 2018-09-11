package edu.hm.cs.animation.server.user.model

import com.fasterxml.jackson.annotation.JsonInclude
import net.minidev.json.annotate.JsonIgnore
import javax.persistence.*

/**
 * ApiUser of the API.
 */
@Entity
@JsonInclude(JsonInclude.Include.NON_NULL)
data class ApiUser(

        /**
         * The users id.
         */
        @Id
        @GeneratedValue(strategy = GenerationType.AUTO)
        var id: Long,

        /**
         * Name of the user.
         */
        @Column(nullable = false, unique = true)
        var name: String,

        /**
         * Password of the user. Should be encoded and not plain-text.
         */
        @Column(nullable = false)
        var password: String,

        /**
         * Salt used to encode the password.
         * Used to verify whether a password matches the one stored in the user.
         */
        @Column(nullable = false)
        @JsonIgnore
        var passwordSalt: String

)