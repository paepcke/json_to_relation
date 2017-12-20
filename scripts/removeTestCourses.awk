#! /bin/awk -f

#------------------------------------------
#
# AWK script to remove .csv file lines that
# contain names of Edx test courses. Those
# names are of wondrous variety, each platform
# engineer inventing a new fake0name scheme.
#
# Assumption: environment variable ${COURSE_NAME_INDEX}
# contains a number, which is the zero-origin
# column count where each line will contain
# a course name that may or may not be a test name.
#
# WARNING: this script is naive about commas:
#          it knows naught of double-quote
#          escapes.
#------------------------------------------

   { FS = "," };
   { $"${COURSE_NAME_INDEX}" = tolower($"${COURSE_NAME_INDEX}") }
   $"${COURSE_NAME_INDEX}"   ~ /^[0-9]/ {next}
   $"${COURSE_NAME_INDEX}"   ~ /jbau|janeu|sefu|davidu|caitlynx|josephtest|nickdupuniversity|nathanielu/ {next}
   $"${COURSE_NAME_INDEX}"   ~ /gracelyou|sandbox|demo|sampleuniversity|joeu|grbuniversity/ {next}
   $"${COURSE_NAME_INDEX}"   ~ /stanford_spcs\/001\/spcs_test_course1|\/test/ {next}
   $"${COURSE_NAME_INDEX}"   ~ /*zzz*/ {next}
   $"${COURSE_NAME_INDEX}"   ~ /business\/123\/gsb-test|foundation\/wtc01\/wadhwani_test_course/ {next}
   $"${COURSE_NAME_INDEX}"   ~ /grb\/101\/grb_test_course|gsb\/af1\/alfresco_testing/ {next}
   $"${COURSE_NAME_INDEX}"   ~ /internal\/101\/private_testing_course|openedx\/testeduc2000c\2013_sept/ {next}
   $"${COURSE_NAME_INDEX}"   ~ /stanford\/exp1\/experimental_assessment_test/ {next}
   $"${COURSE_NAME_INDEX}"   ~ /stanford\/shib_only\/on_campus_stanford_only_test_class/ {next}
   $"${COURSE_NAME_INDEX}"   ~ /stanford_spcs\/001\/spcs_test_course1|testing\/testing123\/evergreen/ {next}
   $"${COURSE_NAME_INDEX}"   ~ /testing_settings\/for_non_display|tocc\/1\/eqptest/ {next}
   $"${COURSE_NAME_INDEX}"   ~ /worldview\/wvtest\/worldview_testing|stanford\/xxxx\/yyyy/ {next}
   $"${COURSE_NAME_INDEX}"   ~ /testtest|nickdup|monx/ {next}
   {print}
