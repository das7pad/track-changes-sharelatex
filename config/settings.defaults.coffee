Path = require('path')
TMP_DIR = process.env["TMP_PATH"] or Path.resolve(Path.join(__dirname, "../../", "tmp"))

module.exports =
	mongo:
		url: process.env['MONGO_CONNECTION_STRING'] or "mongodb://#{process.env["MONGO_HOST"] or "localhost"}/sharelatex"

	internal:
		trackchanges:
			port: 3015
			host: process.env["LISTEN_ADDRESS"] or "localhost"
	apis:
		documentupdater:
			url: "http://#{process.env["DOCUMENT_UPDATER_HOST"] or process.env["DOCUPDATER_HOST"] or "localhost"}:3003"
		docstore:
			url: "http://#{process.env["DOCSTORE_HOST"] or "localhost"}:3016"
		web:
			url: "http://#{process.env['WEB_API_HOST'] or process.env['WEB_HOST'] or "localhost"}:#{process.env['WEB_API_PORT'] or process.env['WEB_PORT'] or 3000}"
			user: process.env['WEB_API_USER'] or "sharelatex"
			pass: process.env['WEB_API_PASSWORD'] or "password"
	redis:
		lock:
			port: process.env["LOCK_REDIS_PORT"] or process.env["REDIS_PORT"] or "6379"
			host: process.env["LOCK_REDIS_HOST"] or process.env["REDIS_HOST"] or "localhost"
			password: process.env["LOCK_REDIS_PASSWORD"] or process.env["REDIS_PASSWORD"] or ""
			key_schema:
				historyLock: ({doc_id}) -> "HistoryLock:{#{doc_id}}"
				historyIndexLock: ({project_id}) -> "HistoryIndexLock:{#{project_id}}"
		history:
			port: process.env["DOC_UPDATER_REDIS_PORT"] or process.env["REDIS_PORT"] or "6379"
			host: process.env["DOC_UPDATER_REDIS_HOST"] or process.env["REDIS_HOST"] or "localhost"
			password: process.env["DOC_UPDATER_REDIS_PASSWORD"] or process.env["REDIS_PASSWORD"] or ""
			key_schema:
				uncompressedHistoryOps: ({doc_id}) -> "UncompressedHistoryOps:{#{doc_id}}"
				docsWithHistoryOps: ({project_id}) -> "DocsWithHistoryOps:{#{project_id}}"

	trackchanges:
		s3:
			key: process.env['AWS_ACCESS_KEY_ID'] || process.env['AWS_KEY']
			secret: process.env['AWS_SECRET_ACCESS_KEY'] || process.env['AWS_SECRET']
			endpoint: process.env['AWS_S3_ENDPOINT']
			forcePathStyle: process.env['AWS_S3_PATH_STYLE'] == 'true'
		stores:
			doc_history: process.env['AWS_BUCKET']
		continueOnError: process.env['TRACK_CHANGES_CONTINUE_ON_ERROR'] or false
			
	path:
		dumpFolder:   Path.join(TMP_DIR, "dumpFolder")

	sentry:
		dsn: process.env.SENTRY_DSN
