module.exports = (db) => {

	// Routing and returning a response
	const express = require("express");

	// Create a router and make sure it prints details to the log
	// after every request
	const router = express.Router();

	const ejs = require("ejs");

	/*** ROUTING ***/

	// Get an instance of the module and user collections
	let mod = db.get("modules");
	let users = db.get("users");

	// And keep them up to date after every request
	router.get("/", (req, res) => {
		res.render("pages/index");
	});

	// And keep them up to date after every request
	router.get("/modules", (req, res) => {
		mod
		.find()
		.then(modules => {
			res.render("pages/modules", {modules: modules});
		})
		.catch(resError(res));
	});

	// Any page not already rendered before this will throw a 404 error
	router.use((req, res, next) => {
		resError(res, 404)("404 Not Found")
	})

	return router;
}

function resError (res, code=500) {
	return error => {
		res.status(code).render("pages/error", {error: error});
	};
}