module.exports = (db) => {

	// Routing and returning a response
	const express = require("express");

	// Create a router and use the EJS rendering engine
	const router = express.Router();
	const ejs = require("ejs");

	// Parse cookies so we can stay logged in
	const cookieParser = require("cookie-parser");
	router.use(cookieParser());

	/*** ROUTING ***/

	// Get an instance of the module and user collections
	let mod = db.get("modules");
	let users = db.get("users");

	// Display the index page at root
	router.use("/", (req, res, next) => {
		if (req.cookies.token && req.cookies.username) {
			users
			.findOne({
				username: req.cookies.username,
				token:    req.cookies.token
			})
			.then(user => {
				if (user !== null && user.token_expiry > Date.now()) {
					next();
				} else {
					res.render("pages/login");
				}
			})
			.catch(routeError(res));
		} else {
			res.render("pages/login");
		}
	});

	router.get("/", (req, res) => {
		res.render("pages/index");
	});

	// Display a list of all modules
	router.get("/modules", (req, res) => {
		mod
		.find()
		.then(modules => {
			res.render("pages/modules", {modules: modules});
		})
		.catch(routeError(res));
	});

	// Display a list of all users
	router.get("/users", (req, res) => {
		users
		.find()
		.then(users => {
			res.render("pages/users", {users: users});
		})
		.catch(routeError(res));
	});

	// Any page not already rendered before this will throw a 404 error
	router.use((req, res, next) => {
		routeError(res, 404)("404 Not Found")
	});

	return router;
};

function routeError (res, code=500) {
	return error => {
		res.status(code).render("pages/error", {error: error});
	};
}
