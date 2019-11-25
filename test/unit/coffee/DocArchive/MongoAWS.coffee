chai = require('chai')
chai.should()
sinon = require("sinon")
modulePath = "../../../../app/js/MongoAWS.js"
SandboxedModule = require('sandboxed-module')
{ObjectId} = require("mongojs")
zlib = require "zlib"

describe "MongoAWS", ->
	beforeEach ->
		@s3 =
			getObject: sinon.stub()
			putObject: sinon.stub()
		@awssdk =
			S3: sinon.stub().returns @s3

		@MongoAWS = SandboxedModule.require modulePath, requires:
			"settings-sharelatex": @settings =
				trackchanges:
					s3:
						secret: "s3-secret"
						key: "s3-key"
					stores:
						doc_history: "s3-bucket"
			"child_process": @child_process = {}
			"logger-sharelatex": @logger = {log: sinon.stub(), error: sinon.stub(), err:->}
			"aws-sdk": @awssdk
			"fs": @fs = {}
			"./mongojs" : { db: @db = {}, ObjectId: ObjectId }
			'metrics-sharelatex': {inc: ()->}

		@project_id = ObjectId().toString()
		@doc_id = ObjectId().toString()
		@pack_id = ObjectId()
		@update = { v:123 }
		@callback = sinon.stub()

	describe "archivePack", ->

		beforeEach (done) ->
			@s3.putObject = sinon.stub().callsArgWith(1, null)
			@db.docHistory = {}
			@db.docHistory.findOne = sinon.stub().callsArgWith(1, null, {"pack":"hello"})

			@MongoAWS.archivePack @project_id, @doc_id, @pack_id, (err, result) =>
				@callback()
				done()

		it "should call the callback", ->
			@callback.called.should.equal true

	describe "unArchivePack", ->

		beforeEach (done) ->
			zlib.gzip '{"pack":"123"}', (err, zbuf) =>

				@s3.getObject = sinon.stub().callsArgWith(1, null, {Body: zbuf})
				@db.docHistory = {}
				@db.docHistory.insert = sinon.stub().callsArgWith(1, null, "pack")

				@MongoAWS.unArchivePack @project_id, @doc_id, @pack_id, (err, result) =>
					@callback()
					done()

		it "should call db.docHistory.insert", ->
			@db.docHistory.insert.called.should.equal true
