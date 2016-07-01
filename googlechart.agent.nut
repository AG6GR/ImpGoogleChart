const TABLE_SIZE = 320;

class DataTable {
	static version = [0,0,0];
	
	// Column type strings
	static TYPE_BOOLEAN 	= "boolean";
	static TYPE_NUMBER 		= "number";
	static TYPE_STRING 		= "string";
	static TYPE_DATE 		= "date";
	static TYPE_DATETIME 	= "datetime";
	static TYPE_TIMEOFDAY	= "timeofday";
	
	_cols = null;
	_rows = null;
	
	//-------------------- STATIC METHODS --------------------//
	/* 
	 * Returns a table representing a DataTable cell with the specified value,
	 * formatted value, and properties table. 
	 */
	static function makeCell(value=null, formated_value=null, properties=null) {
		local newCell = {};
		newCell.v <- value;
		newCell.f <- (formated_value == null) ? "" : formated_value;
		newCell.p <- properties;
		return newCell;
	}
	/*
	 * Decodes a modified-JSON string as returned by Google's libraries into
	 * a squirrel table. Google JSON is identical to standard JSON except that
	 * keys are unquoted and string values are single-quoted rather than double-
	 * quoted.
	 */
	function GJSONtoTable(text) {
		local i = 0;
		local keyvalues = split(text, ":;");
		local resultTable = {};
		
		for (i = 0; i < keyvalues.len(); i += 2) {
		    //server.log("Key: " + keyvalues[i] + " Value: " + keyvalues[i + 1])
			resultTable[keyvalues[i]] <- keyvalues[i + 1];
		}
		return resultTable;
	}
	/*
	 * Translates a date table (as returned by date()) into a TYPE_DATETIME
	 * compatible string for inclusion in a DataTable cell.
	 */
	function toDateTime(datetime) {
		local dateTable = (typeof datetime == "table") ? datetime : date(datetime);
		return format("Date(%d, %d, %d, %d, %d, %d, %d)", 
			dateTable.year, dateTable.month, dateTable.day, dateTable.hour,
			dateTable.min, dateTable.sec, dateTable.usec/1000);
		
	}
	//-------------------- PUBLIC METHODS --------------------//
	constructor () {
	    _cols = array();
	    _rows = array();
	}
	
	/*
	 * Adds a new column to the data table, and returns the index of the new column.
	 */
	function addColumn(type, label=null, id=null) {
		local newCol = {};
		newCol.type <- type;
		if (label != null) {
			newCol.label <- label;
		} else {
			newCol.label <- "";
		}
		if (id != null) {
			newCol.id <- id;
		} else {
			newCol.id <- "";
		}
		_cols.append(newCol);
		return _cols.len() - 1;
	}
	/*
	 * Adds one new row to the data table, and returns the index of the
	 * last new row. cellArray is an array of values representing the contents 
	 * of the new row. Each value can either a table representing a formatted 
	 * cell created with the makeCell() function or a raw value which will be 
	 * wrapped in a table for insertion into the DataTable.
	 */
	function addRow(cellArray) {
		local newRow = array();
		foreach (item in cellArray) {
			if (typeof item != "table") {
				newRow.append({"v" : item});
			} else {
				newRow.append(item);
			}
		}
		_rows.append({"c" : newRow});
	}
	
	/*
	 * Inserts a new column to the data table, at the specifid index. All 
	 * existing columns at or after the specified index are shifted to a 
	 * higher index.
	 */
	function insertColumn(columnIndex, type, label=null, id=null) {
		local newCol = {};
		newCol.type <- type;
		if (label != null) {
			newCol.label <- label;
		} else {
			newCol.label <- "";
		}
		if (id != null) {
			newCol.id <- id;
		} else {
			newCol.id <- "";
		}
		_cols.insert(columnIndex, newCol);
	}
	/*
	 * Inserts one new rows to the data table at the specified index.
	 * cellArray is an array of values representing the contents 
	 * of the new row. Each value can either a table representing a formatted 
	 * cell created with the makeCell() function or a raw value which will be 
	 * wrapped in a table for insertion into the DataTable.
	 */
	function insertRow(rowIndex, cellArray) {
	    foreach (row in cellArray) {
    		local newRow = array();
    		foreach (item in row) {
    			if (typeof item != "table") {
    				newRow.append({"v" : item});
    			} else {
    				newRow.append(item);
    			}
    		}
    		_rows.insert(rowIndex, {"c" : newRow});
	    }
	}
	
	/*
	 * Returns a table corresponding to this DataTable.
	 */
	function toTable() {
		local dataTable = {};
		dataTable.cols <- _cols;
		dataTable.rows <- _rows;
		return dataTable;
	}
	/*
	 * Returns a JSON representation of the DataTable that can be passed 
	 * into the Javascript DataTable constructor. 
	 */
	function toJSON() {
		return http.jsonencode(toTable());
	}
	/*
	 * Responds to a Google Charts Query with the data contained in this
	 * DataTable. request is the received httprequest object. Returns a string
	 * with the appropriate httpresponse body text.
	 *
	 * currentSig is an optional string parameter specifiying the hash of this
	 * DataTable. This is used to send a "not_modified" response if the data has
	 * not changed since the last request. If currentSig is not provided, this
	 * this functionallity will be disabled.
	 */
	function respond(request, currentSig=null) {
		// Decode request
		local reqId = 0;
		local sig = "";
		local responseHandler = "google.visualization.Query.setResponse";
		
		if ("tqx" in request.query) {
			local tqx = DataTable.GJSONtoTable(request.query.tqx);
			
			if ("reqId" in tqx) {
				reqId = tqx.reqId;
			}
			if ("sig" in tqx) {
				sig = tqx.sig;
			}
			if ("responseHandler" in tqx) {
				responseHandler = tqx.responseHandler;
			}
		}
		// Respond
		
		local responseTable = {};
		responseTable["reqId"] <- reqId;
		
		if (currentSig != null) {
			responseTable.sig <- currentSig;
		}
		
		if (currentSig == null || sig != currentSig) {
			responseTable.status <- "ok";
			responseTable.table <- toTable();
		} else {
			responseTable.status <- "error";
			responseTable.errors  
				<- [{"reason":"not_modified","message":"Data not modified"}];
		}
		return responseHandler + "(" + http.jsonencode(responseTable) + ")";
	}
	
