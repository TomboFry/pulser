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

// Enum for the status of a request
const status = {
	ERR: "error",
	SUC: "success"
};

// A list of possible states for a module to be in
const mod_state = [
	"created", "progress", "ongoing", "finished"
];

/*** APP SETUP ***/

// Connect to the mongodb server
monk(`${cf.MSERVER}:${cf.MPORT}/${cf.MDB}`)
	// Once it's done that successfully, only then can we continue
	.then(db => {
		// Set up express and bodyparser
		const app = express();
		app.use (bodyParser.urlencoded( { extended: true } ));
		app.use (bodyParser.json());

		// Create a router and make sure it prints details to the log
		// after every request
		const router = express.Router();
		router.use(morgan("dev"));

		// Get an instance of the modules collection
		let mod = db.get("modules");
		// And keep it up to date after every request
		router.use((req, res, next) => {
			mod = db.get("modules");
			next();
		});

		// When the homepage is requested just print it was successful
		// (for now?)
		router.get("/", (req, res) => resJson(res, status.SUC));

		// TODO: Implement authentication for
		// more secure connection over WAN
		router.get("/auth", (req, res) => {
			resJson(res, status.ERR, "Not implemented");
		});

		// Retrieve a list of modules and print them in an array
		router.get("/modules", (req, res) => {
			mod
			.find({}/*, "-_id -text -value -state"*/)
			.then(modules => {
				if (!modules || modules.length == 0) {
					resJson(res, status.ERR, "No Modules Found");
				} else {
					resJson(res, status.SUC, modules);
				}
			})
			.catch(routeError(res));
		});

		// When a specific status is requested
		router.route("/modules/:name")
		// Update it, and if it doesn't exist create it.
		.put((req, res) => {
			let query = { name: req.params.name };

			let state = req.body.state;
			if (state === undefined ||
				(state !== "" && mod_state.indexOf(state) == -1)
			) {
				resJson(res, status.ERR, `Invalid State: '${state}'`);
				return;
			}

			let values = {
				name: req.params.name,
				text: req.body.text || "",
				value: req.body.value || "",
				state: state || mod_state[0]
			};

			mod
			.findOne(query)
			.then(module => {
				if (module) {
					mod
					.update(query, values)
					.then(module => resJson(res, status.SUC, module))
					.catch(routeError(res));
				} else {
					mod
					.insert(values)
					.then(module => resJson(res, status.SUC, module))
					.catch(routeError(res));
				}
			})
			.catch(routeError(res));
		})
		// Return the status of the module
		.get((req, res) => {
			mod
			.findOne( { name: req.params.name } )
			.then(module => {
				if (module) {
					resJson(res, status.SUC, module);
				} else {
					resJson(res, status.ERR, "Module not set");
				}
			})
			.catch(routeError(res));
		})
		.delete((req, res) => {
			mod
			.remove( { name: req.params.name} )
			.then(upd => resJson(res, status.SUC, upd))
			.catch(routeError(res));
		});

		// Run the server directly at root
		app.use("/", router);

		// Listen at the specified URL and port,
		// and print to the console when it's ready
		app.listen(cf.SPORT, cf.SURL, () => {
			console.log(`Listening at http://${cf.SURL}:${cf.SPORT}/`);
		});
	})
	// If the server could not connect to mongo, print the error message.
	.catch(err => console.log(err.message));

/*** MISCELLANEOUS FUNCTIONS ***/

// Returns the specified object to the user,
// With the time included
function resJson(res, status, obj) {
	res.json( { time: timeNow(), status: status, data: obj } );
}

function routeError(res) {
	return err => resJson(res, status.ERR, err.message);
}

// Returns the current server time in a readable format
function timeNow() {
	let d = new Date(),
	    h = (d.getHours()<10?'0':'') + d.getHours(),
	    m = (d.getMinutes()<10?'0':'') + d.getMinutes(),
	    s = (d.getSeconds()<10?'0':'') + d.getSeconds();
	return `${h}:${m}:${s}`;
}
