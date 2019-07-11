## Kitura EmojiServer

The source code is adapted from [here](https://www.raywenderlich.com/1032630-kitura-stencil-tutorial-how-to-make-websites-with-swift).

For environment setup and cloud configuration and deployment, please refer to [Setup steps](./SETUP.md) for details.

## Additional setup notes

### Postgres setup and configuration

For general download and setup for PostgreSQL DB, please refer to [this document](https://www.tutorialspoint.com/postgresql/postgresql_environment.htm). Also, [this tutorial](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-postgresql-on-ubuntu-16-04) from DigitalOcean might be helpful.
In short,

Installation, 
```sh
$ sudo apt-get update
$ sudo apt-get install postgresql postgresql-contrib
```

Creatdb named `emojijournal`,
```sh
$ sudo -i -u postgres
$ createdb -h localhost -p 5432 -U postgres emojijournal
```
Which by default will propt you for password of db default user `postgres`. Remember your password and later in `./Sources/Application/Models/Persistence.swift`, change it to the one you set. Please make sure to remember the username password you set if you decide to use other user than the default one.

### Create test user for the emoji journal application

By default, the db does not contain any user. If you want to test the feature of the web client, please create one with the `POST /user` API at `http://localhost:8080/openapi/ui` .

If you want to test with multi-user experience, create more than 2 users and login seperately from different devices.

Currently, there are no log out method for the web client. More will be added, or not. ;-)

### Nginx web server setup

Please refer to this [blog(Chinese)](https://yo1995.github.io/coding/kitura-deployment/).

## JS improvements

Per the original [tutorial]((https://www.raywenderlich.com/1032630-kitura-stencil-tutorial-how-to-make-websites-with-swift)),
> You set up an input element at the top right-hand corner to delete an entry, but you may notice that you haven’t yet written the function to handle this yet.

One improvement that I made to the app is to implement those two functions. I've no knowledge of JavaScript, hence my implementation could be ugly and not efficient. But it works well with my case.

The scripts are hardcoded in the `./Views/home.stencil` file. Please check and make PR if you are good with JS!

## Other

The app should compile with ~50 dependencies and run, logging with one warning regarding the cloud environment setup. If any error happens to appear, please open an issue to report them.

---

## Build the app

xcodebuild -workspace EmojiJournalMobileApp.xcworkspace -scheme DukeAppStore clean build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

