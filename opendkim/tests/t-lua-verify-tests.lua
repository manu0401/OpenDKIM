-- $Id: t-lua-verify-tests.lua,v 1.4 2010/09/24 21:40:31 cm-msk Exp $

-- Copyright (c) 2009, 2010, The OpenDKIM Project.  All rights reserved.

-- simple/simple verify test using Lua features

mt.echo("*** simple/simple verifying test using Lua features")

-- setup
sock = "unix:" .. mt.getcwd() .. "/t-lua-verify-tests.sock"
binpath = mt.getcwd() .. "/.."
if os.getenv("srcdir") ~= nil then
	mt.chdir(os.getenv("srcdir"))
end

-- try to start the filter
mt.startfilter(binpath .. "/opendkim", "-x", "t-lua-verify-tests.conf",
               "-p", sock)

-- try to connect to it
conn = mt.connect(sock, 40, 0.05)
if conn == nil then
	error("mt.connect() failed")
end

-- send connection information
-- mt.negotiate() is called implicitly
if mt.conninfo(conn, "localhost", "127.0.0.1") ~= nil then
	error("mt.conninfo() failed")
end
if mt.getreply(conn) ~= SMFIR_CONTINUE then
	error("mt.conninfo() unexpected reply")
end

-- send envelope macros and sender data
-- mt.helo() is called implicitly
mt.macro(conn, SMFIC_MAIL, "i", "t-lua-verify-tests")
if mt.mailfrom(conn, "user@example.com") ~= nil then
	error("mt.mailfrom() failed")
end
if mt.getreply(conn) ~= SMFIR_CONTINUE then
	error("mt.mailfrom() unexpected reply")
end

-- send headers
-- mt.rcptto() is called implicitly
if mt.header(conn, "DKIM-Signature", " v=1; a=rsa-sha256; c=simple/simple; d=example.com; s=test;\r\n\tt=1283905216; bh=3VWGQGY+cSNYd1MGM+X6hRXU0stl8JCaQtl4mbX/j2I=;\r\n\th=From:Date:Subject;\r\n\tb=AiGrvHu2mODRK2BlLXJy/YjCiBg3qr/QZ7laVq7ccMeA2QDmrksc9Hoj7lsFQc+bs\r\n\t lgIJh+8gzyQeGZz8TYX/LJaBg8kH8jn0w70hvI63sgN4wytwhvpvkPInUhLXgpkknj\r\n\t DT70LzX2ABd24nHDshfS22v+nwUl9xuMAq77UtbE=") ~= nil then
	error("mt.header(DKIM-Signature) failed")
end
if mt.getreply(conn) ~= SMFIR_CONTINUE then
	error("mt.header(DKIM-Signature) unexpected reply")
end
if mt.header(conn, "From", "user@host.example.com") ~= nil then
	error("mt.header(From) failed")
end
if mt.getreply(conn) ~= SMFIR_CONTINUE then
	error("mt.header(From) unexpected reply")
end
if mt.header(conn, "Date", "Tue, 22 Dec 2009 13:04:12 -0800") ~= nil then
	error("mt.header(Date) failed")
end
if mt.getreply(conn) ~= SMFIR_CONTINUE then
	error("mt.header(Date) unexpected reply")
end
if mt.header(conn, "Subject", "Signing test") ~= nil then
	error("mt.header(Subject) failed")
end
if mt.getreply(conn) ~= SMFIR_CONTINUE then
	error("mt.header(Subject) unexpected reply")
end
if mt.header(conn, "X-Test-Header", "oldvalue") ~= nil then
	error("mt.header(X-Test-Header) failed")
end
if mt.getreply(conn) ~= SMFIR_CONTINUE then
	error("mt.header(X-Test-Header) unexpected reply")
end

-- send EOH
if mt.eoh(conn) ~= nil then
	error("mt.eoh() failed")
end
if mt.getreply(conn) ~= SMFIR_CONTINUE then
	error("mt.eoh() unexpected reply")
end

-- send body
if mt.bodystring(conn, "This is a test!\r\n") ~= nil then
	error("mt.bodystring() failed")
end
if mt.getreply(conn) ~= SMFIR_CONTINUE then
	error("mt.bodystring() unexpected reply")
end

-- end of message; let the filter react
if mt.eom(conn) ~= nil then
	error("mt.eom() failed")
end
if mt.getreply(conn) ~= SMFIR_ACCEPT then
	error("mt.eom() unexpected reply")
end

-- verify that an Authentication-Results header field got added
if not mt.eom_check(conn, MT_HDRINSERT, "Authentication-Results") and
   not mt.eom_check(conn, MT_HDRADD, "Authentication-Results") then
	error("no Authentication-Results added")
end
ar = mt.getheader(conn, "Authentication-Results", 0)
if string.find(ar, "dkim=pass", 1, true) == nil then
	error("incorrect DKIM result")
end

mt.disconnect(conn)