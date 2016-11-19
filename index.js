/*** REQUIREMENTS ***/

// Routing and returning a response
const express = require("express");

// Parses the body of a HTTP request/response
const bodyParser = require("body-parser");

// Connecting to the database
const monk = require("monk");

// Printing useful access details to the log
const morgan = require("morgan");

// Contains all the configuration for connecting to the mongo database
// and running the express server
const cf = require("./config");

/*** APP SETUP ***/

// Connect to the mongodb server
monk(`${cf.MSERVER}:${cf.MPORT}/${cf.MDB}`)
	// Once it's done that successfully, only then can we continue
	.then(db => {
		// Set up express and bodyparser
		const app = express();
		app.use (bodyParser.urlencoded( { extended: true } ));
		app.use (bodyParser.json());
		app.use (morgan("dev"));

		// Configure express for use with EJS
		app.set ("view engine", "ejs");

		// Get both routes, one for the UI, and one for the API
		let api = require("./routes/api")(db, cf);
		let gui = require("./routes/gui")(db);

		// Run the server through the /api
		// eg. /api/modules
		app.use("/api/", api);
		app.use("/",     gui);

		// Listen at the specified URL and port,
		// and print to the console when it's ready
		app.listen(cf.SPORT, cf.SURL, () => {
			console.log(`Listening at http://${cf.SURL}:${cf.SPORT}/`);
		});
	})
	// If the server could not connect to mongo, print the error message.
	.catch(err => console.log(err.message));
