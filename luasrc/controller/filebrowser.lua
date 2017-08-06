-- Copyright 2016 giaulo <giaulo@giaulo.org>
-- Copyright 2017 Xingwang Liao <kuoruan@gmail.com>
-- This is free software, licensed under the Apache License, Version 2.0

module("luci.controller.filebrowser", package.seeall)

local fs    = require "nixio.fs"
local sys   = require "luci.sys"
local http  = require "luci.http"
local user  = require "luci.sys.user"
local dsp   = require "luci.dispatcher"

function index()

	entry({"admin", "system", "filebrowser"},
		template("filebrowser"), _("File Browser"), 60).dependent = true

	entry({"admin", "system", "filebrowser_list"},
		call("filebrowser_list"), nil).leaf = true

	entry({"admin", "system", "filebrowser_open"},
		call("filebrowser_open"), nil).leaf = true

	entry({"admin", "system", "filebrowser_delete"},
		call("filebrowser_delete"), nil).leaf = true

	entry({"admin", "system", "filebrowser_rename"},
		call("filebrowser_rename"), nil).leaf = true

	entry({"admin", "system", "filebrowser_upload"},
		call("filebrowser_upload"), nil).leaf = true

end

function filebrowser_list()
	local rv = { }
	local path = http.formvalue("path")

	if path and path ~= "" then
		local entires = nixio.util.consume((fs.dir(filepath)))
	end

	rv = scandir(path)

	http.prepare_content("application/json")
	http.write_json(rv)
end

function scandir(directory)
	local i, t, popen = 0, {}, io.popen

	local pfile = popen("ls -l \""..directory.."\" | egrep '^d' ; ls -lh \""..directory.."\" | egrep -v '^d'")
	for filename in pfile:lines() do
		i = i + 1
		t[i] = filename
	end
	pfile:close()
	return t
end

function filebrowser_open(file, filename)
	file = file:gsub("<>", "/")

	local io = require "io"
	local mime = to_mime(filename)

	local download_fpi = io.open(file, "r")
	http.header('Content-Disposition', 'inline; filename="'..filename..'"' )
	http.prepare_content(mime or "application/octet-stream")
	luci.ltn12.pump.all(luci.ltn12.source.file(download_fpi), http.write)
end

function filebrowser_delete()
	local path = http.formvalue("path")
	local isdir = http.formvalue("isdir")
	path = path:gsub("<>", "/")
	path = path:gsub(" ", "\ ")
	if isdir then
		local success = os.execute('rm -r "'..path..'"')
	else
		local success = os.remove(path)
	end
	return success
end

function filebrowser_rename()
	local filepath = http.formvalue("filepath")
	local newpath = http.formvalue("newpath")
	local success = os.execute('mv "'..filepath..'" "'..newpath..'"')
	return success
end

function filebrowser_upload()
	local filecontent = http.formvalue("upload-file")
	local filename = http.formvalue("upload-filename")
	local uploaddir = http.formvalue("upload-dir")
	local filepath = uploaddir..filename
	local url = luci.dispatcher.build_url('admin', 'system', 'filebrowser')

	local fp
	fp = io.open(filepath, "w")
	fp:write(filecontent)
	fp:close()
	http.redirect(url..'?path='..uploaddir)
end

MIME_TYPES = {
	["txt"]   = "text/plain";
	["js"]    = "text/javascript";
	["css"]   = "text/css";
	["htm"]   = "text/html";
	["html"]  = "text/html";
	["patch"] = "text/x-patch";
	["c"]     = "text/x-csrc";
	["h"]     = "text/x-chdr";
	["o"]     = "text/x-object";
	["ko"]    = "text/x-object";

	["bmp"]   = "image/bmp";
	["gif"]   = "image/gif";
	["png"]   = "image/png";
	["jpg"]   = "image/jpeg";
	["jpeg"]  = "image/jpeg";
	["svg"]   = "image/svg+xml";

	["zip"]   = "application/zip";
	["pdf"]   = "application/pdf";
	["xml"]   = "application/xml";
	["xsl"]   = "application/xml";
	["doc"]   = "application/msword";
	["ppt"]   = "application/vnd.ms-powerpoint";
	["xls"]   = "application/vnd.ms-excel";
	["odt"]   = "application/vnd.oasis.opendocument.text";
	["odp"]   = "application/vnd.oasis.opendocument.presentation";
	["pl"]    = "application/x-perl";
	["sh"]    = "application/x-shellscript";
	["php"]   = "application/x-php";
	["deb"]   = "application/x-deb";
	["iso"]   = "application/x-cd-image";
	["tgz"]   = "application/x-compressed-tar";

	["mp3"]   = "audio/mpeg";
	["ogg"]   = "audio/x-vorbis+ogg";
	["wav"]   = "audio/x-wav";

	["mpg"]   = "video/mpeg";
	["mpeg"]  = "video/mpeg";
	["avi"]   = "video/x-msvideo";
}

function to_mime(filename)
	if type(filename) == "string" then
		local ext = filename:match("[^%w]+$")

		if ext and MIME_TYPES[ext:lower()] then
			return MIME_TYPES[ext:lower()]
		end
	end

	return "application/octet-stream"
end
