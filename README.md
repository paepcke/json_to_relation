json_to_relation
================

From a file or MongoDB that contain one or more JSON structures,
creates a relational schema, and a relational table. The table will
contain the file's content organized by a schema that is discovered on
the fly. Unpopulated fields are filled with nulls.

The output may be directed to a .csv file, as SQL insert statements to
a file, or directly to a MySQL database.

The schema's data types are conservative, in that they assume the
worst case size for each column. A schema_hints dictionary can provide
more optimal typing.

Test via:
   sudo python setup.py nosetests
Install via:
   sudo python setup.py install

To run:
   - use CLI or
   - GUI



