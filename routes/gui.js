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
	let db_app = db.get("applications");
	let users = db.get("users");

	// Only list GUI pages if we have the correct cookies set
	router.use("/", (req, res, next) => {
		if (req.cookies.token && req.cookies.username) {
			users
			.findOne({
				username: req.cookies.username,
				token:    req.cookies.token
			})
			.then(user => {
				// If there exists a user and has an expiry that has
				// not already passed, carry on to the next part of the route
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

	// Display the index page at root
	router.get("/", (req, res) => {
		res.render("pages/index");
	});

	// Display a list of all applications
	router.get("/applications", (req, res) => {
		// Allow query searching through the applications
		let query = {};
		// Set the urgency and state if it is valid in the query
		if (req.query.urgency) query.urgency = req.query.urgency;
		if (req.query.state)   query.state   = req.query.state;
		db_app
		.find(query)
		.then(applications => {
			for (var i = 0; i < applications.length; i++) {
				let updates = applications[i].updates;
				applications[i].updates = updates.sort((a, b) => {
					if (a.timestamp < b.timestamp) {
						return 1;
					}
					if (a.timestamp < b.timestamp) {
						return -1;
					}
					return 0;
				});
			}
			res.render("pages/applications",
				{
					// Return the applications sorted by timestamp
					// so the most recent module appears first
					applications: applications.sort((a, b) => {
						let timestamp_a = 0;
						let timestamp_b = 0;

						if (a.updates.length > 0) {
							timestamp_a = a.updates[0].timestamp;
						}
						if (b.updates.length > 0) {
							timestamp_b = b.updates[0].timestamp;
						}

						if (timestamp_a < timestamp_b) {
							return 1;
						}
						if (timestamp_a > timestamp_b) {
							return -1;
						}
						return 0;
					})
				}
			);
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
		routeError(res, 404)("404 Not Found");
	});

	return router;
};

function routeError (res, code=500) {
	return error => {
		res.status(code).render("pages/error", {error: error});
	};
}