	/* 
	 * Returns the value of the cell at the given row and column indexes.
	 */
	function getValue(rowIndex, columnIndex) {
		return ("v" in _row[rowIndex]["c"][columnIndex]) ? _row[rowIndex]["c"][columnIndex]["v"] : null;
	}
	
	/* 
	 * Returns the identifier of a given column specified by the column index
	 * in the underlying table.
	 * 
	 * For data tables that are retrieved by queries, the column identifier 
	 * is set by the data source, and can be used to refer to columns when 
	 * using the query language. 
	 */
	function getColumnId(columnIndex) {
		return _cols[columnIndex].id;
	}
	
	/* 
	 * Returns the identifier of a given column specified by the column index
	 * in the underlying table.
	 *
	 * The column label is typically displayed as part of the visualization. 
	 * For example the column label can be displayed as a column header in a 
	 * table, or as the legend label in a pie chart. 
	 */
	function getColumnLabel(columnIndex) {
		return _cols[columnIndex].label;
	}
	
	/* 
	 * Returns the type of a given column specified by the column index as a
	 * string.
	 */
	function getColumnType(columnIndex) {
		return _cols[columnIndex].type;
	}
	
	/*
	 * Returns the number of columns in the table.
	 */
	function getNumberOfColumns() {
		return _cols.len();
	}
	
	/*
	 * Returns the number of rows in the table.
	 */
	function getNumberOfRows() {
		return _rows.len();
	}
	
	/*
	 * Removes the specified number of columns starting from the column at 
	 * the specified index.
	 */
	function removeColumns(columnIndex, numberOfColumns) {
		for (; numberOfColumns > 0; numberOfColumns--) {
			_cols.remove(columnIndex);
		}
	}
	
	/*
	 * Removes the specified number of rows starting from the row at 
	 * the specified index.
	 */
	function removeRows(rowIndex, numberOfRows) {
		for (; numberOfRows > 0; numberOfRows--) {
			_rows.remove(rowIndex);
		}
	}
	
	/*
	 * Sets the value of the specified cell in the DataTable.
	 * Each value can either a table representing a formatted 
	 * cell created with the makeCell() function or a raw value which will be 
	 * wrapped in a table for insertion into the DataTable.
	 */
	function setCell(rowIndex, columnIndex, value) {
		_rows[rowIndex]["c"][columnIndex] = (typeof value == "table") ? value : {"v" : value};
	}
	
	//-------------------- PRIVATE METHODS --------------------//
	
}

//================ MAIN CODE ================//

dt <- DataTable();

dt.addColumn(DataTable.TYPE_DATETIME, "Time");
dt.addColumn(DataTable.TYPE_NUMBER, "Temperature");
dt.addColumn(DataTable.TYPE_NUMBER, "Light");
dt.addColumn(DataTable.TYPE_NUMBER, "Pressure");
dt.addColumn(DataTable.TYPE_NUMBER, "Humidity");

gaugeDT <- DataTable();

gaugeDT.addColumn(DataTable.TYPE_STRING, "Label");
gaugeDT.addColumn(DataTable.TYPE_NUMBER, "Value");
gaugeDT.addRow(["Temperature (ºC)",0]);
gaugeDT.addRow(["Light (lux)",0]);
gaugeDT.addRow(["Pressure (HPa)",0]);
gaugeDT.addRow(["Humidity (%rH)",0]);

function requestHandler(request, response) {
	try {
		if (request.path == "/gauge") {
			response.send(200, gaugeDT.respond(request, time()));
		} else {
			response.send(200, dt.respond(request, time()));
		}
	} catch (exception) {
	    server.error(exception);
		response.send(500, "Internal Server Error: " + exception);
	}
}
// Register the handler function as a callback
http.onrequest(requestHandler);

device.on("Light", function(data) {
	dt.addRow([DataTable.toDateTime(date()), null, data.brightness, null, null]);
	if (dt.getNumberOfRows() > TABLE_SIZE) {
	   dt.removeRows(0,1);
	}
	gaugeDT.setCell(1, 1, data.brightness);
});
device.on("Pressure", function(data) {
	dt.addRow([DataTable.toDateTime(date()), null, null, data.pressure, null]);
	if (dt.getNumberOfRows() > TABLE_SIZE) {
	   dt.removeRows(0,1);
	}
	gaugeDT.setCell(2, 1, data.pressure);
});
device.on("Temperature", function(data) {
	dt.addRow([DataTable.toDateTime(date()), data.temperature, null, null, null]);
	if (dt.getNumberOfRows() > TABLE_SIZE) {
	   dt.removeRows(0,1);
	}
	gaugeDT.setCell(0, 1, data.temperature);
});
device.on("Humidity", function(data) {
	dt.addRow([DataTable.toDateTime(date()), null, null, null, data.humidity]);
	if (dt.getNumberOfRows() > TABLE_SIZE) {
	   dt.removeRows(0,1);
	}
	gaugeDT.setCell(3, 1, data.humidity);
});