# Google Charts on Electric Imp
The DataTable class allows an Electric Imp agent to serve as a data source for Google Charts. A DataTable object acts like its Javascript equivalent, allowing the agent to easily record and format data for presentation. The DataTable object can also be used to respond to requests made by Queries using the Chart Tools Datasource protocol.

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
