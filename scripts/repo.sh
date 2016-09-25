#!/bin/bash
##
##  Tigase Jabber/XMPP Server
##  Copyright (C) 2004-2012 "Artur Hefczyc" <artur.hefczyc@tigase.org>
##
##  This program is free software: you can redistribute it and/or modify
##  it under the terms of the GNU Affero General Public License as published by
##  the Free Software Foundation, either version 3 of the License.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU Affero General Public License for more details.
##
##  You should have received a copy of the GNU Affero General Public License
##  along with this program. Look for COPYING file in the top folder.
##  If not, see http://www.gnu.org/licenses/.
##
##  $Rev: $
##  Last modified by $Author: $
##  $Date: $
##

D="-server -Xms100M -Xmx1500M -Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8 -Djdbc.drivers=com.mysql.jdbc.Driver:org.postgresql.Driver"

MYSQL_REP="-sc tigase.db.jdbc.JDBCRepository -su jdbc:mysql://localhost/tigase?user=root&password=ciao"

java $D -cp "jars/*" tigase.util.RepositoryUtils $MYSQL_REP $*
