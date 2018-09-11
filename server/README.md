# HM Animations Server

## Motivation
While the web application alone handles all the animation stuff and can pretty much operate on its own, we needed a possibility to manage visible animations so that students can build up curiosity and stay tuned for more.

## Getting started
- Set up a PostgreSQL database and include the JDBC Url, username and password in the `persistence.xml` file.
- Build the project with gradle or use your IDE (e. g. IntelliJ) to build it for you (Launch configuration with Main.kt as entry point). You need to include the following command line parameters: `--port 4200 --debug --jwt-salt "12345678901234567890123456789012"`.

## Technology
The server is based on [Javalin](javalin.io) which is a java/kotlin library used to build a REST web service. For building we have [Gradle](https://gradle.org/).

## Security
Since the REST API is primarily though of as a management tool for the web application we have to restrict access to it.

This is done via JSON Web Tokens and Basic HTTP Authentication. The first step is to login via Basic Authentication. As an result to the login you'll get your JSON Web Token which you can use to authenticate to every API call.

### How do I get my JSON Web Token?
Well you basically just do a GET Request to `http://localhost:4200/api/auth` where you attach the `Authorization` HTTP header with `Basic YYY` as content. You may ask what is `YYY`: It is username and password of your user in the form `username:password` encoded in Base64.
You may say "I don't even have a user yet!" because you just created the database for the server. That is no problem as you can login in this case with username "admin" and password "admin" (Note that this will just work in case you have no user in the database).
As result you should get your JSON Web Token.

### How do I authenticate using the JSON Web Token?
Once you retrieved your JSON Web Token you can just head over to another GET request to `http://localhost:4200/api/hello`. You have to add the `Authorization` header again but now with the JSON Web Token as value: `Authorization: xxxxxx.yyyyyy.zzzzzz` (Of course your JSON Web Token will be much longer).

As result you should now get `Hello World`.
