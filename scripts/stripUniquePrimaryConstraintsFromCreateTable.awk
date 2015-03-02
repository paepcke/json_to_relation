# Given an sql export file (mysqldump result) of
# courseware_studentmodule or courseware_studentmodulehistory,
# remove the declarations for PRIMARY KEY and CONSTRAINTS from
# the CREATE TABLE declaration.
#
# Excerpt of the CREATE TABLE input:
#      DROP TABLE IF EXISTS `courseware_studentmodule`;
#      CREATE TABLE `courseware_studentmodule` (
#        `id` int(11) NOT NULL AUTO_INCREMENT,
#        PRIMARY KEY (`id`),
#        UNIQUE KEY `courseware_studentmodule_student_id_635d77aea1256de5_uniq` (`student_id`,`module_id`,`course_id`),
#        KEY `courseware_studentmodule_1923c03f` (`done`),
#        KEY `courseware_studentmodule_ff48d8e5` (`course_id`),
#        CONSTRAINT `student_id_refs_id_51af713179ba2570` FOREIGN KEY (`student_id`) REFERENCES `auth_user` (`id`)
#      ) ENGINE=InnoDB AUTO_INCREMENT=42227991 DEFAULT CHARSET=utf8;
#      Another line
#         ...
#
# Output will be:
#      DROP TABLE IF EXISTS `courseware_studentmodule`;
#      CREATE TABLE `courseware_studentmodule` (
#        `id` int(11) NOT NULL,
#        KEY `courseware_studentmodule_1923c03f` (`done`),
#        KEY `courseware_studentmodule_ff48d8e5` (`course_id`)
#      ) ENGINE=MyISAM DEFAULT CHARSET=utf8;
#      Another line
#         ...
# Notice that the last KEY decl must not have a trailing comma./
# We use MyISAM b/c loading is faster, with key disabling working.

# BEGIN block done once: Field separator is comma.
# This means each line will be partitioned
# into $1: everything up to, and excluding 
# the comma, and $2: empty string.

BEGIN {FS=","; seen=0; inCreateTable=0};
{
    # All work done in earlier lines?
    if ($0 ~ /CREATE TABLE.*/)
    {
	inCreateTable = 1
	# Remember that we just printed CREATE TABLE
	# so that no comma is added before the next line,
	# and the auto increment is removed there.
	# See below for when that happens:
	justPrintedCreateTable = 1
	print $0
	next
    } else if (seen || inCreateTable == 0) {
	print $0
	next
    } else if ($0 ~ /[\s]*PRIMARY KEY/ ||\
	       $0 ~ /[\s]*UNIQUE KEY/ ||\
	       $0 ~ /[\s]*CONSTRAINT.*/)
    {
	# Stop processing this line; read next line from file:
	next
    } else if (match($0, /ENGINE/)) {
	# We reached the close of the CREATE TABLE statement.
	# Output a CR *without* a leading comma (last KEY stmt
	# that was printed earlier):

	printf "\n%s\n",") ENGINE=MyISAM DEFAULT CHARSET=utf8;"

	# All work is done; from here all lines
	# will simply be printed:
	seen=1
    } else {
	# Now we know we are inside the CREATE TABLE
	# statement. When processing the previous record
	# we printed a line without a trailing comma.
	# Unless we just printed the CREATE TABLE,
	# we do need that trailing comma. We print that comma, 
	# followed by a CR. We also print the current 
	# line but *without* a trailing comma. That way,
	# when ENGINE is found, we can leave out the
	# comma in the last line of the CREATE TABLE
	# (see earlier branch):
	if (justPrintedCreateTable) {
	    printf "  `id` int(11) NOT NULL"
	    justPrintedCreateTable = 0
	} else {
	    printf ",\n%s", $1
	}
    }
}