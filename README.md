# Google Charts on Electric Imp
The DataTable class allows an Electric Imp agent to serve as a data source for [Google Charts](https://developers.google.com/chart/). A DataTable object acts like its [Javascript equivalent](https://developers.google.com/chart/interactive/docs/reference#DataTable), allowing the agent to easily record and format data for presentation. The DataTable object can also be used to respond to requests made by [Queries](https://developers.google.com/chart/interactive/docs/queries) using the [Chart Tools Datasource protocol](https://developers.google.com/chart/interactive/docs/dev/implementing_data_source).

## Class Usage

### Constructor: DataTable()
The constructors initializes an empty DataTable with no rows and no columns.

## Class Methods

### addColumn(*type, [label, id]*)
The *addColumn* method adds new column to the data table, and returns the index of the new column. Type specifies the type of data stored in this column and should be one of the following constants:

| Constant | Type |
| -------- | ----- |
| TYPE_BOOLEAN | Boolean |
| TYPE_NUMBER | Numeric |
| TYPE_STRING | String |
| TYPE_DATE | Date (Year, Month, Day) |
| TYPE_DATETIME | Date and Time (Year, Month, Day, Hour, Minutes, Seconds, Milliseconds)|
| TYPE_TIMEOFDAY | Time of Day (Hour, Minutes, Seconds, Milliseconds) |

Label and id are optional parameters which provide a label (used for labeling the column in a chart) and id (used for identifying the column in queries).

```squirrel
dt <- DataTable();

dt.addColumn(DataTable.TYPE_DATETIME, "Time");
dt.addColumn(DataTable.TYPE_NUMBER, "Temperature", "temp");
```

### addRow(*cellArray*)

The *addRow* method adds new row to the data table, and returns the index of the new row. CellArray is an array of values representing the contents of the new row. Each entry can either a table representing a formattedcell created with the *makeCell()* function or a raw value which will be wrapped in a table for insertion into the DataTable. 

```squirrel
// Categorical data
dt.addRow(["Temperature (ºC)", 0]);

// Time series data
dt.addRow([DataTable.toDateTime(date()), 3.2]);
```

### insertColumn(*columnIndex, type, [label, id]*)

Inserts a new column to the data table, at the specified index. All existing columns at or after the specified index are shifted to a higher index. Uses the same set of type constants as the *addColumn* method.

```squirrel
dt <- DataTable();

dt.addColumn(DataTable.TYPE_NUMBER, "Temperature", "temp");
dt.insertColumn(0, DataTable.TYPE_DATETIME, "Time");
```

### insertRow(*rowIndex, cellArray*)

Inserts one new row to the data table at the specified index. cellArray is an array of values representing the contents of the new row. Each value can either a table representing a formatted cell created with the makeCell() function or a raw value which will be wrapped in a table for insertion into the DataTable. All existing rows at or after the specified index are shifted to a higher index.

```squirrel
dt <- DataTable();

dt.insertRow(0, [1 , "Second row"]);
dt.insertRow(1, [2 , "Third row"]);
dt.insertRow(0, [0 , "First row]);
```

### toTable()

Returns a squirrel table representation of this DataTable. This representation corresponds closely with the JavaScript string literal data object format as described in the [Google Charts API reference](https://developers.google.com/chart/interactive/docs/reference#dataparam). 

The top most table contains two keys. `cols` maps to an array of tables defining the properties of each column in the DataTable. Every column must have a corresponding table in this array, defining the type of that column. Optionally, an id and label may also be defined. The second key, `rows` maps to an array of tables representing the rows of the DataTable. Each entry of the rows array contains a table defining the properties of that row. In particular, the key `c` maps to an array of cells defining the values and properties of the cells in that row. Each cell is a table with the keys `v` (value), `f` (optional formatted value), and `p` (optional custom properties).

```squirrel
dt <- DataTable();

dt.addColumn(DataTable.TYPE_STRING, "Label");
dt.addColumn(DataTable.TYPE_NUMBER, "Value");
dt.addRow(["Temperature (ºC)",0]);
dt.addRow(["Light (lux)",0]);
dt.addRow(["Pressure (HPa)",0]);
dt.addRow(["Humidity (%rH)",0]);

server.log(http.jsonencode(dt.toTable()));
```
Formatted output:
```JSON
{ 
	"rows": [
		{ "c": [ { "v": "Temperature (\u00baC)" }, { "v": 0 } ] }, 
		{ "c": [ { "v": "Light (lux)" }, { "v": 0 } ] }, 
		{ "c": [ { "v": "Pressure (HPa)" }, { "v": 0 } ] }, 
		{ "c": [ { "v": "Humidity (%rH)" }, { "v": 0 } ] } 
	], 
	"cols": [ 
		{ 
			"type": "string", 
			"id": "", 
			"label": "Label" 
		}, 
		{ 
			"type": "number", 
			"id": "", 
			"label": "Value" 
		} 
	] 
}
```

### toJSON()

Returns a JSON representation of the DataTable that can be passed into the Javascript DataTable constructor.

```squirrel
dt <- DataTable();

dt.addColumn(DataTable.TYPE_STRING, "Label");
dt.addColumn(DataTable.TYPE_NUMBER, "Value");
dt.addRow(["Temperature (ºC)",0]);
dt.addRow(["Light (lux)",0]);
dt.addRow(["Pressure (HPa)",0]);
dt.addRow(["Humidity (%rH)",0]);

server.log(dt.toJSON());
// Equivalent to
server.log(http.jsonencode(dt.toTable()));
```

### respond(*request, [currentSig]*)

Responds to a Google Charts Query with the data contained in this DataTable. request is the received httprequest object. This method returns a string with the appropriate httpresponse body text.

currentSig is an optional string parameter specifiying a hash value for this DataTable. This is used to send a "not_modified" response if the data has not changed since the last request. If currentSig is not provided, this functionallity will be disabled.

```squirrel
function requestHandler(request, response) {
	try {
		response.send(200, dt.respond(request, http.base64encode(http.hash.md5(dt.toJSON()))));
	} catch (exception) {
	    server.error(exception);
		response.send(500, "Internal Server Error: " + exception);
	}
}
// Register the handler function as a callback
http.onrequest(requestHandler);
```

### getValue(*rowIndex, columnIndex*)

Returns the value of the cell at the given row and column indexes.

```squirrel
dt <- DataTable();

dt.addColumn(DataTable.TYPE_NUMBER, "Value");
dt.addRow([0]);

dt.getValue(0, 0);
```

### getColumn(*columnIndex*)

Returns a table containing the properties of the column with the given index. A brief summary of typical keys is given below:

| Key | Description |
|-----|-------------|
| *id*  | The column identifier. For data tables that are retrieved by queries, the column identifier is set by the data source, and can be used to refer to columns when using the query language. |
| *label* | The column label is typically displayed as part of the visualization. For example the column label can be displayed as a column header in a table, or as the legend label in a pie chart. |
| *type* | A string indicating the data type stored in this label. See the supported types listed for the *addColumn* method.|

### getNumberOfColumns()

Returns the number of columns in the table.

### getNumberOfRows()

Returns the number of rows in the table.

### removeColumns(*columnIndex, numberOfColumns*)

Removes the specified number of columns starting from the column at the specified index.

### removeRows(*rowIndex, numberOfRows*)

Removes the specified number of rows starting from the row at the specified index.

### setCell(*rowIndex, columnIndex, value*)

Sets the value of the specified cell in the DataTable. Each value can either a table representing a formatted cell created with the *makeCell()* method or a raw value which will be wrapped in a table for insertion into the DataTable.

## Static Methods

### makeCell(*[value, formated_value, properties]*)

Returns a table representing a DataTable cell with the specified value, formatted value, and properties table. 



### GJSONtoTable(*text*)

Decodes a modified-JSON string as returned by Google's libraries into a squirrel table. Google JSON is identical to standard JSON except that keys are unquoted and string values are single-quoted rather than double-quoted.

### toDateTime(*datetime*)

Translates a date table (as returned by date()) into a TYPE_DATETIME compatible string for inclusion in a DataTable cell.

```squirrel
dt <- DataTable();

dt.addColumn(DataTable.TYPE_DATETIME, "Time");
dt.addColumn(DataTable.TYPE_NUMBER, "Temperature");

// Timestamp and log data from the device
device.on("Temperature", function(data) {
	dt.addRow([DataTable.toDateTime(date()), data.temperature]);
});
```
