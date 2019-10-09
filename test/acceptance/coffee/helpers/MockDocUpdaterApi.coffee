express = require("express")
bodyParser = require("body-parser")
app = express()

module.exports = MockDocUpdaterApi =
	docs: {}

	getDoc: (project_id, doc_id, callback = (error) ->) ->
		callback null, @docs[doc_id]

	setDoc: (project_id, doc_id, lines, user_id, undoing, callback = (error) ->) ->
		@docs[doc_id] ||= {}
		@docs[doc_id].lines = lines
		callback()

	run: () ->
		app.get "/project/:project_id/doc/:doc_id", (req, res, next) =>
			@getDoc req.params.project_id, req.params.doc_id, (error, doc) ->
				if error?
					res.sendStatus 500
				if !doc?
					res.sendStatus 404
				else
					res.send JSON.stringify doc

		app.post "/project/:project_id/doc/:doc_id", bodyParser(), (req, res, next) =>
			@setDoc req.params.project_id, req.params.doc_id, req.body.lines, req.body.user_id, req.body.undoing, (errr, doc) ->
				if error?
					res.sendStatus 500
				else
					res.sendStatus 204

		app.listen 3003, (error) ->
			throw error if error?
		.on "error", (error) ->
			console.error "error starting MockDocUpdaterApi:", error.message
			process.exit(1)


MockDocUpdaterApi.run()

