# Copyright (c) 2014, Stanford University
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

-- Note: if you change order or content of the
--       col names, match that in addAnonToActivityGradeTable.py,
--       and in testAddAnonToActivityGradeTable.py
CREATE DATABASE IF NOT EXISTS Edx;
USE Edx;
CREATE TABLE IF NOT EXISTS Edx.ActivityGrade (
    activity_grade_id int(11),
    student_id int(11) NOT NULL,
    course_display_name varchar(255) NOT NULL,
    grade double,
    max_grade double,
    percent_grade double,
    parts_correctness varchar(50),
    answers varchar(255),
    num_attempts int,
    first_submit datetime,
    last_submit datetime,
    module_type varchar(32) NOT NULL,
    anon_screen_name varchar(40) NOT NULL DEFAULT '',
    resource_display_name varchar(255) NOT NULL DEFAULT '',
    module_id varchar(255)
    );
