/*** REQUIREMENTS ***/

// Routing and returning a response
const express = require("express");

// Parses the body of a HTTP request/response
const bodyParser = require("body-parser");

// Connecting to the database
const monk = require("monk");

// Printing useful access details to the log
const morgan = require("morgan");

// Contains all the configuration for connecting to the mongo database and running the express server
const config = require("./config");

const status = {
	ERR: "error",
	SUC: "success"
}

/*** APP SETUP ***/

monk(config.MSERVER + ":" + config.MPORT + "/" + config.MDB)
	.then(db => {
		const app = express();
		app.use (bodyParser.urlencoded( { extended: true } ));
		app.use (bodyParser.json());

		const router = express.Router();
		router.use(morgan("dev"));

		router.get("/", (req, res) => {
			resJson(res, { status: status.SUC } );
		});

		router.get("/auth", (req, res) => {
			res.send("No");
		});

		router.route("/status/:name")
			.put((req, res) => {
				let query = { name: req.params.name };
				let values = {
					name: req.params.name,
					text: req.body.text || "",
					value: req.body.value || ""
				};

				db.get("modules").findOne(query)
				.then(module => {
					console.log(module);
					if (module !== null) {
						db.get("modules").update(query, values)
						.then(module => resJson(res, { status: status.SUC, module: module } ));
					} else {
						db.get("modules").insert(values)
						.then(module => resJson(res, { status: status.SUC, module: module } ));
					}
				})
				.catch(err => resJson(res, { status: status.ERR, response: "Query could not be completed" } ));
			})
			.get((req, res) => {
				db.get("modules")
					.findOne( { name: req.params.name } )
					.then(module => {
						if (module === null) {
							resJson(res, { status: status.ERR, response: "Module not set" } );
						} else {
							resJson(res, { status: status.SUC, response: module } );
						}
					})
					.catch(err => resJson(res, { status: status.ERR, message: err.message } ));
			});

		app.use("/", router);

		app.listen(config.SPORT, config.SURL, () => {
			console.log("Listening at http://" + config.SURL + ":" + config.SPORT + "/");
		});
	})
	.catch(err => console.log(err.message));

/*** MISCELLANEOUS FUNCTIONS ***/

function resJson(res, obj) {
	res.json(Object.assign({ time:timeNow() }, obj));
}

function timeNow() {
	let d = new Date(),
		h = (d.getHours()<10?'0':'') + d.getHours(),
		m = (d.getMinutes()<10?'0':'') + d.getMinutes(),
		s = (d.getSeconds()<10?'0':'') + d.getSeconds();
	return h + ':' + m + ':' + s;
}