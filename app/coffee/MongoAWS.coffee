settings = require "settings-sharelatex"
logger = require "logger-sharelatex"
AWS = require 'aws-sdk'
{db, ObjectId} = require "./mongojs"
JSONStream = require "JSONStream"
ReadlineStream = require "byline"
zlib = require "zlib"
Metrics = require "metrics-sharelatex"

DAYS = 24 * 3600 * 1000 # one day in milliseconds
s3 = new AWS.S3(
	accessKeyId: settings.trackchanges.s3.key
	secretAccessKey: settings.trackchanges.s3.secret
	endpoint: settings.trackchanges.s3.endpoint
	s3ForcePathStyle: settings.trackchanges.s3.forcePathStyle
	signatureVersion: 'v4'
)

module.exports = MongoAWS =

	archivePack: (project_id, doc_id, pack_id, callback = (error) ->) ->

		query = {
			_id: ObjectId(pack_id)
			doc_id: ObjectId(doc_id)
		}

		return callback new Error("invalid project id") if not project_id?
		return callback new Error("invalid doc id") if not doc_id?
		return callback new Error("invalid pack id") if not pack_id?

		logger.log {project_id, doc_id, pack_id}, "uploading data to s3"

		db.docHistory.findOne query, (err, result) ->
			return callback(err) if err?
			return callback new Error("cannot find pack to send to s3") if not result?
			return callback new Error("refusing to send pack with TTL to s3") if result.expiresAt?
			uncompressedData = JSON.stringify(result)
			if uncompressedData.indexOf("\u0000") != -1
				error = new Error("null bytes found in upload")
				logger.error err: error, project_id: project_id, doc_id: doc_id, pack_id: pack_id, error.message
				return callback(error)
			zlib.gzip uncompressedData, (err, buf) ->
				logger.log {project_id, doc_id, pack_id, origSize: uncompressedData.length, newSize: buf.length}, "compressed pack"
				return callback(err) if err?

				params =
					Body: buf
					Bucket: settings.trackchanges.stores.doc_history,
					Key: "#{project_id}/changes-#{doc_id}/pack-#{pack_id}"

				s3.putObject params, (error) ->
					return callback(error) if error?
					Metrics.inc("archive-pack")
					logger.log {project_id, doc_id, pack_id}, "upload to s3 completed"
					callback(null)

	readArchivedPack: (project_id, doc_id, pack_id, _callback = (error, result) ->) ->
		callback = (args...) ->
			_callback(args...)
			_callback = () ->

		return callback new Error("invalid project id") if not project_id?
		return callback new Error("invalid doc id") if not doc_id?
		return callback new Error("invalid pack id") if not pack_id?

		logger.log {project_id, doc_id, pack_id}, "downloading data from s3"

		params =
			Bucket: settings.trackchanges.stores.doc_history,
			Key: "#{project_id}/changes-#{doc_id}/pack-#{pack_id}"

		s3.getObject params, (error, response) ->
			if error?
				logger.log {project_id, doc_id, pack_id, error}, "download from s3 failed"
				return callback(error) if error?

			logger.log {project_id, doc_id, pack_id}, "download from s3 completed"
			zlib.gunzip response.Body, {encoding: 'utf-8'}, (error, data) ->
				if error?
					logger.log {project_id, doc_id, pack_id, err}, "error uncompressing gzip stream"
					return callback(error)

				try
					object = JSON.parse data
				catch e
					return callback(e)
				object._id = ObjectId(object._id)
				object.doc_id = ObjectId(object.doc_id)
				object.project_id = ObjectId(object.project_id)
				for op in object.pack
					op._id = ObjectId(op._id) if op._id?
				callback null, object

	unArchivePack: (project_id, doc_id, pack_id, callback = (error) ->) ->
		MongoAWS.readArchivedPack project_id, doc_id, pack_id, (err, object) ->
			return callback(err) if err?
			Metrics.inc("unarchive-pack")
			# allow the object to expire, we can always retrieve it again
			object.expiresAt = new Date(Date.now() + 7 * DAYS)
			logger.log {project_id, doc_id, pack_id}, "inserting object from s3"
			db.docHistory.insert object, callback
