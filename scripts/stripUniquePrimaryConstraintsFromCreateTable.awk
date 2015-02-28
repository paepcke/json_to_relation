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
#        `id` int(11) NOT NULL AUTO_INCREMENT,
#        KEY `courseware_studentmodule_1923c03f` (`done`),
#        KEY `courseware_studentmodule_ff48d8e5` (`course_id`)
#      ) ENGINE=InnoDB AUTO_INCREMENT=42227991 DEFAULT CHARSET=utf8;
#      Another line
#         ...
# Notice that the last KEY decl must not have a trailing comma./


# Done once: Field separator is comma.
# This means each line will be partitioned
# into $1: everything up to, and excluding 
# the comma, and $2: empty string.

BEGIN {FS=","; seen=0};
{
    # All work done in earlier lines?
    if (seen) {
	print $0;
	next;
	# No, work not done: Skip primary/unique/constraint decls:
    } else if (match($0,/[\s]*PRIMARY KEY/) ||\
	       match($0,/[\s]*UNIQUE KEY/) ||\
	       match($0,/[\s]*CONSTRAINT.*/))
    {
	# Stop processing this line; read next line from file:
	next;
    } else if (match($0, /ENGINE/)) {
	# We reached the close of the CREATE TABLE statement.
	# Output a CR *without* a leading comma (last KEY stmt
	# that was printed earlier):
	printf "\n%s\n",$0;
	# All work is done; from here all lines
	# will simply be printed:
	seen=1;
    } else {
	# Unless we are in the very first line,
	# we printed a line without a trailing comma
	# when the previous record was processed.
	# We now know that we do need that trailing
	# comma. We print it, followed by a CR, and
	# the current line *without* a trailing comma:
	if (FNR > 1)
	    printf ",\n%s", $1;
	else
	    printf "%s", $1;
    }
}