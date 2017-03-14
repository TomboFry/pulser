module.exports = (db, cf, io) => {
	/*** REQUIREMENTS ***/

	// Require bcrypt to hash passwords and authenticate users
	const bcrypt = require("bcrypt-nodejs");

	// Generates random IDs to be used for the login tokens
	const hat = require("hat");

	// Enum for the status of a request
	const status = {
		ERR: "error",
		SUC: "success"
	};

	// A list of possible states for a module to be in
	const mod_state = [
		"created", "progress", "ongoing", "finished", "failed"
	];

	// A list of possible urgencies for a module to have
	const mod_urgency = [
		"low", "med", "high"
	];

	// Routing and returning a response
	const express = require("express");

	// Create a router and make sure it prints details to the log
	// after every request
	const router = express.Router();

	/*** ROUTING ***/

	// Get an instance of the module and user collections
	let db_app = db.get("applications");
	let users = db.get("users");

	let genPassword = (username, password, callback) => {
		bcrypt.genSalt(cf.SALTROUNDS, (err, salt) => {
			if (err) callback(null, err);
			bcrypt.hash(password, salt, null, (err, hashed_password) => {
				if (err) callback(null, err);
				let values = {
					username: username,
					password: hashed_password,
					token: "",
					token_expiry: "",
					is_application: false
				};
				console.log(values);
				callback(values);
			});
		});
	};

	router.use(
		["/auth", "/applications", "/applications/:app_slug",
		"/applications/:app_slug/updates",
		"/applications/:app_slug/updates/:upd_id"],
		(req, res, next) => {
		// Authenticate after every request
		if (req.headers.authorization) {
			const encoded = req.headers.authorization.split(' ')[1];
			const decoded = new Buffer(encoded, 'base64')
			                  .toString('utf8')
			                  .split(":");
			users
			.findOne({username: decoded[0], token: decoded[1]})
			.then(user => {
				if (user !== null) {
					// If the token hasn't expired, or it's the application user
					// attempting to login, let them through.
					if (user.token_expiry > Date.now() ||
					    user.is_application === true) {
						next();
					} else {
						resJson(res, status.ERR, "Token expired. Log in again");
					}
				} else {
					resJson(res, status.ERR, "User doesn't exist");
				}
			})
			.catch(routeError(res));
		} else {
			resJson(res, status.ERR, "Authentication required");
		}
	});

	// When the homepage is requested just print it was successful
	router.get("/", (req, res) => resJson(res, status.SUC));
	router.get("/auth", (req, res) => resJson(res, status.SUC));

	// Authenticate the user if they don't have a token
	router.post("/login", (req, res) => {
		// Make sure a username and password are provided
		if (!req.body.username || !req.body.password) {
			return resJson(res, status.ERR,
			               "Both username and password required");
		}
		const username = req.body.username;
		const password = req.body.password;

		// Generate a token for a specific user
		let genToken = (user) => {
			let values = Object.assign({}, user);
			// Generate the token
			values.token = hat();
			// Add 7 days to the current date
			values.token_expiry = Date.now() + 604800000;

			users
			.update(user, values)
			.then(done => {
				resJson(
					res
					// Clear any existing cookies
					.clearCookie("token").clearCookie("username")
					// Set the cookies with an expiry date
					.cookie("token",
					        values.token,
					        { maxAge: values.token_expiry })
					.cookie("username",
					        username,
					        { maxAge: values.token_expiry }),
					status.SUC,
					// Also return the token as a string if using the REST api.
					values.token
				);
			})
			.catch(routeError(res));
		};

		users
		.findOne({username: username})
		.then(user => {
			if (user !== null) {
				// Make sure the password matches up with the hashed password
				bcrypt.compare(password, user.password, (err, result) => {
					if (result === true) {
						genToken(user);
					} else {
						resJson(res, status.ERR, "Password incorrect");
					}
				});
			} else {
				resJson(res, status.ERR, "User does not exist");
			}
		})
		.catch(routeError(res));
	});

	// On logout, clear the cookies
	router.post("/logout", (req, res) => {
		res
		.clearCookie("token")
		.clearCookie("username")
		.redirect("/api");
	});

	// Creating a new user
	router.post("/users", (req, res) => {
		users = db.get("users");

		// Make sure a username and password are provided
		if (!req.body.username || !req.body.password) {
			return resJson(res, status.ERR,
			               "Both username and password required");
		}

		const username = req.body.username;
		const password = req.body.password;

		users
		.findOne({username: username})
		.then(user => {
			// Make sure the user doesn't already exist
			if (user === null) {
				// Also hash the provided password for the new user.
				genPassword(username, password, (values, err) => {
					if (err) routeError(res)(err);

					values.is_application = req.body.is_application || false;

					users
					.insert(values)
					.then(done => {
						resJson(res, status.SUC, done);
					})
					.catch(routeError(res));
				});
			} else {
				resJson(res, status.ERR, "User already exists");
			}
		})
		.catch(routeError(res));
	});

	// Updating an existing user
	router.route("/users/:username")
	.put((req, res) => {
		const username = req.params.username;
		const password = req.body.password;

		// Make sure the password is provided
		if (!password) {
			resJson(res, status.ERR, "Password must be filled in");
		}

		users
		.findOne({ username: username })
		.then(user => {
			// Make sure the user actually exists
			if (user !== null) {
				// Generate a new password and update the DB fields
				genPassword(username, password, (values, err) => {
					if (err) routeError(res)(err);
					// First update the other users so they are not
					// an application user
					users
					.update(
					    {username: { $ne: username }},
					    {$set: { is_application: false }},
					    false, true)
					.then(prelim_result => {
						// Then update the user as intended
						values.is_application = req.body.is_application || false;
						users
						.update({username: username}, values)
						.then(result => resJson(res, status.SUC, result))
						.catch(error => routeError(res));
					})
					.catch(error => routeError(res));
				});
			} else {
				resJson(res, status.ERR, "User does not exist");
			}
		})
		.catch(routeError(res));
	})
	// Deleting an existing user
	.delete((req, res) => {
		const username = req.params.username;
		users
		.findOne({ username: username })
		.then(user => {
			// Make sure it actually exists
			if (user !== null) {
				users
				.remove({ username: username })
				.then(result => {
					resJson(res, status.SUC, result);
				});
			} else {
				resJson(res, status.ERR, "User does not exist to delete");
			}
		})
		.catch(routeError(res));
	});

	// Keep the applications db up to date after every request to the applications route
	router.use("/applications", (req, res, next) => {
		db_app = db.get("applications");
		next();
	});

	// Retrieve a list of applications and print them in an array
	router.route("/applications")
	.get((req, res) => {
		db_app
		.find({})
		.then(applications => {
			if (!applications || applications.length === 0) {
				resJson(res, status.ERR, "No applications Found");
			} else {
				resJson(res, status.SUC, applications);
			}
		})
		.catch(routeError(res));
	})
	.post((req, res) => {

		let requirement = 0;
		let requirement_threshold = 2;

		if (req.body.app_slug) requirement++;
		if (req.body.app_name) requirement++;
		if (req.body.app_image) requirement++;
		if (requirement < requirement_threshold) {
			resJson(res, status.ERR,
			        "Application name and slug required, image optional");
			return;
		}

		let query = { slug: req.body.app_slug };

		db_app
		.findOne(query)
		.then(application => {
			if (application) {
				resJson(res, status.ERR, "Application already exists");
			} else {
				let values = {
					slug: req.body.app_slug,
					name: req.body.app_name,
					image: req.body.app_image || "",
					updates: []
				}
				db_app
				.insert(values)
				.then(result => resJson(res, status.SUC, "Application added"))
				.catch(routeError(res));
			}
		})
		.catch(routeError(res));
	});

	router.route("/applications/:app_slug")
	.get((req, res) => {
		let query = { slug: req.params.app_slug };

		db_app
		.findOne(query)
		.then(application => {
			if (application) {
				resJson(res, status.SUC, application);
			} else {
				resJson(res, status.ERR, "Application doesn't exist");
			}
		})
		.catch(routeError(res));
	})
	.put((req, res) => {
		let query = { slug: req.params.app_slug };

		db_app
		.findOne(query)
		.then(application => {
			if (application) {
				let values = {
					slug: application.slug,
					name: req.body.app_name || application.name,
					image: req.body.app_image || application.image,
					updates: application.updates
				}
				db_app
				.update(query, values)
				.then(result => resJson(res, status.SUC, "Application updated"))
				.catch(routeError(res));
			} else {
				resJson(res, status.ERR, "Application doesn't exist");
			}
		})
	})
	.delete((req, res) => {
		let query = { slug: req.params.app_slug };

		db_app
		.findOne(query)
		.then(application => {
			if (application) {
				db_app
				.remove(query)
				.then(result => resJson(res, status.SUC, "Application deleted"))
				.catch(routeError(res));
			} else {
				resJson(res, status.ERR, "Application doesn't exist");
			}
		})
	});

	// When a specific status is requested
	router.route("/applications/:app_slug/updates")
	.get((req, res) => {
		let query = { slug: req.params.app_slug };

		db_app
		.findOne(query)
		.then(application => {
			if (application && application.updates.length > 0) {
				resJson(res, status.SUC, application.updates);
			} else {
				resJson(res, status.ERR,
				        `Updates are empty for '${application.name}'`);
			}
		})
	})
	// Update it, and if it doesn't exist create it.
	.post((req, res) => {
		let query = { slug: req.params.app_slug };

		db_app
		.findOne(query)
		.then(application => {
			// If the application already exists, update it, otherwise add it.
			if (application) {
				// If a state is provided, make sure it's valid
				let state = req.body.state;
				if (
					state !== undefined &&
					state !== "" &&
					mod_state.indexOf(state) == -1
				) {
					resJson(res, status.ERR, `Invalid State: '${state}'`);
					return;
				}

				// Also make sure the value (if provided) is between 0 and 100
				let value = req.body.value;
				if (value !== undefined && value !== "" &&
				   ((Number(parseFloat(value)) != value) ||
				    (value < 0 || value > 100))) {
					resJson(res, status.ERR,
					        `Invalid or out of range value: '${value}'`);
					return;
				}

				// Make sure the urgency is valid if provided
				let urgency = req.body.urgency;
				if (
					urgency !== undefined &&
					urgency !== "" &&
					mod_urgency.indexOf(urgency) == -1
				) {
					resJson(res, status.ERR, `Invalid Urgency: '${urgency}'`);
					return;
				}

				// Create an object with all the validated values
				let values = {
					_id: db.helper.id.ObjectID(), // Creates a new ObjectID
					text: req.body.text || "",
					value: value || "",
					state: state || mod_state[0],
					urgency: urgency || mod_urgency[0],
					timestamp: Math.round(Date.now() / 1000)
				};

				// Send a packet to any clients connected via the websocket
				// for push notifications
				io.emit("module-update", {
					"slug": req.params.app_slug,
					"updates": values
				});

				db_app
				.update(query, { $push: { "updates": values } })
				.then(module => resJson(res, status.SUC, module))
				.catch(routeError(res));
			} else {
				resJson(res, status.ERR, "Application doesn't exist");
			}
		})
		.catch(routeError(res));
	});

	router.route("/applications/:app_slug/updates/:upd_id")
	.get((req, res) => {
		let query = {
			"slug": req.params.app_slug,
			"updates": { "$elemMatch": { "_id": req.params.upd_id } }
		};

		db_app
		.findOne(query)
		.then(update => {
			if (update) {
				resJson(res, status.SUC, update.updates);
			} else {
				resJson(res, status.ERR, "Update not found")
			}
		})
		.catch(routeError(res));
	})
	.delete((req, res) => {
		let query = {
			"slug": req.params.app_slug,
			"updates": { "$elemMatch": { "_id": req.params.upd_id } }
		};

		db_app
		.findOne(query)
		.then(update => {
			if (update) {
				let updates = {
					"$pull": { "updates": { "_id": req.params.upd_id } }
				};

				db_app
				.update(query, updates)
				.then(result => resJson(res, status.SUC, "Update Removed"))
				.catch(routeError(res));
			} else {
				resJson(res, status.ERR, "This update doesn't exist");
			}
		})
		.catch(routeError(res));
	});

	return router;
};

/*** MISCELLANEOUS FUNCTIONS ***/

// Returns the specified object to the user,
// With the time included
function resJson(res, status, obj) {
	return res.json( { time: timeNow(), status: status, data: obj } );
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
