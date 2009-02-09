class Maintenance < Application
	
	def dump
		# fetch the db conf for this environment
		path = Merb.dir_for(:config) / "database.yml"
		conf = Erubis.load_yaml_file(path)[Merb.environment]
		
		# dump the current database with mysqldump - these vars are
		# straight from the config, so are safe to embed directly
		if conf["adapter"] == "mysql"
			sql = `mysqldump --host="#{conf['host']}" --user="#{conf['username']}" --password="#{conf['password']}" #{conf['database']}`
		
		# only mysql is supported, for now,
		# but TODO: sqlite should be added
		else
			raise\
				ArgumentError,
				"Unsupported database adapter: #{conf['adapter']}"
		end
		
		# force a file download, named DBNAME-DDMMYY.sql
		fn = "#{conf['database']}-#{Time.now.strftime('%d%m%y')}.sql"
		headers["content-disposition"] = "attachment; filename=#{fn}"
  	render sql, :format => :text
	end
end
